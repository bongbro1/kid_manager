import { db } from "../bootstrap";
import { MAPBOX_ACCESS_TOKEN } from "../config";
import { HttpsError } from "firebase-functions/v2/https";
import {
  RoutePointRecord,
  SafeRouteRecord,
  SafeRouteTravelMode,
} from "../types";
import { listRouteRelevantHazards } from "./safeRouteZonesService";

const DEFAULT_CORRIDOR_WIDTH_METERS = 50;
const MAX_SUGGESTED_ROUTES = 3;

type DirectionsRoute = {
  distance?: number;
  duration?: number;
  geometry?: {
    coordinates?: Array<[number, number]>;
  };
};

function toRoutePoint(
  latitude: number,
  longitude: number,
  sequence: number
): RoutePointRecord {
  return {
    latitude,
    longitude,
    sequence,
  };
}

function toMapboxProfile(travelMode: SafeRouteTravelMode) {
  switch (travelMode) {
    case "walking":
      return "walking";
    case "motorbike":
    case "pickup":
    case "otherVehicle":
      return "driving";
  }
}

function toTravelModeLabel(travelMode: SafeRouteTravelMode) {
  switch (travelMode) {
    case "walking":
      return "Đi bộ";
    case "motorbike":
      return "Xe máy";
    case "pickup":
      return "Đón con";
    case "otherVehicle":
      return "Phương tiên khác";
  }
}

function createRouteRecord(params: {
  id: string;
  childId: string;
  parentId: string;
  name: string;
  points: RoutePointRecord[];
  distanceMeters: number;
  durationSeconds: number;
  travelMode: SafeRouteTravelMode;
}) {
  const now = Date.now();
  const points = params.points;

  return {
    id: params.id,
    childId: params.childId,
    parentId: params.parentId,
    name: params.name,
    startPoint: points[0],
    endPoint: points[points.length - 1],
    points,
    hazards: [] as SafeRouteRecord["hazards"],
    corridorWidthMeters: DEFAULT_CORRIDOR_WIDTH_METERS,
    distanceMeters: params.distanceMeters,
    durationSeconds: params.durationSeconds,
    travelMode: params.travelMode,
    createdAt: now,
    updatedAt: now,
    profile: toMapboxProfile(params.travelMode),
  } satisfies SafeRouteRecord;
}

async function fetchDirections(
  start: RoutePointRecord,
  end: RoutePointRecord,
  travelMode: SafeRouteTravelMode
) {
  const token = MAPBOX_ACCESS_TOKEN.value();
  if (!token) {
    throw new HttpsError("failed-precondition", "Missing MAPBOX_ACCESS_TOKEN secret");
  }

  const profile = toMapboxProfile(travelMode);
  const url = new URL(
    `https://api.mapbox.com/directions/v5/mapbox/${profile}/` +
      `${start.longitude},${start.latitude};${end.longitude},${end.latitude}`
  );
  url.searchParams.set("alternatives", "true");
  url.searchParams.set("geometries", "geojson");
  url.searchParams.set("overview", "full");
  url.searchParams.set("steps", "false");
  url.searchParams.set("access_token", token);

  const response = await fetch(url);
  if (!response.ok) {
    const body = await response.text().catch(() => "");
    if (response.status === 401 || response.status === 403) {
      throw new HttpsError(
        "failed-precondition",
        "MAPBOX_ACCESS_TOKEN is invalid or missing Directions access",
        {
          status: response.status,
          body,
        }
      );
    }
    throw new HttpsError(
      "internal",
      `Mapbox Directions failed with ${response.status}`,
      body
    );
  }

  const payload = (await response.json()) as {
    routes?: DirectionsRoute[];
  };
  return payload.routes ?? [];
}

export async function buildSuggestedSafeRoutes(params: {
  childId: string;
  parentId: string;
  start: RoutePointRecord;
  end: RoutePointRecord;
  travelMode: SafeRouteTravelMode;
}) {
  const routes = await fetchDirections(params.start, params.end, params.travelMode);
  if (!routes.length) return [] as SafeRouteRecord[];

  const builtRoutes: SafeRouteRecord[] = [];
  const modeLabel = toTravelModeLabel(params.travelMode);

  for (let index = 0; index < routes.length && index < MAX_SUGGESTED_ROUTES; index += 1) {
    const route = routes[index];
    const coordinates = route.geometry?.coordinates ?? [];
    if (coordinates.length < 2) continue;

    const points = coordinates.map((coordinate, sequence) =>
      toRoutePoint(coordinate[1], coordinate[0], sequence)
    );

    const routeRef = db.collection("routes").doc();
    const routeRecord = createRouteRecord({
      id: routeRef.id,
      childId: params.childId,
      parentId: params.parentId,
      name: `${modeLabel} Tuyến an toàn ${index + 1}`,
      points,
      distanceMeters: Number(route.distance ?? 0),
      durationSeconds: Number(route.duration ?? 0),
      travelMode: params.travelMode,
    });
    const hazards = await listRouteRelevantHazards(
      params.childId,
      routeRecord.points,
      routeRecord.corridorWidthMeters
    );
    const fullRoute = {
      ...routeRecord,
      hazards,
    } satisfies SafeRouteRecord;

    await routeRef.set(fullRoute, {merge: true});
    builtRoutes.push(fullRoute);
  }

  return builtRoutes;
}
