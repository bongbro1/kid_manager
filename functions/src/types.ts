export type TripStatus =
  | "planned"
  | "active"
  | "temporarilyDeviated"
  | "deviated"
  | "completed"
  | "cancelled";

export type ZoneRiskLevel = "low" | "medium" | "high";

export type SafeRouteTravelMode =
  | "walking"
  | "motorbike"
  | "pickup"
  | "otherVehicle";

export type RoutePointRecord = {
  latitude: number;
  longitude: number;
  sequence: number;
};

export type RouteHazardRecord = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  riskLevel: ZoneRiskLevel;
  sourceZoneId: string;
};

export type SafeRouteRecord = {
  id: string;
  childId: string;
  parentId: string | null;
  name: string;
  startPoint: RoutePointRecord;
  endPoint: RoutePointRecord;
  points: RoutePointRecord[];
  hazards: RouteHazardRecord[];
  corridorWidthMeters: number;
  distanceMeters: number;
  durationSeconds: number;
  travelMode: SafeRouteTravelMode;
  createdAt: number;
  updatedAt: number;
  profile?: string;
};

export type LiveLocationRecord = {
  childId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  speed: number;
  heading: number;
  batteryLevel: number | null;
  isCharging: boolean | null;
  isMock: boolean;
  timestamp: number;
  motion?: string;
  transport?: string;
};

export type TripRecord = {
  id: string;
  childId: string;
  parentId: string;
  routeId: string;
  alternativeRouteIds?: string[];
  currentRouteId?: string | null;
  routeName?: string | null;
  status: TripStatus;
  reason: string | null;
  consecutiveDeviationCount: number;
  currentDistanceFromRouteMeters: number;
  startedAt: number;
  updatedAt: number;
  scheduledStartAt?: number | null;
  nextActivationAt?: number | null;
  repeatWeekdays?: number[];
  lastScheduledActivationAt?: number | null;
  lastLocation: LiveLocationRecord | null;
  lastDeviationAlertAt?: number | null;
  lastDangerAlertAt?: number | null;
  lastDangerHazardId?: string | null;
  lastBackOnRouteAlertAt?: number | null;
  lastReturnedToStartAlertAt?: number | null;
  lastStationaryAlertAt?: number | null;
  hasLeftStartArea?: boolean | null;
  isNearStartArea?: boolean | null;
  stationaryAnchorLatitude?: number | null;
  stationaryAnchorLongitude?: number | null;
  stationarySinceAt?: number | null;
  hasStationaryAlertActive?: boolean | null;
};

export type SafeRouteMonitorContextRecord = {
  tripId: string;
  routes: SafeRouteRecord[];
  hazards: RouteHazardRecord[];
  builtAt: number;
  minEvaluationIntervalMs: number;
  minEvaluationDistanceMeters: number;
};

export type SafeRouteCurrentTripSnapshotRecord = {
  childId: string;
  adultCurrentTrip: TripRecord | null;
  adultRecentCompletedTrip: TripRecord | null;
  adultCurrentTripVisibleUntil: number | null;
  childMonitorTrip: TripRecord | null;
  childMonitorContext?: SafeRouteMonitorContextRecord | null;
  updatedAt: number;
};
