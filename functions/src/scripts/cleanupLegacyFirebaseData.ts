import * as admin from "firebase-admin";
import {
  TRACKING_LOCATION_EVENT_CATEGORY,
  TRACKING_LOCATION_TTL_MS,
  toMillis,
} from "../services/trackingLocationNotifications";
import { PREVIEW_SAFE_ROUTE_ID_PREFIX } from "../services/safeRouteDirectionsService";
import { isCanonicalZoneEventRecord } from "../services/zoneEventEvaluator";

type CleanupCategory =
  | "trackingNotifications"
  | "legacyZoneEvents"
  | "staleFamilyMembers"
  | "previewRoutes";

type CleanupStats = {
  scanned: number;
  candidates: number;
  deleted: number;
  errors: number;
  samples: string[];
};

type CleanupSummary = Record<CleanupCategory, CleanupStats>;

const FIRESTORE_DELETE_BATCH_SIZE = 400;
const RTDB_DELETE_BATCH_SIZE = 250;
const SAMPLE_LIMIT = 10;
const DEFAULT_PROJECT_ID = "kidmanager-b4a8f";
const DEFAULT_DATABASE_URL = "https://kidmanager-b4a8f-default-rtdb.firebaseio.com";
const ALL_CATEGORIES: CleanupCategory[] = [
  "trackingNotifications",
  "legacyZoneEvents",
  "staleFamilyMembers",
  "previewRoutes",
];
const LEGACY_TRACKING_EVENT_KEYS = new Set([
  "tracking.location_service_off.parent",
  "tracking.location_permission_denied.parent",
  "tracking.background_disabled.parent",
  "tracking.location_stale.parent",
  "tracking.ok.parent",
]);

function createStats(): CleanupStats {
  return {
    scanned: 0,
    candidates: 0,
    deleted: 0,
    errors: 0,
    samples: [],
  };
}

function rememberSample(stats: CleanupStats, value: string) {
  if (stats.samples.length < SAMPLE_LIMIT) {
    stats.samples.push(value);
  }
}

function parseCategoriesArg(raw: string | undefined): CleanupCategory[] {
  if (!raw || !raw.trim()) {
    return [...ALL_CATEGORIES];
  }

  const requested = raw
    .split(",")
    .map((value) => value.trim())
    .filter((value): value is CleanupCategory =>
      ALL_CATEGORIES.includes(value as CleanupCategory),
    );

  return requested.length > 0 ? requested : [...ALL_CATEGORIES];
}

function readArgValue(args: string[], name: string): string | undefined {
  const matched = args.find((arg) => arg.startsWith(`${name}=`));
  if (!matched) {
    return undefined;
  }
  const value = matched.slice(name.length + 1).trim();
  return value.length > 0 ? value : undefined;
}

function getString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function getStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => getString(item))
    .filter((item) => item.length > 0)
    .filter((item, index, list) => list.indexOf(item) === index);
}

async function commitFirestoreDeletes(
  refs: FirebaseFirestore.DocumentReference[],
  db: FirebaseFirestore.Firestore,
): Promise<number> {
  let deleted = 0;

  for (let index = 0; index < refs.length; index += FIRESTORE_DELETE_BATCH_SIZE) {
    const chunk = refs.slice(index, index + FIRESTORE_DELETE_BATCH_SIZE);
    if (chunk.length === 0) {
      continue;
    }

    const batch = db.batch();
    for (const ref of chunk) {
      batch.delete(ref);
    }
    await batch.commit();
    deleted += chunk.length;
  }

  return deleted;
}

async function commitRtdbDeletes(paths: string[]): Promise<number> {
  let deleted = 0;

  for (let index = 0; index < paths.length; index += RTDB_DELETE_BATCH_SIZE) {
    const chunk = paths.slice(index, index + RTDB_DELETE_BATCH_SIZE);
    if (chunk.length === 0) {
      continue;
    }

    const updates: Record<string, null> = {};
    for (const path of chunk) {
      updates[path] = null;
    }

    await admin.database().ref().update(updates);
    deleted += chunk.length;
  }

  return deleted;
}

function isExpiredTrackingLocationNotificationDoc(
  data: Record<string, unknown>,
  cutoffMs: number,
): boolean {
  const eventCategory = data.eventCategory;
  if (eventCategory === TRACKING_LOCATION_EVENT_CATEGORY) {
    const expiresAtMs = toMillis(data.expiresAt);
    return expiresAtMs != null && expiresAtMs <= cutoffMs;
  }

  if (getString(data.type).toUpperCase() !== "TRACKING") {
    return false;
  }

  const eventKey = getString(data.eventKey);
  if (!LEGACY_TRACKING_EVENT_KEYS.has(eventKey)) {
    return false;
  }

  const createdAtMs = toMillis(data.createdAt);
  return createdAtMs != null && createdAtMs <= cutoffMs;
}

