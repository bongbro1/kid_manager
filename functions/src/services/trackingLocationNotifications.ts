import { admin, db } from "../bootstrap";
import { t } from "../i18n";

export const TRACKING_LOCATION_EVENT_CATEGORY = "location_status";
export const TRACKING_LOCATION_TTL_MS = 24 * 60 * 60 * 1000;

const TRACKING_LOCATION_STATUSES = new Set([
  "location_service_off",
  "location_permission_denied",
  "background_disabled",
  "location_stale",
  "ok",
]);

type FamilyMemberDoc = Record<string, unknown>;

function readTrimmedStringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  return raw
    .map((item) => (typeof item === "string" ? item.trim() : ""))
    .filter((item) => item.length > 0);
}

export function isTrackingLocationStatus(status: string): boolean {
  return TRACKING_LOCATION_STATUSES.has(status.trim().toLowerCase());
}

export function toMillis(value: unknown): number | null {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }

  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed) && parsed > 0) {
      return Math.trunc(parsed);
    }
  }

  if (typeof value === "object" && value !== null) {
    const maybe = value as { seconds?: unknown; _seconds?: unknown };
    const seconds =
      (typeof maybe.seconds === "number" ? maybe.seconds : null) ??
      (typeof maybe._seconds === "number" ? maybe._seconds : null);
    if (seconds != null && Number.isFinite(seconds) && seconds > 0) {
      return Math.trunc(seconds * 1000);
    }
  }

  return null;
}

export function eventKeyForTrackingLocationStatus(status: string): string {
  return `tracking.${status.trim().toLowerCase()}.parent`;
}

export function shouldReceiveTrackingLocationNotification(params: {
  memberUid: string;
  memberRole: string;
  memberData: FamilyMemberDoc;
  childUid: string;
}): boolean {
  const role = params.memberRole.trim().toLowerCase();
  if (params.memberUid === params.childUid) {
    return false;
  }

  if (role === "parent") {
    return true;
  }

  if (role !== "guardian") {
    return false;
  }

  const managedChildIds = readTrimmedStringList(
    params.memberData.managedChildIds ??
      params.memberData.assignedChildIds ??
      params.memberData.childIds,
  );
  return managedChildIds.includes(params.childUid);
}

export async function resolveUserLanguage(uid: string): Promise<string> {
  const userSnap = await db.doc(`users/${uid}`).get();
  const user = userSnap.exists ? (userSnap.data() as Record<string, unknown>) : {};
  return String(user.lang ?? user.locale ?? "vi").toLowerCase();
}

export function buildTrackingLocationNotificationRecord(params: {
  locale: string;
  childUid: string;
  childName: string;
  familyId: string;
  status: string;
  nowMs: number;
}): {
  title: string;
  body: string;
  eventKey: string;
  eventCategory: string;
  expiresAt: FirebaseFirestore.Timestamp;
  data: Record<string, string>;
} {
  const normalizedStatus = params.status.trim().toLowerCase();
  if (!isTrackingLocationStatus(normalizedStatus)) {
    throw new Error(`Unsupported tracking location status: ${params.status}`);
  }

  const eventKey = eventKeyForTrackingLocationStatus(normalizedStatus);
  const templateParams = {
    childName: params.childName,
  };

  const title = t(params.locale, `${eventKey}.title`, templateParams);
  const body = t(params.locale, `${eventKey}.body`, templateParams);

  return {
    title,
    body,
    eventKey,
    eventCategory: TRACKING_LOCATION_EVENT_CATEGORY,
    expiresAt: admin.firestore.Timestamp.fromMillis(
      params.nowMs + TRACKING_LOCATION_TTL_MS,
    ),
    data: {
      actorUid: params.childUid,
      actorName: params.childName,
      actorRole: "child",
      childUid: params.childUid,
      childName: params.childName,
      familyId: params.familyId,
      status: normalizedStatus,
      timestamp: String(params.nowMs),
      eventKey,
      title,
      body,
      eventCategory: TRACKING_LOCATION_EVENT_CATEGORY,
    },
  };
}

export function isExpiredTrackingLocationNotification(params: {
  eventCategory: unknown;
  expiresAt: unknown;
  nowMs: number;
}): boolean {
  if (params.eventCategory !== TRACKING_LOCATION_EVENT_CATEGORY) {
    return false;
  }

  const expiresAtMs = toMillis(params.expiresAt);
  return expiresAtMs != null && expiresAtMs <= params.nowMs;
}
