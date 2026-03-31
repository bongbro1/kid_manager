import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onValueWritten } from "firebase-functions/v2/database";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { admin, db } from "../bootstrap";
import {
  MAPBOX_ACCESS_TOKEN,
  REGION,
  RTDB_TRIGGER_REGION,
  TZ,
} from "../config";
import { chunk, mustNumber, mustString, normalizeTimeZone, zonedDateParts } from "../helpers";
import {
  requireAdultManagerOfChild,
  requireParentGuardianOrChildSelf,
} from "../services/child";
import {
  buildSuggestedSafeRoutes,
  isPreviewSafeRouteId,
  persistSelectedSafeRoute,
} from "../services/safeRouteDirectionsService";
import {
  createSafeRouteAlert,
  sendSafeRouteAlertPush,
  type SafeRouteAlertKind,
} from "../services/safeRouteAlertsService";
import {
  asSafeRouteCurrentTripSnapshotRecord,
  buildSafeRouteCurrentTripSnapshot,
  MONITORED_TRIP_STATUSES,
  SAFE_ROUTE_CURRENT_TRIPS_COLLECTION,
  selectTripFromCurrentTripSnapshot,
  VISIBLE_TRIP_STATUSES,
  type SafeRouteTripAudience,
} from "../services/safeRouteCurrentTripService";
import {
  claimDangerZoneSafeRouteAlertDispatch,
  claimStationarySafeRouteAlertDispatch,
  claimTimedSafeRouteAlertDispatch,
} from "../services/safeRouteAlertCooldownService";
import {
  evaluateSafeRouteTripAcrossRoutes,
  parseLiveLocationRecord,
} from "../services/safeRouteMonitoringService";
import {
  assessTrustedLiveLocation,
  buildAcceptedTrustedLocationSignal,
  buildRejectedTrustedLocationSignal,
  buildTrustedLiveLocationPayload,
  parseTrustedLocationSignalRecord,
} from "../services/trustedLocationService";
import { listDangerZoneHazardsForChild } from "../services/safeRouteZonesService";
import {
  enforceQuota,
  FREE_SAFE_ROUTE_LIMIT,
  getRemainingQuota,
  SAFE_ROUTE_LIMIT_ERROR,
} from "../services/subscriptionQuota";
import { haversineMeters } from "../utils/safeRouteGeo";
import {
  RoutePointRecord,
  SafeRouteRecord,
  SafeRouteTravelMode,
  TripRecord,
  TripStatus,
} from "../types";
const SAFE_ROUTE_ALERT_COOLDOWN_MS = 3 * 60 * 1000;
const START_POINT_EXIT_RADIUS_METERS = 30;
const DESTINATION_ARRIVAL_RADIUS_METERS = 10;
const DESTINATION_ROUTE_PROXIMITY_METERS = 18;
const ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS = 120;
const STATIONARY_RADIUS_METERS = 18;
const STATIONARY_ALERT_DELAY_MS = 5 * 60 * 1000;
const SAFE_ROUTE_SCHEDULE = "every 1 minutes";
const FAMILY_LIVE_LOCATIONS_ROOT = "live_locations_by_family";

function parseSafeRouteTravelMode(value: unknown): SafeRouteTravelMode {
  const normalized = mustString(value ?? "walking", "travelMode");
  switch (normalized) {
    case "walking":
    case "motorbike":
    case "pickup":
    case "otherVehicle":
      return normalized;
    default:
      throw new HttpsError(
        "invalid-argument",
        "Unsupported safe route travel mode"
      );
  }
}

function parseTripStatus(value: unknown): TripStatus {
  const normalized = mustString(value, "status");
  switch (normalized) {
    case "planned":
    case "active":
    case "temporarilyDeviated":
    case "deviated":
    case "completed":
    case "cancelled":
      return normalized;
    default:
      throw new HttpsError("invalid-argument", "Unsupported trip status");
  }
}

function parseRepeatWeekdays(value: unknown) {
  if (!Array.isArray(value)) {
    return [] as number[];
  }

  return value
    .map((item) => Number(item))
    .filter((day) => Number.isInteger(day) && day >= 1 && day <= 7)
    .sort((left, right) => left - right);
}

function parseRouteIdList(value: unknown) {
  if (!Array.isArray(value)) {
    return [] as string[];
  }

  return value
    .map((item) => String(item ?? "").trim())
    .filter((id) => id.length > 0)
    .filter((id, index, list) => list.indexOf(id) === index);
}

function readFamilyIdFromLocationRecord(raw: unknown): string | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }

  const familyId = (raw as Record<string, unknown>).familyId;
  if (typeof familyId !== "string" || !familyId.trim()) {
    return null;
  }
  return familyId.trim();
}

function shouldCreatePlannedTrip(params: {
  scheduledStartAt: number | null;
  repeatWeekdays: number[];
  nowMs: number;
}) {
  if (params.repeatWeekdays.length > 0) {
    return true;
  }
  if (params.scheduledStartAt == null) {
    return false;
  }
  return params.scheduledStartAt > params.nowMs + 30 * 1000;
}

function isTripScheduleDue(
  trip: TripRecord,
  nowMs: number,
  timeZone: string,
) {
  if (trip.status !== "planned") {
    return false;
  }

  const scheduledStartAt = trip.scheduledStartAt;
  const repeatWeekdays = trip.repeatWeekdays ?? [];
  if (scheduledStartAt == null) {
    return false;
  }

  if (repeatWeekdays.length === 0) {
    return nowMs >= scheduledStartAt;
  }

  const nowParts = zonedDateParts(nowMs, timeZone);
  const scheduledParts = zonedDateParts(scheduledStartAt, timeZone);

  if (nowParts.dayKey < scheduledParts.dayKey) {
    return false;
  }
  if (!repeatWeekdays.includes(nowParts.weekday)) {
    return false;
  }
  if (nowParts.minutesOfDay < scheduledParts.minutesOfDay) {
    return false;
  }
  if (trip.lastScheduledActivationAt != null) {
    const lastActivationParts = zonedDateParts(
      trip.lastScheduledActivationAt,
      timeZone
    );
    if (lastActivationParts.dayKey == nowParts.dayKey) {
      return false;
    }
  }

  return true;
}