async function cleanupTrackingNotifications(params: {
  execute: boolean;
  cutoffMs: number;
  db: FirebaseFirestore.Firestore;
}): Promise<CleanupStats> {
  const stats = createStats();
  const refsToDelete = new Map<string, FirebaseFirestore.DocumentReference>();

  const eventCategorySnapshot = await params.db
    .collection("notifications")
    .where("eventCategory", "==", TRACKING_LOCATION_EVENT_CATEGORY)
    .get();

  for (const doc of eventCategorySnapshot.docs) {
    stats.scanned += 1;
    const data = (doc.data() ?? {}) as Record<string, unknown>;
    if (!isExpiredTrackingLocationNotificationDoc(data, params.cutoffMs)) {
      continue;
    }

    stats.candidates += 1;
    refsToDelete.set(doc.id, doc.ref);
    rememberSample(stats, `notifications/${doc.id}`);
  }

  const trackingSnapshot = await params.db
    .collection("notifications")
    .where("type", "==", "TRACKING")
    .get();

  for (const doc of trackingSnapshot.docs) {
    stats.scanned += 1;
    const data = (doc.data() ?? {}) as Record<string, unknown>;
    if (!isExpiredTrackingLocationNotificationDoc(data, params.cutoffMs)) {
      continue;
    }

    if (!refsToDelete.has(doc.id)) {
      stats.candidates += 1;
      rememberSample(stats, `notifications/${doc.id}`);
    }
    refsToDelete.set(doc.id, doc.ref);
  }

  if (!params.execute || refsToDelete.size === 0) {
    return stats;
  }

  try {
    stats.deleted = await commitFirestoreDeletes([...refsToDelete.values()], params.db);
  } catch (error) {
    console.error("[LEGACY_CLEANUP] trackingNotifications delete failed", error);
    stats.errors += refsToDelete.size;
  }

  return stats;
}

async function cleanupLegacyZoneEvents(params: {
  execute: boolean;
}): Promise<CleanupStats> {
  const stats = createStats();
  const pathsToDelete: string[] = [];

  const snapshot = await admin.database().ref("zoneEventsByChild").get();
  if (!snapshot.exists()) {
    return stats;
  }

  const rawByChild = snapshot.val() as Record<string, unknown>;
  for (const [childUid, rawEvents] of Object.entries(rawByChild)) {
    if (!rawEvents || typeof rawEvents !== "object") {
      continue;
    }

    for (const [eventId, rawEvent] of Object.entries(
      rawEvents as Record<string, unknown>,
    )) {
      stats.scanned += 1;
      if (isCanonicalZoneEventRecord(rawEvent)) {
        continue;
      }

      const path = `zoneEventsByChild/${childUid}/${eventId}`;
      pathsToDelete.push(path);
      stats.candidates += 1;
      rememberSample(stats, path);
    }
  }

  if (!params.execute || pathsToDelete.length === 0) {
    return stats;
  }

  try {
    stats.deleted = await commitRtdbDeletes(pathsToDelete);
  } catch (error) {
    console.error("[LEGACY_CLEANUP] legacyZoneEvents delete failed", error);
    stats.errors += pathsToDelete.length;
  }

  return stats;
}

async function cleanupStaleFamilyMembers(params: {
  execute: boolean;
  db: FirebaseFirestore.Firestore;
}): Promise<CleanupStats> {
  const stats = createStats();
  const refsToDelete: FirebaseFirestore.DocumentReference[] = [];

  const membersSnapshot = await params.db.collectionGroup("members").get();
  for (const doc of membersSnapshot.docs) {
    const pathSegments = doc.ref.path.split("/");
    if (pathSegments.length !== 4 || pathSegments[0] !== "families") {
      continue;
    }

    const familyId = pathSegments[1];
    const uid = doc.id;
    stats.scanned += 1;

    const userSnap = await params.db.doc(`users/${uid}`).get();
    if (!userSnap.exists) {
      refsToDelete.push(doc.ref);
      stats.candidates += 1;
      rememberSample(stats, doc.ref.path);
      continue;
    }

    const userData = (userSnap.data() ?? {}) as Record<string, unknown>;
    if (getString(userData.familyId) !== familyId) {
      refsToDelete.push(doc.ref);
      stats.candidates += 1;
      rememberSample(stats, doc.ref.path);
    }
  }

  if (!params.execute || refsToDelete.length === 0) {
    return stats;
  }

  try {
    stats.deleted = await commitFirestoreDeletes(refsToDelete, params.db);
  } catch (error) {
    console.error("[LEGACY_CLEANUP] staleFamilyMembers delete failed", error);
    stats.errors += refsToDelete.length;
  }

  return stats;
}

