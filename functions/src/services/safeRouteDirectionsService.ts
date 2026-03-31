import { randomUUID } from "crypto";
import { db } from "../bootstrap";
import { HttpsError } from "firebase-functions/v2/https";
import {
  RoutePointRecord,
  SafeRouteRecord,
  SafeRouteTravelMode,
} from "../types";
import { readMapboxAccessToken } from "./mapboxGateway";
import { listRouteRelevantHazards } from "./safeRouteZonesService";

const DEFAULT_CORRIDOR_WIDTH_METERS = 50;
const MAX_SUGGESTED_ROUTES = 3;
export const PREVIEW_SAFE_ROUTE_ID_PREFIX = "preview_route_";

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

function normalizeRouteName(name: string | null | undefined, fallback: string) {
  const trimmed = typeof name === "string" ? name.trim() : "";
  if (!trimmed) {
    return fallback;
  }

  return trimmed.slice(0, 120);
}

function normalizeRoutePoints(points: RoutePointRecord[]) {
  return [...points]
    .map((point, sequence) => ({
      latitude: Number(point.latitude),
      longitude: Number(point.longitude),
      sequence: Number.isInteger(point.sequence) ? point.sequence : sequence,
    }))
    .filter(
      (point) =>
        Number.isFinite(point.latitude) &&
        Number.isFinite(point.longitude) &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180,
    )
    .sort((left, right) => left.sequence - right.sequence)
    .map((point, sequence) => ({
      ...point,
      sequence,
    }));
}

function createPreviewRouteId() {
  return `${PREVIEW_SAFE_ROUTE_ID_PREFIX}${randomUUID()}`;
}

export function isPreviewSafeRouteId(routeId: string) {
  return routeId.startsWith(PREVIEW_SAFE_ROUTE_ID_PREFIX);
}

async function fetchDirections(
  start: RoutePointRecord,
  end: RoutePointRecord,
  travelMode: SafeRouteTravelMode
) {
  const token = readMapboxAccessToken();

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
  maxRoutes?: number;
}) {
  const routes = await fetchDirections(params.start, params.end, params.travelMode);
  if (!routes.length) return [] as SafeRouteRecord[];

  const builtRoutes: SafeRouteRecord[] = [];
  const modeLabel = toTravelModeLabel(params.travelMode);
  const routeLimit = Math.max(
    0,
    Math.min(MAX_SUGGESTED_ROUTES, params.maxRoutes ?? MAX_SUGGESTED_ROUTES)
  );

  for (let index = 0; index < routes.length && index < routeLimit; index += 1) {
    const route = routes[index];
    const coordinates = route.geometry?.coordinates ?? [];
    if (coordinates.length < 2) continue;

    const points = coordinates.map((coordinate, sequence) =>
      toRoutePoint(coordinate[1], coordinate[0], sequence)
    );

    const routeRecord = createRouteRecord({
      id: createPreviewRouteId(),
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

    builtRoutes.push(fullRoute);
  }

  return builtRoutes;
}

export async function persistSelectedSafeRoute(params: {
  route: SafeRouteRecord;
  childId: string;
  parentId: string;
}) {
  const normalizedPoints = normalizeRoutePoints(params.route.points);
  if (normalizedPoints.length < 2) {
    throw new HttpsError(
      "invalid-argument",
      "Safe route must contain at least two valid points",
    );
  }

  const routeRef = db.collection("routes").doc();
  const modeLabel = toTravelModeLabel(params.route.travelMode);
  const routeRecord = createRouteRecord({
    id: routeRef.id,
    childId: params.childId,
    parentId: params.parentId,
    name: normalizeRouteName(
      params.route.name,
      `${modeLabel} Tuyáº¿n an toÃ n`,
    ),
    points: normalizedPoints,
    distanceMeters: Math.max(0, Number(params.route.distanceMeters ?? 0)),
    durationSeconds: Math.max(0, Number(params.route.durationSeconds ?? 0)),
    travelMode: params.route.travelMode,
  });

  const hazards = await listRouteRelevantHazards(
    params.childId,
    routeRecord.points,
    routeRecord.corridorWidthMeters,
  );
  const fullRoute = {
    ...routeRecord,
    hazards,
  } satisfies SafeRouteRecord;

  await routeRef.set(fullRoute, { merge: true });
  return fullRoute;
}