function parseRoutePoint(
  raw: any,
  fieldName: string,
  sequence: number
): RoutePointRecord {
  const latitude = mustNumber(
    raw?.latitude ?? raw?.lat,
    `${fieldName}.latitude`
  );
  const longitude = mustNumber(
    raw?.longitude ?? raw?.lng,
    `${fieldName}.longitude`
  );
  return {
    latitude,
    longitude,
    sequence,
  };
}

function parseOptionalString(value: unknown) {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function parsePreviewRouteRecord(
  raw: any,
  fieldName: string,
): SafeRouteRecord {
  const id = mustString(raw?.id, `${fieldName}.id`);
  const childId = mustString(raw?.childId, `${fieldName}.childId`);
  const travelMode = parseSafeRouteTravelMode(raw?.travelMode);
  const pointsRaw = Array.isArray(raw?.points) ? raw.points : [];
  if (pointsRaw.length < 2) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName}.points must contain at least two points`,
    );
  }

  const points = pointsRaw.map((point: unknown, index: number) =>
    parseRoutePoint(point, `${fieldName}.points[${index}]`, index),
  );
  const distanceMeters = Number(raw?.distanceMeters ?? 0);
  const durationSeconds = Number(raw?.durationSeconds ?? 0);
  const corridorWidthMeters = Number(raw?.corridorWidthMeters ?? 50);
  if (!Number.isFinite(distanceMeters) || distanceMeters < 0) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName}.distanceMeters must be a non-negative number`,
    );
  }
  if (!Number.isFinite(durationSeconds) || durationSeconds < 0) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName}.durationSeconds must be a non-negative number`,
    );
  }
  if (!Number.isFinite(corridorWidthMeters) || corridorWidthMeters <= 0) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName}.corridorWidthMeters must be a positive number`,
    );
  }

  return {
    id,
    childId,
    parentId: parseOptionalString(raw?.parentId),
    name: parseOptionalString(raw?.name) ?? "Safe route",
    startPoint: points[0],
    endPoint: points[points.length - 1],
    points,
    hazards: [],
    corridorWidthMeters,
    distanceMeters,
    durationSeconds,
    travelMode,
    createdAt: Number(raw?.createdAt ?? Date.now()),
    updatedAt: Number(raw?.updatedAt ?? Date.now()),
    profile: parseOptionalString(raw?.profile) ?? undefined,
  };
}

function parseOptionalPreviewRouteRecord(
  raw: any,
  fieldName: string,
): SafeRouteRecord | null {
  if (raw == null) {
    return null;
  }

  return parsePreviewRouteRecord(raw, fieldName);
}

function parsePreviewRouteList(value: unknown, fieldName: string) {
  if (!Array.isArray(value)) {
    return [] as SafeRouteRecord[];
  }

  return value.map((item, index) =>
    parsePreviewRouteRecord(item, `${fieldName}[${index}]`),
  );
}

function asTripRecord(
  doc: FirebaseFirestore.DocumentSnapshot
): TripRecord | null {
  if (!doc.exists) return null;
  const data = doc.data() as any;
  return {
    id: doc.id,
    childId: String(data.childId ?? ""),
    parentId: String(data.parentId ?? ""),
    routeId: String(data.routeId ?? ""),
    alternativeRouteIds: parseRouteIdList(data.alternativeRouteIds),
    currentRouteId:
      data.currentRouteId == null ? null : String(data.currentRouteId),
    routeName: data.routeName == null ? null : String(data.routeName),
    status: parseTripStatus(data.status ?? "planned"),
    reason: data.reason == null ? null : String(data.reason),
    consecutiveDeviationCount: Number(data.consecutiveDeviationCount ?? 0),
    currentDistanceFromRouteMeters: Number(
      data.currentDistanceFromRouteMeters ?? 0
    ),
    startedAt: Number(data.startedAt ?? Date.now()),
    updatedAt: Number(data.updatedAt ?? Date.now()),
    scheduledStartAt:
      data.scheduledStartAt == null ? null : Number(data.scheduledStartAt),
    repeatWeekdays: parseRepeatWeekdays(data.repeatWeekdays),
    lastScheduledActivationAt:
      data.lastScheduledActivationAt == null
        ? null
        : Number(data.lastScheduledActivationAt),
    lastLocation: data.lastLocation ?? null,
    lastDeviationAlertAt:
      data.lastDeviationAlertAt == null
        ? null
        : Number(data.lastDeviationAlertAt),
    lastDangerAlertAt:
      data.lastDangerAlertAt == null ? null : Number(data.lastDangerAlertAt),
    lastDangerHazardId:
      data.lastDangerHazardId == null ? null : String(data.lastDangerHazardId),
    lastBackOnRouteAlertAt:
      data.lastBackOnRouteAlertAt == null
        ? null
        : Number(data.lastBackOnRouteAlertAt),
    lastReturnedToStartAlertAt:
      data.lastReturnedToStartAlertAt == null
        ? null
        : Number(data.lastReturnedToStartAlertAt),
    lastStationaryAlertAt:
      data.lastStationaryAlertAt == null
        ? null
        : Number(data.lastStationaryAlertAt),
    hasLeftStartArea: data.hasLeftStartArea === true,
    isNearStartArea: data.isNearStartArea === true,
    stationaryAnchorLatitude:
      data.stationaryAnchorLatitude == null
        ? null
        : Number(data.stationaryAnchorLatitude),
    stationaryAnchorLongitude:
      data.stationaryAnchorLongitude == null
        ? null
        : Number(data.stationaryAnchorLongitude),
    stationarySinceAt:
      data.stationarySinceAt == null ? null : Number(data.stationarySinceAt),
    hasStationaryAlertActive: data.hasStationaryAlertActive === true,
  };
}

