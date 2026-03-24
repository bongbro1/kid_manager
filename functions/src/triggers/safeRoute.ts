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
import { mustNumber, mustString } from "../helpers";
import {
  requireAdultManagerOfChild,
  requireParentGuardianOrChildSelf,
} from "../services/child";
import { buildSuggestedSafeRoutes } from "../services/safeRouteDirectionsService";
import {
  createSafeRouteAlert,
  sendSafeRouteAlertPush,
} from "../services/safeRouteAlertsService";
import {
  evaluateSafeRouteTripAcrossRoutes,
  parseLiveLocationRecord,
} from "../services/safeRouteMonitoringService";
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

const VISIBLE_TRIP_STATUSES: TripStatus[] = [
  "planned",
  "active",
  "temporarilyDeviated",
  "deviated",
];
const MONITORED_TRIP_STATUSES: TripStatus[] = [
  "active",
  "temporarilyDeviated",
  "deviated",
];
const SAFE_ROUTE_ALERT_COOLDOWN_MS = 3 * 60 * 1000;
const START_POINT_EXIT_RADIUS_METERS = 30;
const DESTINATION_ARRIVAL_RADIUS_METERS = 10;
const DESTINATION_ROUTE_PROXIMITY_METERS = 18;
const ALTERNATIVE_ROUTE_ENDPOINT_RADIUS_METERS = 120;
const STATIONARY_RADIUS_METERS = 18;
const STATIONARY_ALERT_DELAY_MS = 5 * 60 * 1000;
const RECENT_COMPLETED_TRIP_WINDOW_MS = 15 * 60 * 1000;
const SAFE_ROUTE_SCHEDULE = "every 1 minutes";

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

function zonedDateParts(ms: number) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    weekday: "short",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date(ms));

  const weekdayToken =
    parts.find((part) => part.type === "weekday")?.value ?? "Mon";
  const year = Number(parts.find((part) => part.type === "year")?.value ?? 1970);
  const month = Number(parts.find((part) => part.type === "month")?.value ?? 1);
  const day = Number(parts.find((part) => part.type === "day")?.value ?? 1);
  const hour = Number(parts.find((part) => part.type === "hour")?.value ?? 0);
  const minute = Number(
    parts.find((part) => part.type === "minute")?.value ?? 0
  );

  const weekday = (() => {
    switch (weekdayToken.slice(0, 3).toLowerCase()) {
      case "mon":
        return 1;
      case "tue":
        return 2;
      case "wed":
        return 3;
      case "thu":
        return 4;
      case "fri":
        return 5;
      case "sat":
        return 6;
      case "sun":
      default:
        return 7;
    }
  })();

  return {
    weekday,
    dayKey: `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(
      2,
      "0"
    )}`,
    minutesOfDay: hour * 60 + minute,
  };
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

