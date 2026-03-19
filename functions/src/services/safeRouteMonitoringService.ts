import {
  LiveLocationRecord,
  RouteHazardRecord,
  SafeRouteRecord,
  TripRecord,
  TripStatus,
} from "../types";
import {
  distanceLocationToRouteMeters,
  haversineMeters,
  pointInCircleMeters,
} from "../utils/safeRouteGeo";

export type SafeRouteTripEvaluation = {
  matchedRouteId: string;
  nextStatus: TripStatus;
  nextReason: string | null;
  nextDeviationCount: number;
  distanceFromRouteMeters: number;
  distanceFromStartMeters: number;
  distanceToDestinationMeters: number;
  isNearStartPoint: boolean;
  triggeredHazard: RouteHazardRecord | null;
};

const START_POINT_ENTER_RADIUS_METERS = 15;

export function parseLiveLocationRecord(
  childId: string,
  raw: any
): LiveLocationRecord {
  return {
    childId,
    latitude: Number(raw?.latitude ?? 0),
    longitude: Number(raw?.longitude ?? 0),
    accuracy: Number(raw?.accuracy ?? 0),
    speed: Number(raw?.speed ?? 0),
    heading: Number(raw?.heading ?? 0),
    batteryLevel:
      raw?.batteryLevel == null ? null : Number(raw?.batteryLevel ?? 0),
    isMock: raw?.isMock === true,
    timestamp: Number(raw?.timestamp ?? Date.now()),
    motion: typeof raw?.motion === "string" ? raw.motion : undefined,
    transport: typeof raw?.transport === "string" ? raw.transport : undefined,
  };
}

export function evaluateSafeRouteTrip(params: {
  trip: TripRecord;
  route: SafeRouteRecord;
  liveLocation: LiveLocationRecord;
  hazards: RouteHazardRecord[];
}) {
  const {trip, route, liveLocation, hazards} = params;
  const thresholdMeters = Math.max(50, route.corridorWidthMeters);
  const distanceFromRouteMeters = distanceLocationToRouteMeters(
    liveLocation,
    route.points
  );
  const distanceFromStartMeters = haversineMeters(
    liveLocation.latitude,
    liveLocation.longitude,
    route.startPoint.latitude,
    route.startPoint.longitude
  );
  const distanceToDestinationMeters = haversineMeters(
    liveLocation.latitude,
    liveLocation.longitude,
    route.endPoint.latitude,
    route.endPoint.longitude
  );
  const isNearStartPoint =
    distanceFromStartMeters <= START_POINT_ENTER_RADIUS_METERS;

  const deviatedThisTick = distanceFromRouteMeters > thresholdMeters;
  const nextDeviationCount = deviatedThisTick
    ? trip.consecutiveDeviationCount + 1
    : 0;

  let nextStatus: TripStatus = "active";
  let nextReason: string | null = null;

  if (deviatedThisTick && nextDeviationCount >= 3) {
    nextStatus = "deviated";
    nextReason = "Child moved outside safe route corridor";
  } else if (deviatedThisTick) {
    nextStatus = "temporarilyDeviated";
    nextReason = "Child is temporarily outside safe route corridor";
  }

  const triggeredHazard =
    hazards.find((hazard) =>
      pointInCircleMeters(
        liveLocation.latitude,
        liveLocation.longitude,
        hazard.latitude,
        hazard.longitude,
        hazard.radiusMeters
      )
    ) ?? null;

  return {
    matchedRouteId: route.id,
    nextStatus,
    nextReason,
    nextDeviationCount,
    distanceFromRouteMeters,
    distanceFromStartMeters,
    distanceToDestinationMeters,
    isNearStartPoint,
    triggeredHazard,
  } satisfies SafeRouteTripEvaluation;
}

export function evaluateSafeRouteTripAcrossRoutes(params: {
  trip: TripRecord;
  routes: SafeRouteRecord[];
  liveLocation: LiveLocationRecord;
  hazards: RouteHazardRecord[];
}) {
  const { routes, ...rest } = params;
  const candidates = routes.map((route) => ({
    route,
    evaluation: evaluateSafeRouteTrip({
      ...rest,
      route,
    }),
  }));

  candidates.sort(
    (left, right) =>
      left.evaluation.distanceFromRouteMeters -
      right.evaluation.distanceFromRouteMeters
  );

  return candidates[0];
}
