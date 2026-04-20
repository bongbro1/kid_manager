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
import {
  LiveLocationRecord,
  RoutePointRecord,
  SafeRouteMonitorContextRecord,
  SafeRouteRecord,
  SafeRouteTravelMode,
  TripRecord,
  TripStatus,
} from "../types";
import { distancePointToPolylineMeters, haversineMeters } from "../utils/safeRouteGeo";
import {
  buildTrackingWatchHeartbeatUpdate,
  buildTrackingWatchStoppedUpdate,
  TRACKING_WATCH_COLLECTION,
} from "../services/trackingWatch";
const SAFE_ROUTE_ALERT_COOLDOWN_MS = 3 * 60 * 1000;
const START_POINT_EXIT_RADIUS_METERS = 30;
const DESTINATION_ARRIVAL_RADIUS_METERS = 10;
const DESTINATION_ROUTE_PROXIMITY_METERS = 18;
const ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS = 120;
const STATIONARY_RADIUS_METERS = 18;
const STATIONARY_ALERT_DELAY_MS = 5 * 60 * 1000;
const SAFE_ROUTE_SCHEDULE = "every 1 minutes";
const FAMILY_LIVE_LOCATIONS_ROOT = "live_locations_by_family";
const SAFE_ROUTE_MONITOR_MIN_EVALUATION_INTERVAL_MS = 5000;
const SAFE_ROUTE_MONITOR_MIN_EVALUATION_DISTANCE_METERS = 10;
const SAFE_ROUTE_MONITOR_DECISION_PROXIMITY_METERS = 40;
const SAFE_ROUTE_SCHEDULE_WINDOW_MS = 60 * 1000;

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

function floorToMinute(ms: number) {
  return Math.floor(ms / 60000) * 60000;
}

function computeRecurringNextActivationAt(params: {
  scheduledStartAt: number;
  repeatWeekdays: number[];
  timeZone: string;
  referenceMs: number;
}) {
  const scheduledParts = zonedDateParts(
    params.scheduledStartAt,
    params.timeZone,
  );
  let probeMs = floorToMinute(params.referenceMs);
  const endMs = probeMs + 8 * 24 * 60 * 60 * 1000;

  while (probeMs <= endMs) {
    const probeParts = zonedDateParts(probeMs, params.timeZone);
    if (
      params.repeatWeekdays.includes(probeParts.weekday) &&
      probeParts.minutesOfDay === scheduledParts.minutesOfDay
    ) {
      return probeMs;
    }
    probeMs += 60000;
  }

  return null;
}