function isTripScheduleDue(trip: TripRecord, nowMs: number) {
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

  const nowParts = zonedDateParts(nowMs);
  const scheduledParts = zonedDateParts(scheduledStartAt);

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
    const lastActivationParts = zonedDateParts(trip.lastScheduledActivationAt);
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

async function findVisibleTripByChildId(childId: string) {
  const snap = await db
    .collection("trips")
    .where("childId", "==", childId)
    .get();

  const trips = snap.docs
    .map((doc) => asTripRecord(doc))
    .filter((trip): trip is TripRecord => trip !== null)
    .filter((trip) => VISIBLE_TRIP_STATUSES.includes(trip.status))
    .sort((left, right) => right.updatedAt - left.updatedAt);

  return trips[0] ?? null;
}

async function findMonitorableTripByChildId(childId: string) {
  const snap = await db
    .collection("trips")
    .where("childId", "==", childId)
    .get();

  const trips = snap.docs
    .map((doc) => asTripRecord(doc))
    .filter((trip): trip is TripRecord => trip !== null)
    .filter((trip) => MONITORED_TRIP_STATUSES.includes(trip.status))
    .sort((left, right) => right.updatedAt - left.updatedAt);

  return trips[0] ?? null;
}

async function findLatestTripByChildId(childId: string) {
  const snap = await db
    .collection("trips")
    .where("childId", "==", childId)
    .get();

  const trips = snap.docs
    .map((doc) => asTripRecord(doc))
    .filter((trip): trip is TripRecord => trip !== null)
    .sort((left, right) => right.updatedAt - left.updatedAt);

  return trips[0] ?? null;
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
    const route = await loadRouteOrThrow(routeId);
    const access = await requireAdultManagerOfChild(requesterUid, route.childId);
    const ownerParentUid = access.ownerParentUid;

    if (route.parentId != null && route.parentId !== ownerParentUid) {
      throw new HttpsError(
        "permission-denied",
        "You cannot start a trip on this route"
      );
    }

    const tripRef = db.collection("trips").doc();
    const now = Date.now();
    const batch = db.batch();
    const scheduledStartAtRaw =
      request.data?.trip?.scheduledStartAt ?? request.data?.scheduledStartAt;
    const scheduledStartAt =
      scheduledStartAtRaw == null ? null : Number(scheduledStartAtRaw);
    const alternativeRouteIds = await validateAlternativeRoutes({
      parentUid: ownerParentUid,
      childId: route.childId,
      primaryRoute: route,
      candidateRouteIds: parseRouteIdList(
      request.data?.trip?.alternativeRouteIds ?? request.data?.alternativeRouteIds
      ),
    });
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

    const trip =
      requesterUid === childId
        ? await findMonitorableTripByChildId(childId)
        : await findVisibleTripByChildId(childId);
    if (trip != null) {
      return {
        ok: true,
        trip,
      };
    }

    const latestTrip = await findLatestTripByChildId(childId);
    const shouldExposeRecentCompleted =
      latestTrip != null &&
      latestTrip.status === "completed" &&
      Date.now() - latestTrip.updatedAt <= RECENT_COMPLETED_TRIP_WINDOW_MS;

    return {
      ok: true,
      trip: shouldExposeRecentCompleted ? latestTrip : null,
    };
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

    const dueTrips = plannedSnap.docs
      .map((doc) => asTripRecord(doc))
      .filter((trip): trip is TripRecord => trip !== null)
      .filter((trip) => isTripScheduleDue(trip, nowMs))
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

    if (!event.data.after.exists()) {
      await targetRef.remove();
      return;
    }

    const liveLocation = parseLiveLocationRecord(childId, event.data.after.val());
    await targetRef.set(liveLocation);
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
    const trip = await findMonitorableTripByChildId(childId);
    if (!trip) return;

    const routes = await loadRoutesForTrip(trip);
    const liveLocation = parseLiveLocationRecord(childId, event.data.after.val());
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

    if (arrivedAtDestination) {
      await createSafeRouteAlert({
        trip: {
          ...trip,
          status: "completed",
        },
        route,
        kind: "arrived",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      await sendSafeRouteAlertPush({
        toUid: trip.parentId,
        trip: {
          ...trip,
          status: "completed",
        },
        route,
        childName,
        kind: "arrived",
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

    if (
      evaluation.triggeredHazard &&
      ((trip.lastDangerAlertAt ?? 0) + SAFE_ROUTE_ALERT_COOLDOWN_MS <= now ||
        trip.lastDangerHazardId !== evaluation.triggeredHazard.id)
    ) {
      await createSafeRouteAlert({
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        kind: "dangerZone",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        hazard: evaluation.triggeredHazard,
      });
      await sendSafeRouteAlertPush({
        toUid: trip.parentId,
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        childName,
        kind: "dangerZone",
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        hazard: evaluation.triggeredHazard,
      });
      updates.lastDangerAlertAt = now;
      updates.lastDangerHazardId = evaluation.triggeredHazard.id;
    }

    if (
      returnedToStart &&
      (trip.lastReturnedToStartAlertAt ?? 0) + SAFE_ROUTE_ALERT_COOLDOWN_MS <=
        now
    ) {
      await createSafeRouteAlert({
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        kind: "returnedToStart",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      await sendSafeRouteAlertPush({
        toUid: trip.parentId,
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        childName,
        kind: "returnedToStart",
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      updates.lastReturnedToStartAlertAt = now;
    } else if (
      returnedToRoute &&
      (trip.lastBackOnRouteAlertAt ?? 0) + SAFE_ROUTE_ALERT_COOLDOWN_MS <= now
    ) {
      await createSafeRouteAlert({
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        kind: "backOnRoute",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      await sendSafeRouteAlertPush({
        toUid: trip.parentId,
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        childName,
        kind: "backOnRoute",
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      updates.lastBackOnRouteAlertAt = now;
    }

    if (
      !evaluation.triggeredHazard &&
      stillAtSamePlace &&
      stationaryDurationMs >= STATIONARY_ALERT_DELAY_MS &&
      trip.hasStationaryAlertActive !== true
    ) {
      await createSafeRouteAlert({
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        kind: "stationary",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        stationaryDurationMinutes,
      });
      await sendSafeRouteAlertPush({
        toUid: trip.parentId,
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        childName,
        kind: "stationary",
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
        stationaryDurationMinutes,
      });
      updates.lastStationaryAlertAt = now;
      updates.hasStationaryAlertActive = true;
    }

    if (
      evaluation.nextStatus === "deviated" &&
      (trip.lastDeviationAlertAt ?? 0) + SAFE_ROUTE_ALERT_COOLDOWN_MS <= now
    ) {
      await createSafeRouteAlert({
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        kind: "deviated",
        childName,
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      await sendSafeRouteAlertPush({
        toUid: trip.parentId,
        trip: {
          ...trip,
          status: evaluation.nextStatus,
        },
        route,
        childName,
        kind: "deviated",
        distanceFromRouteMeters: evaluation.distanceFromRouteMeters,
      });
      updates.lastDeviationAlertAt = now;
    }

    if (!evaluation.triggeredHazard) {
      updates.lastDangerHazardId = null;
    }

    await tripRef.set(updates, {merge: true});
  }
);