function asRouteRecord(
  doc: FirebaseFirestore.DocumentSnapshot
): SafeRouteRecord | null {
  if (!doc.exists) return null;
  const data = doc.data() as any;
  return {
    id: doc.id,
    childId: String(data.childId ?? ""),
    parentId: data.parentId == null ? null : String(data.parentId),
    name: String(data.name ?? ""),
    startPoint: data.startPoint as RoutePointRecord,
    endPoint: data.endPoint as RoutePointRecord,
    points: (data.points ?? []) as RoutePointRecord[],
    hazards: (data.hazards ?? []) as SafeRouteRecord["hazards"],
    corridorWidthMeters: Number(data.corridorWidthMeters ?? 50),
    distanceMeters: Number(data.distanceMeters ?? 0),
    durationSeconds: Number(data.durationSeconds ?? 0),
    travelMode: parseSafeRouteTravelMode(data.travelMode ?? "walking"),
    createdAt: Number(data.createdAt ?? Date.now()),
    updatedAt: Number(data.updatedAt ?? Date.now()),
    profile: data.profile == null ? undefined : String(data.profile),
  };
}

async function loadRouteOrThrow(routeId: string) {
  const routeSnap = await db.collection("routes").doc(routeId).get();
  const route = asRouteRecord(routeSnap);
  if (!route) {
    throw new HttpsError("not-found", "Safe route not found");
  }
  return route;
}

async function loadTripsByChildId(childId: string) {
  const snap = await db
    .collection("trips")
    .where("childId", "==", childId)
    .get();

  return snap.docs
    .map((doc) => asTripRecord(doc))
    .filter((trip): trip is TripRecord => trip !== null);
}

async function syncCurrentTripSnapshotByChildId(childId: string) {
  const normalizedChildId = childId.trim();
  if (!normalizedChildId) {
    return null;
  }

  const trips = await loadTripsByChildId(normalizedChildId);
  const snapshot = buildSafeRouteCurrentTripSnapshot({
    childId: normalizedChildId,
    trips,
    nowMs: Date.now(),
  });
  const snapshotRef = db
    .collection(SAFE_ROUTE_CURRENT_TRIPS_COLLECTION)
    .doc(normalizedChildId);

  if (
    snapshot.adultCurrentTrip == null &&
    snapshot.adultRecentCompletedTrip == null &&
    snapshot.childMonitorTrip == null
  ) {
    await snapshotRef.delete().catch(() => {});
    return null;
  }

  await snapshotRef.set(snapshot, { merge: true });
  return snapshot;
}

async function readCurrentTripSnapshotByChildId(childId: string) {
  const normalizedChildId = childId.trim();
  if (!normalizedChildId) {
    return null;
  }

  const snapshotSnap = await db
    .collection(SAFE_ROUTE_CURRENT_TRIPS_COLLECTION)
    .doc(normalizedChildId)
    .get();
  if (!snapshotSnap.exists) {
    return null;
  }

  return asSafeRouteCurrentTripSnapshotRecord(snapshotSnap.data());
}

async function ensureCurrentTripSnapshotByChildId(childId: string) {
  const existing = await readCurrentTripSnapshotByChildId(childId);
  if (existing != null) {
    return existing;
  }
  return syncCurrentTripSnapshotByChildId(childId);
}

async function findCurrentTripByChildId(params: {
  childId: string;
  audience: SafeRouteTripAudience;
}) {
  const snapshot = await ensureCurrentTripSnapshotByChildId(params.childId);
  return selectTripFromCurrentTripSnapshot({
    snapshot,
    audience: params.audience,
    nowMs: Date.now(),
  });
}

async function findMonitorableTripByChildId(childId: string) {
  const snapshot = await ensureCurrentTripSnapshotByChildId(childId);
  const trip = selectTripFromCurrentTripSnapshot({
    snapshot,
    audience: "child_monitor",
    nowMs: Date.now(),
  });
  if (trip == null || !MONITORED_TRIP_STATUSES.includes(trip.status)) {
    return null;
  }
  return trip;
}

async function appendCancelExistingTripsToBatch(params: {
  childId: string;
  batch: FirebaseFirestore.WriteBatch;
  nowMs: number;
}) {
  const { childId, batch, nowMs } = params;
  const snap = await db
    .collection("trips")
    .where("childId", "==", childId)
    .get();

  snap.docs.forEach((doc) => {
    const trip = asTripRecord(doc);
    if (!trip || !VISIBLE_TRIP_STATUSES.includes(trip.status)) return;
    batch.set(
      doc.ref,
      {
        status: "cancelled",
        reason: "Superseded by new safe route trip",
        updatedAt: nowMs,
      },
      {merge: true}
    );
  });
}

function buildActivatedTripFromTemplate(params: {
  template: TripRecord;
  nowMs: number;
}): TripRecord {
  const { template, nowMs } = params;
  return {
    id: db.collection("trips").doc().id,
    childId: template.childId,
    parentId: template.parentId,
    routeId: template.routeId,
    alternativeRouteIds: template.alternativeRouteIds ?? [],
    currentRouteId: template.routeId,
    routeName: template.routeName ?? null,
    status: "active",
    reason: "Activated by schedule",
    consecutiveDeviationCount: 0,
    currentDistanceFromRouteMeters: 0,
    startedAt: nowMs,
    updatedAt: nowMs,
    scheduledStartAt: nowMs,
    repeatWeekdays: template.repeatWeekdays ?? [],
    lastScheduledActivationAt: null,
    lastLocation: null,
    lastDeviationAlertAt: null,
    lastDangerAlertAt: null,
    lastDangerHazardId: null,
    lastBackOnRouteAlertAt: null,
    lastReturnedToStartAlertAt: null,
    lastStationaryAlertAt: null,
    hasLeftStartArea: false,
    isNearStartArea: false,
    stationaryAnchorLatitude: null,
    stationaryAnchorLongitude: null,
    stationarySinceAt: nowMs,
    hasStationaryAlertActive: false,
  };
}

async function getChildName(childId: string) {
  const childSnap = await db.doc(`users/${childId}`).get();
  const child = childSnap.data() ?? {};
  return String(child.displayName ?? child.name ?? "Tre");
}