async function cleanupPreviewRoutes(params: {
  execute: boolean;
  db: FirebaseFirestore.Firestore;
}): Promise<CleanupStats> {
  const stats = createStats();
  const refsToDelete: FirebaseFirestore.DocumentReference[] = [];

  const tripsSnapshot = await params.db.collection("trips").get();
  const referencedRouteIds = new Set<string>();
  for (const doc of tripsSnapshot.docs) {
    const data = (doc.data() ?? {}) as Record<string, unknown>;
    const routeId = getString(data.routeId);
    const currentRouteId = getString(data.currentRouteId);
    if (routeId) {
      referencedRouteIds.add(routeId);
    }
    if (currentRouteId) {
      referencedRouteIds.add(currentRouteId);
    }
    for (const alternativeRouteId of getStringList(data.alternativeRouteIds)) {
      referencedRouteIds.add(alternativeRouteId);
    }
  }

  const routesSnapshot = await params.db.collection("routes").get();
  for (const doc of routesSnapshot.docs) {
    stats.scanned += 1;
    const data = (doc.data() ?? {}) as Record<string, unknown>;
    const dataId = getString(data.id);
    const hasPreviewIdentifier =
      doc.id.startsWith(PREVIEW_SAFE_ROUTE_ID_PREFIX) ||
      dataId.startsWith(PREVIEW_SAFE_ROUTE_ID_PREFIX);

    if (!hasPreviewIdentifier) {
      continue;
    }

    if (referencedRouteIds.has(doc.id) || (dataId && referencedRouteIds.has(dataId))) {
      continue;
    }

    refsToDelete.push(doc.ref);
    stats.candidates += 1;
    rememberSample(stats, doc.ref.path);
  }

  if (!params.execute || refsToDelete.length === 0) {
    return stats;
  }

  try {
    stats.deleted = await commitFirestoreDeletes(refsToDelete, params.db);
  } catch (error) {
    console.error("[LEGACY_CLEANUP] previewRoutes delete failed", error);
    stats.errors += refsToDelete.length;
  }

  return stats;
}

async function main() {
  const args = process.argv.slice(2);
  const execute = args.includes("--execute");
  const categoriesArg = readArgValue(args, "--categories");
  const projectId =
    readArgValue(args, "--project") ??
    process.env.GCLOUD_PROJECT ??
    process.env.GCP_PROJECT ??
    process.env.PROJECT_ID ??
    DEFAULT_PROJECT_ID;
  const databaseURL =
    readArgValue(args, "--database-url") ??
    process.env.FIREBASE_DATABASE_URL ??
    DEFAULT_DATABASE_URL;
  const categories = parseCategoriesArg(
    categoriesArg,
  );
  const cutoffMs = Date.now() - TRACKING_LOCATION_TTL_MS;
  const app =
    admin.apps[0] ??
    admin.initializeApp({
      projectId,
      databaseURL,
    });
  const db = app.firestore();

  const summary: CleanupSummary = {
    trackingNotifications: createStats(),
    legacyZoneEvents: createStats(),
    staleFamilyMembers: createStats(),
    previewRoutes: createStats(),
  };

  for (const category of categories) {
    switch (category) {
      case "trackingNotifications":
        summary.trackingNotifications = await cleanupTrackingNotifications({
          execute,
          cutoffMs,
          db,
        });
        break;
      case "legacyZoneEvents":
        summary.legacyZoneEvents = await cleanupLegacyZoneEvents({ execute });
        break;
      case "staleFamilyMembers":
        summary.staleFamilyMembers = await cleanupStaleFamilyMembers({
          execute,
          db,
        });
        break;
      case "previewRoutes":
        summary.previewRoutes = await cleanupPreviewRoutes({
          execute,
          db,
        });
        break;
    }
  }

  console.log(
    JSON.stringify(
      {
        mode: execute ? "execute" : "dry-run",
        projectId,
        databaseURL,
        cutoffIso: new Date(cutoffMs).toISOString(),
        categories,
        summary,
      },
      null,
      2,
    ),
  );

  const totalErrors = Object.values(summary).reduce(
    (total, stats) => total + stats.errors,
    0,
  );
  if (totalErrors > 0) {
    process.exitCode = 1;
  }
}

void main();