function computeNextActivationAtForTrip(params: {
  trip: Pick<
    TripRecord,
    "status" | "scheduledStartAt" | "repeatWeekdays" | "lastScheduledActivationAt"
  >;
  timeZone: string;
  nowMs: number;
}) {
  const scheduledStartAt = params.trip.scheduledStartAt;
  if (params.trip.status !== "planned" || scheduledStartAt == null) {
    return null;
  }

  const repeatWeekdays = params.trip.repeatWeekdays ?? [];
  if (repeatWeekdays.length === 0) {
    return scheduledStartAt;
  }

  return computeRecurringNextActivationAt({
    scheduledStartAt,
    repeatWeekdays,
    timeZone: params.timeZone,
    referenceMs:
      Math.max(params.nowMs, params.trip.lastScheduledActivationAt ?? 0) +
      60000,
  });
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
    nextActivationAt:
      data.nextActivationAt == null ? null : Number(data.nextActivationAt),
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
  const childMonitorTrip =
    trips
      .filter((trip) => MONITORED_TRIP_STATUSES.includes(trip.status))
      .sort((left, right) => right.updatedAt - left.updatedAt)[0] ?? null;
  const childMonitorContext =
    childMonitorTrip == null
      ? null
      : await buildChildMonitorContextForTrip(childMonitorTrip);
  const snapshot = buildSafeRouteCurrentTripSnapshot({
    childId: normalizedChildId,
    trips,
    childMonitorContext,
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

async function syncCurrentTripSnapshotByChildIds(childIds: string[]) {
  const normalizedChildIds = childIds
    .map((childId) => childId.trim())
    .filter((childId, index, list) =>
      childId.length > 0 && list.indexOf(childId) === index,
    );

  await Promise.all(
    normalizedChildIds.map((childId) => syncCurrentTripSnapshotByChildId(childId)),
  );
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

async function isChildBusyForScheduledActivation(childId: string) {
  const snapshot = await ensureCurrentTripSnapshotByChildId(childId);
  const trip = snapshot?.childMonitorTrip;
  return trip != null && MONITORED_TRIP_STATUSES.includes(trip.status);
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

async function findMonitorableTripSnapshotByChildId(childId: string) {
  let snapshot = await ensureCurrentTripSnapshotByChildId(childId);
  const trip = selectTripFromCurrentTripSnapshot({
    snapshot,
    audience: "child_monitor",
    nowMs: Date.now(),
  });
  if (trip == null || !MONITORED_TRIP_STATUSES.includes(trip.status)) {
    return null;
  }

  if (
    snapshot?.childMonitorContext == null ||
    snapshot.childMonitorContext.tripId !== trip.id
  ) {
    snapshot = await syncCurrentTripSnapshotByChildId(childId);
  }

  if (
    snapshot?.childMonitorTrip == null ||
    snapshot.childMonitorContext == null ||
    snapshot.childMonitorContext.tripId !== snapshot.childMonitorTrip.id
  ) {
    return null;
  }

  return snapshot;
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
    nextActivationAt: null,
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

function isHazardRelevantToAnyRoute(params: {
  hazard: { latitude: number; longitude: number; radiusMeters: number };
  routes: SafeRouteRecord[];
}) {
  return params.routes.some((route) => {
    const distance = distancePointToPolylineMeters(
      params.hazard.latitude,
      params.hazard.longitude,
      route.points,
    );
    return distance <= params.hazard.radiusMeters + route.corridorWidthMeters;
  });
}

async function buildChildMonitorContextForTrip(
  trip: TripRecord,
): Promise<SafeRouteMonitorContextRecord | null> {
  if (!MONITORED_TRIP_STATUSES.includes(trip.status)) {
    return null;
  }

  const [routes, hazards] = await Promise.all([
    loadRoutesForTrip(trip),
    listDangerZoneHazardsForChild(trip.childId),
  ]);

  const relevantHazards = hazards.filter((hazard) =>
    isHazardRelevantToAnyRoute({
      hazard,
      routes,
    }),
  );

  return {
    tripId: trip.id,
    routes,
    hazards: relevantHazards,
    builtAt: Date.now(),
    minEvaluationIntervalMs: SAFE_ROUTE_MONITOR_MIN_EVALUATION_INTERVAL_MS,
    minEvaluationDistanceMeters: SAFE_ROUTE_MONITOR_MIN_EVALUATION_DISTANCE_METERS,
  };
}

function isNearMonitorDecisionArea(params: {
  liveLocation: LiveLocationRecord;
  context: SafeRouteMonitorContextRecord;
}) {
  const { liveLocation, context } = params;
  const nearDestination = context.routes.some((route) =>
    haversineMeters(
      liveLocation.latitude,
      liveLocation.longitude,
      route.endPoint.latitude,
      route.endPoint.longitude,
    ) <= SAFE_ROUTE_MONITOR_DECISION_PROXIMITY_METERS,
  );
  if (nearDestination) {
    return true;
  }

  return context.hazards.some((hazard) =>
    haversineMeters(
      liveLocation.latitude,
      liveLocation.longitude,
      hazard.latitude,
      hazard.longitude,
    ) <= hazard.radiusMeters + SAFE_ROUTE_MONITOR_DECISION_PROXIMITY_METERS,
  );
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
    const childTimeZone =
      (await loadChildTimeZoneMap([route.childId])).get(route.childId) ?? TZ;
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
      nextActivationAt: shouldCreatePlanned
        ? computeNextActivationAtForTrip(
            {
              trip: {
                status: "planned",
                scheduledStartAt,
                repeatWeekdays,
                lastScheduledActivationAt: null,
              },
              timeZone: childTimeZone,
              nowMs: now,
            },
          )
        : null,
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

    await syncCurrentTripSnapshotByChildIds(childIds);
  }
);

export const syncSafeRouteCurrentTripSnapshotOnRouteWrite = onDocumentWritten(
  {
    document: "routes/{routeId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const childIds = [
      typeof before?.childId === "string" ? before.childId.trim() : "",
      typeof after?.childId === "string" ? after.childId.trim() : "",
    ];
    await syncCurrentTripSnapshotByChildIds(childIds);
  },
);

export const syncSafeRouteCurrentTripSnapshotOnZoneWrite = onDocumentWritten(
  {
    document: "zones/{zoneId}",
    region: REGION,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    const childIds = [
      typeof before?.childId === "string" ? before.childId.trim() : "",
      typeof after?.childId === "string" ? after.childId.trim() : "",
    ];
    await syncCurrentTripSnapshotByChildIds(childIds);
  },
);

export const syncSafeRouteCurrentTripSnapshotOnLegacyZoneWrite = onValueWritten(
  {
    ref: "zonesByChild/{childId}/{zoneId}",
    region: RTDB_TRIGGER_REGION,
  },
  async (event) => {
    const childId = String(event.params.childId ?? "").trim();
    await syncCurrentTripSnapshotByChildIds([childId]);
  },
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
    const [plannedSnap, missingActivationSnap] = await Promise.all([
      db
        .collection("trips")
        .where("status", "==", "planned")
        .where("nextActivationAt", "<=", nowMs + SAFE_ROUTE_SCHEDULE_WINDOW_MS)
        .orderBy("nextActivationAt")
        .get(),
      db
        .collection("trips")
        .where("status", "==", "planned")
        .where("nextActivationAt", "==", null)
        .limit(100)
        .get(),
    ]);

    const plannedTrips = plannedSnap.docs
      .map((doc) => asTripRecord(doc))
      .filter((trip): trip is TripRecord => trip !== null);
    const missingActivationTrips = missingActivationSnap.docs
      .map((doc) => ({ doc, trip: asTripRecord(doc) }))
      .filter((entry): entry is { doc: FirebaseFirestore.QueryDocumentSnapshot; trip: TripRecord } => entry.trip != null);
    const childTimeZones = await loadChildTimeZoneMap([
      ...plannedTrips.map((trip) => trip.childId),
      ...missingActivationTrips.map((entry) => entry.trip.childId),
    ]);

    for (const entry of missingActivationTrips) {
      const nextActivationAt = computeNextActivationAtForTrip({
        trip: entry.trip,
        timeZone: childTimeZones.get(entry.trip.childId) ?? TZ,
        nowMs,
      });
      await entry.doc.ref.set(
        {
          nextActivationAt,
          updatedAt: nowMs,
        },
        { merge: true },
      );
      if (
        nextActivationAt != null &&
        nextActivationAt <= nowMs + SAFE_ROUTE_SCHEDULE_WINDOW_MS
      ) {
        plannedTrips.push({
          ...entry.trip,
          nextActivationAt,
        });
      }
    }

    const dueTrips = plannedTrips
      .filter((trip) => {
        const nextActivationAt = trip.nextActivationAt;
        return (
          nextActivationAt != null &&
          nextActivationAt <= nowMs + SAFE_ROUTE_SCHEDULE_WINDOW_MS
        );
      })
      .sort((left, right) => (left.nextActivationAt ?? left.updatedAt) - (right.nextActivationAt ?? right.updatedAt));

    let activatedCount = 0;

    for (const trip of dueTrips) {
      if (await isChildBusyForScheduledActivation(trip.childId)) {
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
            nextActivationAt: computeNextActivationAtForTrip({
              trip: {
                status: "planned",
                scheduledStartAt: trip.scheduledStartAt ?? null,
                repeatWeekdays: trip.repeatWeekdays ?? [],
                lastScheduledActivationAt: nowMs,
              },
              timeZone: childTimeZones.get(trip.childId) ?? TZ,
              nowMs,
            }),
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
            nextActivationAt: null,
          },
          { merge: true }
        );
      }

      activatedCount++;
    }

    console.log(
      `[activateScheduledSafeRouteTrips] planned=${plannedSnap.size} missingNextActivation=${missingActivationSnap.size} due=${dueTrips.length} activated=${activatedCount}`
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
    const trackingWatchRef = db.collection(TRACKING_WATCH_COLLECTION).doc(childId);
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
        removals.push(
          trackingWatchRef.set(
            buildTrackingWatchStoppedUpdate({
              familyId: previousFamilyId,
              childUid: childId,
            }),
            { merge: true },
          ),
        );
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
      writes.push(
        trackingWatchRef.set(
          buildTrackingWatchHeartbeatUpdate({
            familyId: nextFamilyId,
            childUid: childId,
            heartbeatMs: nowMs,
            nowMs,
          }),
          { merge: true },
        ),
      );
    }

    await Promise.all(writes);
  }
);

export const monitorSafeRouteLiveLocation = onValueWritten(
  {
    ref: "live_locations/{childId}",
    region: RTDB_TRIGGER_REGION,
  },
  async (event) => {
    if (!event.data.after.exists()) return;

    const childId = String(event.params.childId ?? "");
    const snapshot = await findMonitorableTripSnapshotByChildId(childId);
    if (!snapshot?.childMonitorTrip || !snapshot.childMonitorContext) {
      return;
    }

    const trip = snapshot.childMonitorTrip;
    const context = snapshot.childMonitorContext;
    const liveLocation = parseLiveLocationRecord(childId, event.data.after.val());
    const previousTrusted =
      event.data.before.exists() && event.data.before.val()
        ? parseLiveLocationRecord(childId, event.data.before.val())
        : null;

    if (
      previousTrusted != null &&
      trip.status === "active" &&
      liveLocation.timestamp - previousTrusted.timestamp <
        context.minEvaluationIntervalMs &&
      haversineMeters(
        liveLocation.latitude,
        liveLocation.longitude,
        previousTrusted.latitude,
        previousTrusted.longitude,
      ) < context.minEvaluationDistanceMeters &&
      !isNearMonitorDecisionArea({
        liveLocation,
        context,
      })
    ) {
      return;
    }

    const matched = evaluateSafeRouteTripAcrossRoutes({
      trip,
      routes: context.routes,
      liveLocation,
      hazards: context.hazards,
    });
    const route = matched.route;
    const evaluation = matched.evaluation;

    const now = Date.now();
    const tripRef = db.collection("trips").doc(trip.id);
    const updates: Partial<TripRecord> = {};
    let shouldPersistTripState = false;

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
    const nextStationaryAnchorLatitude = stillAtSamePlace
      ? anchorLatitude
      : liveLocation.latitude;
    const nextStationaryAnchorLongitude = stillAtSamePlace
      ? anchorLongitude
      : liveLocation.longitude;
    const nextHasStationaryAlertActive = stillAtSamePlace
      ? trip.hasStationaryAlertActive === true
      : false;

    if (trip.status !== evaluation.nextStatus) {
      updates.status = evaluation.nextStatus;
      shouldPersistTripState = true;
    }
    if ((trip.reason ?? null) !== (evaluation.nextReason ?? null)) {
      updates.reason = evaluation.nextReason;
      shouldPersistTripState = true;
    }
    if (trip.consecutiveDeviationCount !== evaluation.nextDeviationCount) {
      updates.consecutiveDeviationCount = evaluation.nextDeviationCount;
      shouldPersistTripState = true;
    }
    if ((trip.currentRouteId ?? null) !== (evaluation.matchedRouteId ?? null)) {
      updates.currentRouteId = evaluation.matchedRouteId;
      shouldPersistTripState = true;
    }
    if (
      Math.abs(
        trip.currentDistanceFromRouteMeters - evaluation.distanceFromRouteMeters,
      ) >= context.minEvaluationDistanceMeters
    ) {
      updates.currentDistanceFromRouteMeters =
        evaluation.distanceFromRouteMeters;
      shouldPersistTripState = true;
    }
    if ((trip.hasLeftStartArea === true) !== hasLeftStartArea) {
      updates.hasLeftStartArea = hasLeftStartArea;
      shouldPersistTripState = true;
    }
    if ((trip.isNearStartArea === true) !== evaluation.isNearStartPoint) {
      updates.isNearStartArea = evaluation.isNearStartPoint;
      shouldPersistTripState = true;
    }
    if ((trip.stationaryAnchorLatitude ?? null) !== nextStationaryAnchorLatitude) {
      updates.stationaryAnchorLatitude = nextStationaryAnchorLatitude;
      shouldPersistTripState = true;
    }
    if (
      (trip.stationaryAnchorLongitude ?? null) !==
      nextStationaryAnchorLongitude
    ) {
      updates.stationaryAnchorLongitude = nextStationaryAnchorLongitude;
      shouldPersistTripState = true;
    }
    if ((trip.stationarySinceAt ?? null) !== stationarySinceAt) {
      updates.stationarySinceAt = stationarySinceAt;
      shouldPersistTripState = true;
    }
    if (
      (trip.hasStationaryAlertActive === true) !== nextHasStationaryAlertActive
    ) {
      updates.hasStationaryAlertActive = nextHasStationaryAlertActive;
      shouldPersistTripState = true;
    }

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
      stationaryAnchorLatitude: nextStationaryAnchorLatitude,
      stationaryAnchorLongitude: nextStationaryAnchorLongitude,
      stationarySinceAt,
      hasStationaryAlertActive: nextHasStationaryAlertActive,
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
      updates.updatedAt = now;
      updates.lastLocation = liveLocation;
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
        shouldPersistTripState = true;
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
        shouldPersistTripState = true;
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
        shouldPersistTripState = true;
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
        shouldPersistTripState = true;
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
        shouldPersistTripState = true;
      }
    }

    if (!evaluation.triggeredHazard && trip.lastDangerHazardId != null) {
      updates.lastDangerHazardId = null;
      shouldPersistTripState = true;
    }

    if (!shouldPersistTripState) {
      return;
    }

    updates.updatedAt = now;
    updates.lastLocation = liveLocation;
    await tripRef.set(updates, {merge: true});
  }
);
