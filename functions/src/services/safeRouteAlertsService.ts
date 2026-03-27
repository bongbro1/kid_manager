import { randomUUID } from "crypto";
import { db } from "../bootstrap";
import { createGlobalNotificationRecord } from "./globalNotifications";
import { t } from "../i18n";
import {
  RouteHazardRecord,
  SafeRouteRecord,
  TripRecord,
} from "../types";

export type SafeRouteAlertKind =
  | "deviated"
  | "dangerZone"
  | "backOnRoute"
  | "returnedToStart"
  | "stationary"
  | "arrived";

type LocalizedAlertMessage = {
  eventKey: string;
  title: string;
  body: string;
  status: string;
};

function toDistanceLabel(meters: number) {
  if (meters >= 1000) {
    return `${(meters / 1000).toFixed(1)} km`;
  }
  return `${Math.max(1, Math.round(meters))} m`;
}

function eventKeyForKind(kind: SafeRouteAlertKind) {
  switch (kind) {
    case "backOnRoute":
      return "tracking.safe_route_back_on_route.parent";
    case "dangerZone":
      return "tracking.safe_route_danger_zone.parent";
    case "arrived":
      return "tracking.safe_route_arrived.parent";
    case "returnedToStart":
      return "tracking.safe_route_returned_to_start.parent";
    case "stationary":
      return "tracking.safe_route_stationary.parent";
    case "deviated":
    default:
      return "tracking.safe_route_deviated.parent";
  }
}

function statusForKind(kind: SafeRouteAlertKind) {
  switch (kind) {
    case "backOnRoute":
      return "safe_route_back_on_route";
    case "dangerZone":
      return "safe_route_danger_zone";
    case "arrived":
      return "safe_route_arrived";
    case "returnedToStart":
      return "safe_route_returned_to_start";
    case "stationary":
      return "safe_route_stationary";
    case "deviated":
    default:
      return "safe_route_deviated";
  }
}

async function resolveUserLanguage(uid: string) {
  const userSnap = await db.doc(`users/${uid}`).get();
  const user = userSnap.exists ? (userSnap.data() as any) : {};
  return (user.lang ?? user.locale ?? "vi").toString().toLowerCase();
}

async function buildLocalizedAlertMessage(params: {
  toUid: string;
  childName: string;
  routeName: string;
  kind: SafeRouteAlertKind;
  distanceFromRouteMeters: number;
  hazard?: RouteHazardRecord | null;
  stationaryDurationMinutes?: number | null;
}): Promise<LocalizedAlertMessage> {
  const lang = await resolveUserLanguage(params.toUid);
  const eventKey = eventKeyForKind(params.kind);
  const titleParams = {
    childName: params.childName,
    routeName: params.routeName,
    hazardName: params.hazard?.name ?? "",
    distanceFromRoute: toDistanceLabel(params.distanceFromRouteMeters),
    stationaryDuration:
      params.stationaryDurationMinutes == null
        ? ""
        : `${params.stationaryDurationMinutes}`,
  };

  return {
    eventKey,
    status: statusForKind(params.kind),
    title: t(lang, `${eventKey}.title`, titleParams),
    body: t(lang, `${eventKey}.body`, titleParams),
  };
}

export async function createSafeRouteAlert(params: {
  trip: TripRecord;
  route: SafeRouteRecord;
  kind: SafeRouteAlertKind;
  childName: string;
  distanceFromRouteMeters: number;
  hazard?: RouteHazardRecord | null;
  stationaryDurationMinutes?: number | null;
}) {
  const id = randomUUID();
  const now = Date.now();

  const alertRecord = {
    id,
    tripId: params.trip.id,
    routeId: params.route.id,
    parentId: params.trip.parentId,
    childId: params.trip.childId,
    kind: params.kind,
    status: statusForKind(params.kind),
    childName: params.childName,
    routeName: params.route.name,
    hazardId: params.hazard?.id ?? null,
    hazardName: params.hazard?.name ?? null,
    distanceFromRouteMeters: params.distanceFromRouteMeters,
    stationaryDurationMinutes: params.stationaryDurationMinutes ?? null,
    createdAt: now,
  };

  await db.collection("alerts").doc(id).set(alertRecord, {merge: true});
  return alertRecord;
}

export async function sendSafeRouteAlertPush(params: {
  toUid: string;
  trip: TripRecord;
  route: SafeRouteRecord;
  childName: string;
  kind: SafeRouteAlertKind;
  distanceFromRouteMeters: number;
  hazard?: RouteHazardRecord | null;
  stationaryDurationMinutes?: number | null;
}) {
  const localized = await buildLocalizedAlertMessage({
    toUid: params.toUid,
    childName: params.childName,
    routeName: params.route.name,
    kind: params.kind,
    distanceFromRouteMeters: params.distanceFromRouteMeters,
    hazard: params.hazard,
    stationaryDurationMinutes: params.stationaryDurationMinutes,
  });

  await createGlobalNotificationRecord({
    receiverId: params.toUid,
    senderId: "system",
    type: "tracking",
    title: localized.title,
    body: localized.body,
    eventKey: localized.eventKey,
    data: {
      childUid: params.trip.childId,
      childName: params.childName,
      routeId: params.route.id,
      routeName: params.route.name,
      tripId: params.trip.id,
      kind: params.kind,
      status: localized.status,
      eventKey: localized.eventKey,
      hazardId: params.hazard?.id ?? "",
      hazardName: params.hazard?.name ?? "",
      distanceFromRouteMeters:
        params.distanceFromRouteMeters.toFixed(1),
      stationaryDurationMinutes:
        params.stationaryDurationMinutes?.toString() ?? "",
      title: localized.title,
      body: localized.body,
    },
  });
}
