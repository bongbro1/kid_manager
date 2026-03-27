import {
  SafeRouteCurrentTripSnapshotRecord,
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
    updatedAt: params.nowMs,
  };
}

function asTripRecord(value: unknown): TripRecord | null {
  if (!value || typeof value !== "object") {
    return null;
  }
  return value as TripRecord;
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