async function loadRoutesForTrip(trip: TripRecord) {
  const routeIds = [
    trip.routeId,
    ...(trip.alternativeRouteIds ?? []),
  ].filter((id, index, list) => id.length > 0 && list.indexOf(id) === index);

  const routes = (
    await Promise.all(routeIds.map((routeId) => loadRouteOrThrow(routeId)))
  ).filter((route) => route.childId === trip.childId);

  if (routes.length === 0) {
    throw new HttpsError("not-found", "No safe routes found for trip");
  }

  return routes;
}

async function loadChildTimeZoneMap(childIds: string[]) {
  const uniqueChildIds = childIds
    .map((childId) => childId.trim())
    .filter((childId) => childId.length > 0)
    .filter((childId, index, list) => list.indexOf(childId) === index);

  const result = new Map<string, string>();
  if (uniqueChildIds.length === 0) {
    return result;
  }

  const docIdField = admin.firestore.FieldPath.documentId();
  const snapshots = await Promise.all(
    chunk(uniqueChildIds, 30).map((batchIds) =>
      db.collection("users").where(docIdField, "in", batchIds).get()
    )
  );

  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      const data = doc.data() ?? {};
      result.set(doc.id, normalizeTimeZone(data.timezone, TZ));
    }
  }

  for (const childId of uniqueChildIds) {
    if (!result.has(childId)) {
      result.set(childId, TZ);
    }
  }

  return result;
}

async function dispatchSafeRouteAlert(params: {
  toUid: string;
  trip: TripRecord;
  route: SafeRouteRecord;
  kind: SafeRouteAlertKind;
  childName: string;
  distanceFromRouteMeters: number;
  hazard?: SafeRouteRecord["hazards"][number] | null;
  stationaryDurationMinutes?: number | null;
}): Promise<void> {
  await createSafeRouteAlert({
    trip: params.trip,
    route: params.route,
    kind: params.kind,
    childName: params.childName,
    distanceFromRouteMeters: params.distanceFromRouteMeters,
    hazard: params.hazard,
    stationaryDurationMinutes: params.stationaryDurationMinutes,
  });
  await sendSafeRouteAlertPush({
    toUid: params.toUid,
    trip: params.trip,
    route: params.route,
    childName: params.childName,
    kind: params.kind,
    distanceFromRouteMeters: params.distanceFromRouteMeters,
    hazard: params.hazard,
    stationaryDurationMinutes: params.stationaryDurationMinutes,
  });
}

async function validateAlternativeRoutes(params: {
  parentUid: string;
  childId: string;
  primaryRoute: SafeRouteRecord;
  candidateRouteIds: string[];
}) {
  const { parentUid, childId, primaryRoute, candidateRouteIds } = params;
  const uniqueIds = candidateRouteIds
    .filter((routeId) => routeId !== primaryRoute.id)
    .filter((routeId, index, list) => list.indexOf(routeId) === index)
    .slice(0, 2);

  const routes = await Promise.all(
    uniqueIds.map((routeId) => loadRouteOrThrow(routeId))
  );

  return routes
    .filter(
      (route) =>
        route.childId === childId &&
        (route.parentId == null || route.parentId === parentUid) &&
        route.travelMode === primaryRoute.travelMode &&
        haversineMeters(
          route.startPoint.latitude,
          route.startPoint.longitude,
          primaryRoute.startPoint.latitude,
          primaryRoute.startPoint.longitude
        ) <= ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS &&
        haversineMeters(
          route.endPoint.latitude,
          route.endPoint.longitude,
          primaryRoute.endPoint.latitude,
          primaryRoute.endPoint.longitude
        ) <= ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS
    )
    .map((route) => route.id);
}

function selectValidAlternativeRoutes(params: {
  parentUid: string;
  childId: string;
  primaryRoute: SafeRouteRecord;
  candidateRoutes: SafeRouteRecord[];
}) {
  const { parentUid, childId, primaryRoute, candidateRoutes } = params;
  const uniqueRoutes = candidateRoutes
    .filter((route) => route.id !== primaryRoute.id)
    .filter(
      (route, index, list) =>
        list.findIndex((candidate) => candidate.id === route.id) === index,
    )
    .slice(0, 2);

  return uniqueRoutes.filter(
    (route) =>
      route.childId === childId &&
      (route.parentId == null || route.parentId === parentUid) &&
      route.travelMode === primaryRoute.travelMode &&
      haversineMeters(
        route.startPoint.latitude,
        route.startPoint.longitude,
        primaryRoute.startPoint.latitude,
        primaryRoute.startPoint.longitude,
      ) <= ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS &&
      haversineMeters(
        route.endPoint.latitude,
        route.endPoint.longitude,
        primaryRoute.endPoint.latitude,
        primaryRoute.endPoint.longitude,
      ) <= ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS,
  );
}

