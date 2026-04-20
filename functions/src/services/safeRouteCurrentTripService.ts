import {
  RouteHazardRecord,
  RoutePointRecord,
  SafeRouteCurrentTripSnapshotRecord,
  SafeRouteMonitorContextRecord,
  SafeRouteRecord,
  TripRecord,
  TripStatus,
} from "../types";

export type SafeRouteTripAudience = "child_monitor" | "adult_manager";

export const SAFE_ROUTE_CURRENT_TRIPS_COLLECTION = "safe_route_current_trips";
export const MONITORED_TRIP_STATUSES: TripStatus[] = [
  "active",
  "temporarilyDeviated",
  "deviated",
];
export const VISIBLE_TRIP_STATUSES: TripStatus[] = [
  "planned",
  "active",
  "temporarilyDeviated",
  "deviated",
];
export const RECENT_COMPLETED_TRIP_WINDOW_MS = 15 * 60 * 1000;

export function isTripVisibleToAudience(params: {
  trip: TripRecord;
  audience: SafeRouteTripAudience;
  nowMs: number;
}) {
  const { trip, audience, nowMs } = params;
  if (audience === "child_monitor") {
    return MONITORED_TRIP_STATUSES.includes(trip.status);
  }

  if (VISIBLE_TRIP_STATUSES.includes(trip.status)) {
    return true;
  }

  return (
    trip.status === "completed" &&
    nowMs - trip.updatedAt <= RECENT_COMPLETED_TRIP_WINDOW_MS
  );
}

export function selectCurrentTripForAudience(params: {
  trips: TripRecord[];
  audience: SafeRouteTripAudience;
  nowMs: number;
}) {
  const visibleTrips = params.trips
    .filter((trip) =>
      isTripVisibleToAudience({
        trip,
        audience: params.audience,
        nowMs: params.nowMs,
      })
    )
    .sort((left, right) => right.updatedAt - left.updatedAt);

  return visibleTrips[0] ?? null;
}

export function buildSafeRouteCurrentTripSnapshot(params: {
  childId: string;
  trips: TripRecord[];
  childMonitorContext?: SafeRouteMonitorContextRecord | null;
  nowMs: number;
}): SafeRouteCurrentTripSnapshotRecord {
  const adultCurrentTrip =
    params.trips
      .filter((trip) => VISIBLE_TRIP_STATUSES.includes(trip.status))
      .sort((left, right) => right.updatedAt - left.updatedAt)[0] ?? null;
  const adultRecentCompletedTrip =
    params.trips
      .filter((trip) => trip.status === "completed")
      .sort((left, right) => right.updatedAt - left.updatedAt)[0] ?? null;
  const childMonitorTrip = selectCurrentTripForAudience({
    trips: params.trips,
    audience: "child_monitor",
    nowMs: params.nowMs,
  });

  return {
    childId: params.childId,
    adultCurrentTrip,
    adultRecentCompletedTrip,
    adultCurrentTripVisibleUntil:
      adultRecentCompletedTrip == null
        ? null
        : adultRecentCompletedTrip.updatedAt + RECENT_COMPLETED_TRIP_WINDOW_MS,
    childMonitorTrip,
    childMonitorContext:
      childMonitorTrip != null &&
          params.childMonitorContext != null &&
          params.childMonitorContext.tripId === childMonitorTrip.id
        ? params.childMonitorContext
        : null,
    updatedAt: params.nowMs,
  };
}

function asTripRecord(value: unknown): TripRecord | null {
  if (!value || typeof value !== "object") {
    return null;
  }
  return value as TripRecord;
}

function asRoutePointRecord(value: unknown): RoutePointRecord | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const data = value as Record<string, unknown>;
  const latitude = Number(data.latitude ?? 0);
  const longitude = Number(data.longitude ?? 0);
  const sequence = Number(data.sequence ?? 0);
  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    !Number.isFinite(sequence)
  ) {
    return null;
  }

  return {
    latitude,
    longitude,
    sequence: Math.trunc(sequence),
  };
}

function asRouteHazardRecord(value: unknown): RouteHazardRecord | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const data = value as Record<string, unknown>;
  const id = typeof data.id === "string" ? data.id.trim() : "";
  if (!id) {
    return null;
  }

  const latitude = Number(data.latitude ?? 0);
  const longitude = Number(data.longitude ?? 0);
  const radiusMeters = Number(data.radiusMeters ?? 0);
  if (
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude) ||
    !Number.isFinite(radiusMeters)
  ) {
    return null;
  }

  return {
    id,
    name: typeof data.name === "string" ? data.name : "Danger zone",
    latitude,
    longitude,
    radiusMeters,
    riskLevel:
      data.riskLevel === "high" || data.riskLevel === "medium"
        ? data.riskLevel
        : "low",
    sourceZoneId:
      typeof data.sourceZoneId === "string" && data.sourceZoneId.trim()
        ? data.sourceZoneId.trim()
        : id,
  };
}

function asSafeRouteRecord(value: unknown): SafeRouteRecord | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const data = value as Record<string, unknown>;
  const id = typeof data.id === "string" ? data.id.trim() : "";
  const childId = typeof data.childId === "string" ? data.childId.trim() : "";
  if (!id || !childId) {
    return null;
  }

  const startPoint = asRoutePointRecord(data.startPoint);
  const endPoint = asRoutePointRecord(data.endPoint);
  const points = Array.isArray(data.points)
    ? data.points
        .map((point) => asRoutePointRecord(point))
        .filter((point): point is RoutePointRecord => point != null)
    : [];
  if (startPoint == null || endPoint == null || points.length < 2) {
    return null;
  }

  return {
    id,
    childId,
    parentId:
      typeof data.parentId === "string" && data.parentId.trim()
        ? data.parentId.trim()
        : null,
    name: typeof data.name === "string" ? data.name : "Safe route",
    startPoint,
    endPoint,
    points,
    hazards: Array.isArray(data.hazards)
      ? data.hazards
          .map((hazard) => asRouteHazardRecord(hazard))
          .filter((hazard): hazard is RouteHazardRecord => hazard != null)
      : [],
    corridorWidthMeters: Number(data.corridorWidthMeters ?? 50),
    distanceMeters: Number(data.distanceMeters ?? 0),
    durationSeconds: Number(data.durationSeconds ?? 0),
    travelMode:
      data.travelMode === "motorbike" ||
          data.travelMode === "pickup" ||
          data.travelMode === "otherVehicle"
        ? data.travelMode
        : "walking",
    createdAt: Number(data.createdAt ?? 0),
    updatedAt: Number(data.updatedAt ?? 0),
    profile:
      typeof data.profile === "string" && data.profile.trim()
        ? data.profile.trim()
        : undefined,
  };
}

function asSafeRouteMonitorContextRecord(
  value: unknown,
): SafeRouteMonitorContextRecord | null {
  if (!value || typeof value !== "object") {
    return null;
  }

  const data = value as Record<string, unknown>;
  const tripId = typeof data.tripId === "string" ? data.tripId.trim() : "";
  if (!tripId) {
    return null;
  }

  const routes = Array.isArray(data.routes)
    ? data.routes
        .map((route) => asSafeRouteRecord(route))
        .filter((route): route is SafeRouteRecord => route != null)
    : [];
  const hazards = Array.isArray(data.hazards)
    ? data.hazards
        .map((hazard) => asRouteHazardRecord(hazard))
        .filter((hazard): hazard is RouteHazardRecord => hazard != null)
    : [];
  if (routes.length === 0) {
    return null;
  }

  return {
    tripId,
    routes,
    hazards,
    builtAt:
      typeof data.builtAt === "number" && Number.isFinite(data.builtAt)
        ? Math.trunc(data.builtAt)
        : 0,
    minEvaluationIntervalMs:
      typeof data.minEvaluationIntervalMs === "number" &&
          Number.isFinite(data.minEvaluationIntervalMs)
        ? Math.trunc(data.minEvaluationIntervalMs)
        : 5000,
    minEvaluationDistanceMeters:
      typeof data.minEvaluationDistanceMeters === "number" &&
          Number.isFinite(data.minEvaluationDistanceMeters)
        ? Math.trunc(data.minEvaluationDistanceMeters)
        : 10,
  };
}

export function asSafeRouteCurrentTripSnapshotRecord(
  raw: unknown
): SafeRouteCurrentTripSnapshotRecord | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }

  const data = raw as Record<string, unknown>;
  const childId =
    typeof data.childId === "string" ? data.childId.trim() : "";
  if (!childId) {
    return null;
  }

  const updatedAt =
    typeof data.updatedAt === "number" && Number.isFinite(data.updatedAt)
      ? Math.trunc(data.updatedAt)
      : 0;

  return {
    childId,
    adultCurrentTrip: asTripRecord(data.adultCurrentTrip),
    adultRecentCompletedTrip: asTripRecord(data.adultRecentCompletedTrip),
    adultCurrentTripVisibleUntil:
      typeof data.adultCurrentTripVisibleUntil === "number" &&
      Number.isFinite(data.adultCurrentTripVisibleUntil)
        ? Math.trunc(data.adultCurrentTripVisibleUntil)
        : null,
    childMonitorTrip: asTripRecord(data.childMonitorTrip),
    childMonitorContext: asSafeRouteMonitorContextRecord(
      data.childMonitorContext,
    ),
    updatedAt,
  };
}

export function selectTripFromCurrentTripSnapshot(params: {
  snapshot: SafeRouteCurrentTripSnapshotRecord | null;
  audience: SafeRouteTripAudience;
  nowMs: number;
}) {
  const { snapshot, audience, nowMs } = params;
  if (!snapshot) {
    return null;
  }

  if (audience === "child_monitor") {
    return snapshot.childMonitorTrip;
  }

  const trip = snapshot.adultCurrentTrip;
  const recentCompletedTrip = snapshot.adultRecentCompletedTrip;
  if (
    recentCompletedTrip != null &&
    snapshot.adultCurrentTripVisibleUntil != null &&
    nowMs < snapshot.adultCurrentTripVisibleUntil &&
    (trip == null || recentCompletedTrip.updatedAt >= trip.updatedAt)
  ) {
    return recentCompletedTrip;
  }

  return trip;
}