export const getSuggestedSafeRoutes = onCall(
  {
    region: REGION,
    secrets: [MAPBOX_ACCESS_TOKEN],
  },
  async (request) => {
    const requesterUid = request.auth?.uid;
    if (!requesterUid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const childId = mustString(request.data?.childId, "childId");
    const access = await requireAdultManagerOfChild(requesterUid, childId);
    const ownerParentUid = access.ownerParentUid;

    const start = parseRoutePoint(request.data?.start, "start", 0);
    const end = parseRoutePoint(request.data?.end, "end", 1);
    const travelMode = parseSafeRouteTravelMode(request.data?.travelMode);
    const existingRoutesSnap = await db
      .collection("routes")
      .where("childId", "==", childId)
      .where("parentId", "==", ownerParentUid)
      .get();
    const currentRouteCount = existingRoutesSnap.size;

    await enforceQuota({
      ownerUid: ownerParentUid,
      currentCount: currentRouteCount,
      limit: FREE_SAFE_ROUTE_LIMIT,
      errorMessage: SAFE_ROUTE_LIMIT_ERROR,
      feature: "safe_route",
    });

    const quota = await getRemainingQuota({
      ownerUid: ownerParentUid,
      currentCount: currentRouteCount,
      limit: FREE_SAFE_ROUTE_LIMIT,
    });

    const routes = await buildSuggestedSafeRoutes({
      childId,
      parentId: ownerParentUid,
      start,
      end,
      travelMode,
      maxRoutes: quota.unlimited ? undefined : quota.remaining,
    });

    return {
      ok: true,
      routes,
    };
  }
);

export const startSafeRouteTrip = onCall(
  {
    region: REGION,
  },
  async (request) => {
    const requesterUid = request.auth?.uid;
    if (!requesterUid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const routeId = mustString(
      request.data?.trip?.routeId ?? request.data?.routeId,
      "routeId"
    );
    const previewRoute = parseOptionalPreviewRouteRecord(
      request.data?.trip?.previewRoute ?? request.data?.previewRoute,
      "previewRoute",
    );
    const previewAlternativeRoutes = parsePreviewRouteList(
      request.data?.trip?.previewAlternativeRoutes ??
        request.data?.previewAlternativeRoutes,
      "previewAlternativeRoutes",
    );
    const selectedAlternativeRouteIds = parseRouteIdList(
      request.data?.trip?.alternativeRouteIds ?? request.data?.alternativeRouteIds,
    );

    let route: SafeRouteRecord;
    let ownerParentUid: string;
    let alternativeRouteIds: string[];

    if (previewRoute != null) {
      if (!isPreviewSafeRouteId(previewRoute.id) || previewRoute.id !== routeId) {
        throw new HttpsError(
          "invalid-argument",
          "previewRoute must match the selected routeId",
        );
      }

      const access = await requireAdultManagerOfChild(
        requesterUid,
        previewRoute.childId,
      );
      ownerParentUid = access.ownerParentUid;
      if (
        previewRoute.parentId != null &&
        previewRoute.parentId !== ownerParentUid
      ) {
        throw new HttpsError(
          "permission-denied",
          "You cannot start a trip on this route",
        );
      }

      const requestedPreviewAlternatives = previewAlternativeRoutes.filter((candidate) =>
        selectedAlternativeRouteIds.includes(candidate.id),
      );
      if (requestedPreviewAlternatives.length !== selectedAlternativeRouteIds.length) {
        throw new HttpsError(
          "invalid-argument",
          "Selected preview alternative routes are incomplete",
        );
      }

      const validPreviewAlternatives = selectValidAlternativeRoutes({
        parentUid: ownerParentUid,
        childId: previewRoute.childId,
        primaryRoute: previewRoute,
        candidateRoutes: requestedPreviewAlternatives,
      });
      if (validPreviewAlternatives.length !== requestedPreviewAlternatives.length) {
        throw new HttpsError(
          "invalid-argument",
          "Selected preview alternative routes are invalid",
        );
      }

      const existingRoutesSnap = await db
        .collection("routes")
        .where("childId", "==", previewRoute.childId)
        .where("parentId", "==", ownerParentUid)
        .get();
      const quota = await getRemainingQuota({
        ownerUid: ownerParentUid,
        currentCount: existingRoutesSnap.size,
        limit: FREE_SAFE_ROUTE_LIMIT,
      });
      const routesToPersist = 1 + validPreviewAlternatives.length;
      if (!quota.unlimited && routesToPersist > quota.remaining) {
        throw new HttpsError(
          "resource-exhausted",
          SAFE_ROUTE_LIMIT_ERROR,
        );
      }

      route = await persistSelectedSafeRoute({
        route: previewRoute,
        childId: previewRoute.childId,
        parentId: ownerParentUid,
      });
      const persistedAlternatives = await Promise.all(
        validPreviewAlternatives.map((candidate) =>
          persistSelectedSafeRoute({
            route: candidate,
            childId: previewRoute.childId,
            parentId: ownerParentUid,
          }),
        ),
      );
      alternativeRouteIds = persistedAlternatives.map((candidate) => candidate.id);
    } else {
      route = await loadRouteOrThrow(routeId);
      const access = await requireAdultManagerOfChild(requesterUid, route.childId);
      ownerParentUid = access.ownerParentUid;

      if (route.parentId != null && route.parentId !== ownerParentUid) {
        throw new HttpsError(
          "permission-denied",
          "You cannot start a trip on this route"
        );
      }

      alternativeRouteIds = await validateAlternativeRoutes({
        parentUid: ownerParentUid,
        childId: route.childId,
        primaryRoute: route,
        candidateRouteIds: selectedAlternativeRouteIds,
      });
    }

    const tripRef = db.collection("trips").doc();
    const now = Date.now();
    const batch = db.batch();
    const scheduledStartAtRaw =
      request.data?.trip?.scheduledStartAt ?? request.data?.scheduledStartAt;
    const scheduledStartAt =
      scheduledStartAtRaw == null ? null : Number(scheduledStartAtRaw);
    const repeatWeekdays = parseRepeatWeekdays(
      request.data?.trip?.repeatWeekdays ?? request.data?.repeatWeekdays
    );
    const shouldCreatePlanned = shouldCreatePlannedTrip({
      scheduledStartAt,
      repeatWeekdays,
      nowMs: now,
    });
    const trip = {
      id: tripRef.id,
      childId: route.childId,
      parentId: ownerParentUid,
      routeId: route.id,
      alternativeRouteIds,
      currentRouteId: route.id,
      routeName: route.name,
      status: shouldCreatePlanned ? "planned" : "active",
      reason: shouldCreatePlanned ? "Scheduled safe route trip" : null,
      consecutiveDeviationCount: 0,
      currentDistanceFromRouteMeters: 0,
      startedAt: shouldCreatePlanned && scheduledStartAt != null ? scheduledStartAt : now,
      updatedAt: now,
      scheduledStartAt,
      repeatWeekdays,
      lastScheduledActivationAt: null,
      lastLocation: null,
      lastDeviationAlertAt: null,
      lastDangerAlertAt: null,
      lastDangerHazardId: null,
      lastBackOnRouteAlertAt: null,
      lastReturnedToStartAlertAt: null,
      lastStationaryAlertAt: null,
      hasLeftStartArea: false,
      isNearStartArea: false,
      stationaryAnchorLatitude: route.startPoint.latitude,
      stationaryAnchorLongitude: route.startPoint.longitude,
      stationarySinceAt: now,
      hasStationaryAlertActive: false,
    } satisfies TripRecord;

    await appendCancelExistingTripsToBatch({
      childId: route.childId,
      batch,
      nowMs: now,
    });
    batch.set(tripRef, trip, {merge: true});
    await batch.commit();
    await syncCurrentTripSnapshotByChildId(route.childId);
    return {
      ok: true,
      trip,
    };
  }
);

export const getSafeRouteTripHistoryByChildId = onCall(
  {
    region: REGION,
  },
  async (request) => {
    const requesterUid = request.auth?.uid;
    if (!requesterUid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const childId = mustString(request.data?.childId, "childId");
    await requireParentGuardianOrChildSelf(requesterUid, childId);

    const snap = await db
      .collection("trips")
      .where("childId", "==", childId)
      .get();

    const trips = snap.docs
      .map((doc) => asTripRecord(doc))
      .filter((trip): trip is TripRecord => trip !== null)
      .sort((left, right) => right.updatedAt - left.updatedAt)
      .slice(0, 30);

    return {
      ok: true,
      trips,
    };
  }
);

export const updateSafeRouteTripStatus = onCall(
  {
    region: REGION,
  },
  async (request) => {
    const requesterUid = request.auth?.uid;
    if (!requesterUid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const tripId = mustString(request.data?.tripId, "tripId");
    const status = parseTripStatus(request.data?.status);
    const reason =
      request.data?.reason == null ? null : String(request.data.reason);

    const tripRef = db.collection("trips").doc(tripId);
    const trip = asTripRecord(await tripRef.get());
    if (!trip) {
      throw new HttpsError("not-found", "Trip not found");
    }
    await requireAdultManagerOfChild(requesterUid, trip.childId);

    await tripRef.set(
      {
        status,
        reason,
        updatedAt: Date.now(),
      },
      {merge: true}
    );
    await syncCurrentTripSnapshotByChildId(trip.childId);

    return {ok: true};
  }
);

export const getActiveSafeRouteTripByChildId = onCall(
  {
    region: REGION,
  },
  async (request) => {
    const requesterUid = request.auth?.uid;
    if (!requesterUid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const childId = mustString(request.data?.childId, "childId");
    await requireParentGuardianOrChildSelf(requesterUid, childId);

    const audience: SafeRouteTripAudience =
      requesterUid === childId ? "child_monitor" : "adult_manager";
    const trip = await findCurrentTripByChildId({
      childId,
      audience,
    });

    return {
      ok: true,
      trip,
    };
  }
);

export const syncSafeRouteCurrentTripSnapshot = onDocumentWritten(
  {
    document: "trips/{tripId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const childIds = [
      typeof before?.childId === "string" ? before.childId.trim() : "",
      typeof after?.childId === "string" ? after.childId.trim() : "",
    ].filter((childId, index, list) =>
      childId.length > 0 && list.indexOf(childId) === index
    );

    await Promise.all(
      childIds.map((childId) => syncCurrentTripSnapshotByChildId(childId))
    );
  }
);

export const getSafeRouteById = onCall(
  {
    region: REGION,
  },
  async (request) => {
    const requesterUid = request.auth?.uid;
    if (!requesterUid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const routeId = mustString(request.data?.routeId, "routeId");
    const route = await loadRouteOrThrow(routeId);
    await requireParentGuardianOrChildSelf(requesterUid, route.childId);

    return {
      ok: true,
      route,
    };
  }
);

export const activateScheduledSafeRouteTrips = onSchedule(
  {
    region: REGION,
    schedule: SAFE_ROUTE_SCHEDULE,
    timeZone: TZ,
  },
  async () => {
    const nowMs = Date.now();
    const [plannedSnap, activeSnap] = await Promise.all([
      db.collection("trips").where("status", "==", "planned").get(),
      db
        .collection("trips")
        .where("status", "in", MONITORED_TRIP_STATUSES)
        .get(),
    ]);

    const busyChildIds = new Set(
      activeSnap.docs
        .map((doc) => asTripRecord(doc))
        .filter((trip): trip is TripRecord => trip !== null)
        .map((trip) => trip.childId)
    );
    const plannedTrips = plannedSnap.docs
      .map((doc) => asTripRecord(doc))
      .filter((trip): trip is TripRecord => trip !== null);
    const childTimeZones = await loadChildTimeZoneMap(
      plannedTrips.map((trip) => trip.childId)
    );

    const dueTrips = plannedTrips
      .filter((trip) =>
        isTripScheduleDue(
          trip,
          nowMs,
          childTimeZones.get(trip.childId) ?? TZ
        )
      )
      .sort(
        (left, right) =>
          (left.scheduledStartAt ?? left.updatedAt) -
          (right.scheduledStartAt ?? right.updatedAt)
      );

    let activatedCount = 0;

    for (const trip of dueTrips) {
      if (busyChildIds.has(trip.childId)) {
        continue;
      }

      if ((trip.repeatWeekdays ?? []).length > 0) {
        const activeTrip = buildActivatedTripFromTemplate({
          template: trip,
          nowMs,
        });
        await db.collection("trips").doc(activeTrip.id).set(activeTrip, {
          merge: true,
        });
        await db.collection("trips").doc(trip.id).set(
          {
            lastScheduledActivationAt: nowMs,
          },
          { merge: true }
        );
      } else {
        await db.collection("trips").doc(trip.id).set(
          {
            status: "active",
            reason: "Activated by schedule",
            startedAt: nowMs,
            updatedAt: nowMs,
            lastScheduledActivationAt: nowMs,
          },
          { merge: true }
        );
      }

      busyChildIds.add(trip.childId);
      activatedCount++;
    }

    console.log(
      `[activateScheduledSafeRouteTrips] planned=${plannedSnap.size} due=${dueTrips.length} activated=${activatedCount}`
    );
  }
);

export const syncSafeRouteLiveLocation = onValueWritten(
  {
    ref: "locations/{childId}/current",
    region: RTDB_TRIGGER_REGION,
  },
  async (event) => {
    const childId = String(event.params.childId ?? "");
    const targetRef = admin.database().ref(`live_locations/${childId}`);
    const trustSignalRef = admin.database().ref(`live_location_trust/${childId}`);
    const previousFamilyId = readFamilyIdFromLocationRecord(
      event.data.before.exists() ? event.data.before.val() : null
    );
    const nextFamilyId = readFamilyIdFromLocationRecord(
      event.data.after.exists() ? event.data.after.val() : null
    );

    const removeFamilyMirror = (familyId: string) =>
      admin
        .database()
        .ref(`${FAMILY_LIVE_LOCATIONS_ROOT}/${familyId}/${childId}`)
        .remove();

    if (!event.data.after.exists()) {
      const removals: Array<Promise<unknown>> = [
        targetRef.remove(),
        trustSignalRef.remove(),
      ];
      if (previousFamilyId) {
        removals.push(removeFamilyMirror(previousFamilyId));
      }
      await Promise.all(removals);
      return;
    }

    const rawLiveLocation = parseLiveLocationRecord(childId, event.data.after.val());
    const [previousTrustedSnap, previousSignalSnap] = await Promise.all([
      targetRef.get(),
      trustSignalRef.get(),
    ]);
    const previousTrusted =
      previousTrustedSnap.exists() && previousTrustedSnap.val()
        ? parseLiveLocationRecord(childId, previousTrustedSnap.val())
        : null;
    const previousSignal = previousSignalSnap.exists()
      ? parseTrustedLocationSignalRecord(previousSignalSnap.val())
      : null;
    const trust = assessTrustedLiveLocation({
      current: rawLiveLocation,
      previousTrusted,
    });
    const nowMs = Date.now();

    if (!trust.mirrorEligible) {
      const rejectedSignal = buildRejectedTrustedLocationSignal({
        childId,
        previousSignal,
        previousTrusted,
        assessment: trust,
        nowMs,
      });
      console.warn(
        `[SAFE_ROUTE] skip untrusted live location mirror childId=${childId} reason=${trust.reason}`,
      );
      const writes: Array<Promise<unknown>> = [trustSignalRef.set(rejectedSignal)];
      if (previousFamilyId && previousFamilyId !== nextFamilyId) {
        writes.push(removeFamilyMirror(previousFamilyId));
      }
      await Promise.all(writes);
      return;
    }

    const liveLocation = buildTrustedLiveLocationPayload({
      location: trust.location,
      nowMs,
    });
    const trustSignal = buildAcceptedTrustedLocationSignal({
      childId,
      previousSignal,
      location: trust.location,
      nowMs,
    });
    const writes: Array<Promise<unknown>> = [
      targetRef.set(liveLocation),
      trustSignalRef.set(trustSignal),
    ];

    if (previousFamilyId && previousFamilyId !== nextFamilyId) {
      writes.push(removeFamilyMirror(previousFamilyId));
    }
    if (nextFamilyId) {
      writes.push(
        admin
          .database()
          .ref(`${FAMILY_LIVE_LOCATIONS_ROOT}/${nextFamilyId}/${childId}`)
          .set(liveLocation)
      );
    }

    await Promise.all(writes);
  }
);

export const monitorSafeRouteLiveLocation = onValueWritten(
  {
    ref: "locations/{childId}/current",
    region: RTDB_TRIGGER_REGION,
  },
  async (event) => {
    if (!event.data.after.exists()) return;

    const childId = String(event.params.childId ?? "");
    const trip = await findMonitorableTripByChildId(childId);
    if (!trip) return;

    const rawLiveLocation = parseLiveLocationRecord(childId, event.data.after.val());
    const previousTrustedSnap = await admin
      .database()
      .ref(`live_locations/${childId}`)
      .get();
    const previousTrusted =
      previousTrustedSnap.exists() && previousTrustedSnap.val()
        ? parseLiveLocationRecord(childId, previousTrustedSnap.val())
        : null;
    const trust = assessTrustedLiveLocation({
      current: rawLiveLocation,
      previousTrusted,
    });
    if (!trust.safetyEligible) {
      console.warn(
        `[SAFE_ROUTE] skip untrusted safety location childId=${childId} reason=${trust.reason}`,
      );
      return;
    }

    const routes = await loadRoutesForTrip(trip);
    const liveLocation = trust.location;
    const hazards = await listDangerZoneHazardsForChild(childId);
    const matched = evaluateSafeRouteTripAcrossRoutes({
      trip,
      routes,
      liveLocation,
      hazards,
    });
    const route = matched.route;
    const evaluation = matched.evaluation;

    const now = Date.now();
    const tripRef = db.collection("trips").doc(trip.id);
    const updates: Partial<TripRecord> = {
      status: evaluation.nextStatus,
      reason: evaluation.nextReason,
      consecutiveDeviationCount: evaluation.nextDeviationCount,
      currentDistanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      currentRouteId: evaluation.matchedRouteId,
      updatedAt: now,
      lastLocation: liveLocation,
    };

    const childName = await getChildName(childId);
    const wasOffRoute =
      trip.status === "temporarilyDeviated" || trip.status === "deviated";
    const arrivedAtDestination =
      evaluation.distanceToDestinationMeters <=
        DESTINATION_ARRIVAL_RADIUS_METERS &&
      evaluation.distanceFromRouteMeters <= DESTINATION_ROUTE_PROXIMITY_METERS;
    const returnedToRoute =
      !arrivedAtDestination &&
      !evaluation.triggeredHazard &&
      wasOffRoute &&
      evaluation.nextStatus === "active";
    const hasLeftStartArea =
      trip.hasLeftStartArea === true ||
      evaluation.distanceFromStartMeters >= START_POINT_EXIT_RADIUS_METERS;
    const wasNearStartArea = trip.isNearStartArea === true;
    const returnedToStart =
      hasLeftStartArea &&
      !wasNearStartArea &&
      evaluation.isNearStartPoint;

    updates.hasLeftStartArea = hasLeftStartArea;
    updates.isNearStartArea = evaluation.isNearStartPoint;

    const anchorLatitude =
      trip.stationaryAnchorLatitude ?? liveLocation.latitude;
    const anchorLongitude =
      trip.stationaryAnchorLongitude ?? liveLocation.longitude;
    const distanceFromStationaryAnchor = haversineMeters(
      liveLocation.latitude,
      liveLocation.longitude,
      anchorLatitude,
      anchorLongitude
    );
    const stillAtSamePlace =
      distanceFromStationaryAnchor <= STATIONARY_RADIUS_METERS;
    const stationarySinceAt =
      stillAtSamePlace && trip.stationarySinceAt != null
        ? trip.stationarySinceAt
        : now;
    const stationaryDurationMs = now - stationarySinceAt;
    const stationaryDurationMinutes = Math.max(
      5,
      Math.round(stationaryDurationMs / 60000)
    );

    updates.stationaryAnchorLatitude = stillAtSamePlace
      ? anchorLatitude
      : liveLocation.latitude;
    updates.stationaryAnchorLongitude = stillAtSamePlace
      ? anchorLongitude
      : liveLocation.longitude;
    updates.stationarySinceAt = stationarySinceAt;
    updates.hasStationaryAlertActive = stillAtSamePlace
      ? trip.hasStationaryAlertActive === true
      : false;
    const nextTripState: TripRecord = {
      ...trip,
      status: evaluation.nextStatus,
      reason: evaluation.nextReason,
      consecutiveDeviationCount: evaluation.nextDeviationCount,
      currentDistanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      currentRouteId: evaluation.matchedRouteId,
      updatedAt: now,
      lastLocation: liveLocation,
      hasLeftStartArea,
      isNearStartArea: evaluation.isNearStartPoint,
      stationaryAnchorLatitude: updates.stationaryAnchorLatitude,
      stationaryAnchorLongitude: updates.stationaryAnchorLongitude,
      stationarySinceAt,
      hasStationaryAlertActive: updates.hasStationaryAlertActive,
    };
    const completedTripState: TripRecord = {
      ...nextTripState,
      status: "completed",
      reason: "Child arrived at safe route destination",
      consecutiveDeviationCount: 0,
      hasStationaryAlertActive: false,
    };

    if (arrivedAtDestination) {
      await dispatchSafeRouteAlert({
        toUid: trip.parentId,
        trip: completedTripState,
        route,
        kind: "arrived",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      updates.status = "completed";
      updates.reason = "Child arrived at safe route destination";
      updates.consecutiveDeviationCount = 0;
      updates.currentDistanceFromRouteMeters = evaluation.distanceFromRouteMeters;
      updates.hasStationaryAlertActive = false;
      await tripRef.set(updates, {merge: true});
      return;
    }

    if (evaluation.triggeredHazard) {
      const didClaimDangerZoneAlert =
        await claimDangerZoneSafeRouteAlertDispatch({
          tripId: trip.id,
          nowMs: now,
          cooldownMs: SAFE_ROUTE_ALERT_COOLDOWN_MS,
          hazardId: evaluation.triggeredHazard.id,
        });
      if (didClaimDangerZoneAlert) {
        await dispatchSafeRouteAlert({
          toUid: trip.parentId,
          trip: nextTripState,
          route,
          kind: "dangerZone",
          childName,
          distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
          hazard: evaluation.triggeredHazard,
        });
        updates.lastDangerAlertAt = now;
        updates.lastDangerHazardId = evaluation.triggeredHazard.id;
      }
    }

    if (returnedToStart) {
      const didClaimReturnedToStartAlert =
        await claimTimedSafeRouteAlertDispatch({
          tripId: trip.id,
          kind: "returnedToStart",
          nowMs: now,
          cooldownMs: SAFE_ROUTE_ALERT_COOLDOWN_MS,
        });
      if (didClaimReturnedToStartAlert) {
        await dispatchSafeRouteAlert({
          toUid: trip.parentId,
          trip: nextTripState,
          route,
          kind: "returnedToStart",
          childName,
          distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        });
        updates.lastReturnedToStartAlertAt = now;
      }
    } else if (returnedToRoute) {
      const didClaimBackOnRouteAlert = await claimTimedSafeRouteAlertDispatch({
        tripId: trip.id,
        kind: "backOnRoute",
        nowMs: now,
        cooldownMs: SAFE_ROUTE_ALERT_COOLDOWN_MS,
      });
      if (didClaimBackOnRouteAlert) {
        await dispatchSafeRouteAlert({
          toUid: trip.parentId,
          trip: nextTripState,
          route,
          kind: "backOnRoute",
          childName,
          distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        });
        updates.lastBackOnRouteAlertAt = now;
      }
    }

    if (
      !evaluation.triggeredHazard &&
      stillAtSamePlace &&
      stationaryDurationMs >= STATIONARY_ALERT_DELAY_MS &&
      trip.hasStationaryAlertActive !== true
    ) {
      const didClaimStationaryAlert =
        await claimStationarySafeRouteAlertDispatch({
          tripId: trip.id,
          nowMs: now,
        });
      if (didClaimStationaryAlert) {
        await dispatchSafeRouteAlert({
          toUid: trip.parentId,
          trip: {
            ...nextTripState,
            hasStationaryAlertActive: true,
            lastStationaryAlertAt: now,
          },
          route,
          kind: "stationary",
          childName,
          distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
          stationaryDurationMinutes,
        });
        updates.lastStationaryAlertAt = now;
        updates.hasStationaryAlertActive = true;
      }
    }

    if (evaluation.nextStatus === "deviated") {
      const didClaimDeviationAlert = await claimTimedSafeRouteAlertDispatch({
        tripId: trip.id,
        kind: "deviated",
        nowMs: now,
        cooldownMs: SAFE_ROUTE_ALERT_COOLDOWN_MS,
      });
      if (didClaimDeviationAlert) {
        await dispatchSafeRouteAlert({
          toUid: trip.parentId,
          trip: nextTripState,
          route,
          kind: "deviated",
          childName,
          distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        });
        updates.lastDeviationAlertAt = now;
      }
    }

    if (!evaluation.triggeredHazard) {
      updates.lastDangerHazardId = null;
    }

    await tripRef.set(updates, {merge: true});
  }
);
