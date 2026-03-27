import { HttpsError } from "firebase-functions/v2/https";
import { MAPBOX_ACCESS_TOKEN } from "../config";
import { mustNumber, mustString, validateLatLng } from "../helpers";

const MAPBOX_HOST = "api.mapbox.com";
const MAX_GEOCODE_LIMIT = 10;
const ALLOWED_GEOCODE_FEATURE_TYPES = new Set([
  "address",
  "street",
  "postcode",
  "neighborhood",
  "locality",
  "district",
  "place",
  "region",
  "country",
]);
const ALLOWED_MATCHING_PROFILES = new Set([
  "mapbox/driving",
  "mapbox/driving-traffic",
  "mapbox/walking",
  "mapbox/cycling",
]);

export type MapboxTracePointInput = {
  latitude: number;
  longitude: number;
  accuracy?: number | null;
  timestamp?: number | null;
};

export type MapboxTraceMatchResult = {
  routeCoordinates: Array<[number, number]>;
  snappedPoints: Array<{latitude: number; longitude: number}>;
  nullTracepoints: number;
  distanceMeters: number;
  durationSeconds: number;
};

export type MapboxPlaceCandidate = {
  id: string;
  name: string;
  fullAddress: string;
  latitude: number;
  longitude: number;
  featureType: string;
  relevance: number;
  matchConfidence: string | null;
};

type MapboxDirectionsRoute = {
  distance?: number;
  duration?: number;
  geometry?: {
    coordinates?: Array<[number, number]>;
  };
};

type MapboxTracepoint = {
  location?: [number, number];
};

export function readMapboxAccessToken(): string {
  const token = MAPBOX_ACCESS_TOKEN.value().trim();
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "Missing MAPBOX_ACCESS_TOKEN secret",
    );
  }
  return token;
}

async function fetchMapboxJson<T>(url: URL): Promise<T> {
  const response = await fetch(url);
  if (!response.ok) {
    const body = await response.text().catch(() => "");
    if (response.status === 401 || response.status === 403) {
      throw new HttpsError(
        "failed-precondition",
        "MAPBOX_ACCESS_TOKEN is invalid or does not have access",
        {status: response.status, body},
      );
    }
    throw new HttpsError(
      "internal",
      `Mapbox request failed with ${response.status}`,
      body,
    );
  }
  return (await response.json()) as T;
}

function parseTracePoint(raw: unknown, index: number): MapboxTracePointInput {
  if (!raw || typeof raw !== "object") {
    throw new HttpsError("invalid-argument", `points[${index}] is required`);
  }

  const record = raw as Record<string, unknown>;
  const latitude = mustNumber(
    record.latitude ?? record.lat,
    `points[${index}].latitude`,
  );
  const longitude = mustNumber(
    record.longitude ?? record.lng,
    `points[${index}].longitude`,
  );
  validateLatLng(latitude, longitude);

  const accuracyRaw = record.accuracy ?? record.acc;
  const accuracy =
    accuracyRaw == null ? null : mustNumber(accuracyRaw, `points[${index}].accuracy`);
  const timestampRaw = record.timestamp ?? null;
  const timestamp =
    timestampRaw == null ? null : mustNumber(timestampRaw, `points[${index}].timestamp`);

  return {
    latitude,
    longitude,
    accuracy,
    timestamp,
  };
}

function parseMatchingProfile(value: unknown): string {
  const profile = mustString(value ?? "mapbox/driving", "profile");
  if (!ALLOWED_MATCHING_PROFILES.has(profile)) {
    throw new HttpsError("invalid-argument", "Unsupported map matching profile");
  }
  return profile;
}

function buildMatchingRadiuses(points: MapboxTracePointInput[]): string {
  return points
    .map((point) => {
      const accuracy = point.accuracy;
      if (accuracy == null || !Number.isFinite(accuracy)) {
        return "20.0";
      }
      return Math.min(50, Math.max(10, accuracy)).toFixed(1);
    })
    .join(";");
}

function buildMatchingTimestamps(
  points: MapboxTracePointInput[],
): string | null {
  if (points.some((point) => point.timestamp == null)) {
    return null;
  }

  const seconds: number[] = [];
  let previousSecond = -1;
  for (const point of points) {
    let second = Math.floor((point.timestamp ?? 0) / 1000);
    if (second <= previousSecond) {
      second = previousSecond + 1;
    }
    seconds.push(second);
    previousSecond = second;
  }

  return seconds.join(";");
}

function parseOptionalString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized ? normalized : null;
}

function parseFeatureTypes(value: unknown): string[] {
  if (!Array.isArray(value) || value.length === 0) {
    return Array.from(ALLOWED_GEOCODE_FEATURE_TYPES);
  }

  const normalized = value
    .map((item) => String(item ?? "").trim().toLowerCase())
    .filter((item) => item.length > 0)
    .filter((item, index, list) => list.indexOf(item) === index)
    .filter((item) => ALLOWED_GEOCODE_FEATURE_TYPES.has(item));

  if (normalized.length === 0) {
    throw new HttpsError("invalid-argument", "No valid feature types");
  }

  return normalized;
}

type RoutableCoordinate = {
  latitude: number;
  longitude: number;
};

function extractRoutablePoint(coordinates: Record<string, unknown>): RoutableCoordinate | null {
  const routablePointsRaw = coordinates.routable_points;
  if (!Array.isArray(routablePointsRaw) || routablePointsRaw.length === 0) {
    return null;
  }

  const first = routablePointsRaw[0];
  if (!first || typeof first !== "object") {
    return null;
  }

  const record = first as Record<string, unknown>;
  const latitude =
    typeof record.latitude === "number" ? record.latitude : Number(record.latitude);
  const longitude =
    typeof record.longitude === "number"
      ? record.longitude
      : Number(record.longitude);

  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
    return null;
  }

  return {latitude, longitude};
}

function toPlaceCandidate(raw: Record<string, unknown>): MapboxPlaceCandidate | null {
  const propertiesRaw = raw.properties;
  const properties =
    propertiesRaw && typeof propertiesRaw === "object"
      ? (propertiesRaw as Record<string, unknown>)
      : {};

  const geometryRaw = raw.geometry;
  const geometry =
    geometryRaw && typeof geometryRaw === "object"
      ? (geometryRaw as Record<string, unknown>)
      : {};

  let longitude: number | null = null;
  let latitude: number | null = null;

  const geometryCoordinates = geometry.coordinates;
  if (Array.isArray(geometryCoordinates) && geometryCoordinates.length >= 2) {
    longitude = Number(geometryCoordinates[0]);
    latitude = Number(geometryCoordinates[1]);
  }

  const propertiesCoordinatesRaw = properties.coordinates;
  if (propertiesCoordinatesRaw && typeof propertiesCoordinatesRaw === "object") {
    const propertiesCoordinates = propertiesCoordinatesRaw as Record<string, unknown>;
    const routable = extractRoutablePoint(propertiesCoordinates);
    if (routable != null) {
      longitude = routable.longitude;
      latitude = routable.latitude;
    } else {
      if (longitude == null) {
        longitude = Number(propertiesCoordinates.longitude);
      }
      if (latitude == null) {
        latitude = Number(propertiesCoordinates.latitude);
      }
    }
  }

  if (
    latitude == null ||
    longitude == null ||
    !Number.isFinite(latitude) ||
    !Number.isFinite(longitude)
  ) {
    return null;
  }

  const resolvedLatitude = latitude;
  const resolvedLongitude = longitude;

  const rawName =
    properties.name_preferred ??
    properties.name ??
    raw.name ??
    raw.text ??
    "";
  const name = String(rawName ?? "").trim();

  const explicitFullAddress = parseOptionalString(properties.full_address);
  const placeFormatted = parseOptionalString(properties.place_formatted);
  const fullAddress = explicitFullAddress ||
    (name && placeFormatted && placeFormatted !== name
      ? `${name}, ${placeFormatted}`
      : name || placeFormatted || "");

  const relevance =
    typeof raw.relevance === "number"
      ? raw.relevance
      : Number(properties.relevance ?? 0);

  let matchConfidence: string | null = null;
  const matchCodeRaw = properties.match_code;
  if (matchCodeRaw && typeof matchCodeRaw === "object") {
    matchConfidence = parseOptionalString(
      (matchCodeRaw as Record<string, unknown>).confidence,
    )?.toLowerCase() ?? null;
  }

  return {
    id:
      parseOptionalString(properties.mapbox_id) ??
      parseOptionalString(raw.id) ??
      `${resolvedLatitude},${resolvedLongitude}`,
    name,
    fullAddress,
    latitude: resolvedLatitude,
    longitude: resolvedLongitude,
    featureType:
      parseOptionalString(properties.feature_type)?.toLowerCase() ?? "",
    relevance: Number.isFinite(relevance) ? relevance : 0,
    matchConfidence,
  };
}

export async function fetchMapboxTraceMatch(params: {
  points: unknown[];
  profile: string;
  tidy: boolean;
}): Promise<MapboxTraceMatchResult> {
  const normalizedPoints = params.points.map((point, index) =>
    parseTracePoint(point, index),
  );
  const {profile, tidy} = params;
  if (normalizedPoints.length < 2) {
    throw new HttpsError(
      "invalid-argument",
      "At least two points are required for map matching",
    );
  }
  if (normalizedPoints.length > 100) {
    throw new HttpsError(
      "invalid-argument",
      "Map matching supports up to 100 points per request",
    );
  }

  const token = readMapboxAccessToken();
  const coords = normalizedPoints
    .map((point) => `${point.longitude},${point.latitude}`)
    .join(";");

  const url = new URL(`https://${MAPBOX_HOST}/matching/v5/${profile}/${coords}.json`);
  url.searchParams.set("access_token", token);
  url.searchParams.set("geometries", "geojson");
  url.searchParams.set("overview", "full");
  url.searchParams.set("steps", "false");
  url.searchParams.set("tidy", tidy ? "true" : "false");
  url.searchParams.set("radiuses", buildMatchingRadiuses(normalizedPoints));

  const timestamps = buildMatchingTimestamps(normalizedPoints);
  if (timestamps) {
    url.searchParams.set("timestamps", timestamps);
  }

  const payload = await fetchMapboxJson<{
    code?: string;
    message?: string;
    matchings?: MapboxDirectionsRoute[];
    tracepoints?: Array<MapboxTracepoint | null>;
  }>(url);

  if (payload.code !== "Ok") {
    throw new HttpsError(
      "internal",
      payload.message || "Mapbox map matching failed",
      payload.code,
    );
  }

  const routeCoordinates: Array<[number, number]> = [];
  let distanceMeters = 0;
  let durationSeconds = 0;

  for (const matching of payload.matchings ?? []) {
    distanceMeters += Number(matching.distance ?? 0);
    durationSeconds += Number(matching.duration ?? 0);

    const coordinates = matching.geometry?.coordinates ?? [];
    for (const coordinate of coordinates) {
      const point: [number, number] = [
        Number(coordinate[0]),
        Number(coordinate[1]),
      ];
      if (
        routeCoordinates.length > 0 &&
        routeCoordinates[routeCoordinates.length - 1][0] === point[0] &&
        routeCoordinates[routeCoordinates.length - 1][1] === point[1]
      ) {
        continue;
      }
      routeCoordinates.push(point);
    }
  }

  const tracepoints = payload.tracepoints ?? [];
  const snappedPoints = normalizedPoints.map((point, index) => {
    const tracepoint = tracepoints[index];
    const location = tracepoint?.location;
    if (Array.isArray(location) && location.length >= 2) {
      return {
        latitude: Number(location[1]),
        longitude: Number(location[0]),
      };
    }
    return {
      latitude: point.latitude,
      longitude: point.longitude,
    };
  });

  const nullTracepoints = tracepoints.filter((item) => item == null).length;

  return {
    routeCoordinates,
    snappedPoints,
    nullTracepoints,
    distanceMeters,
    durationSeconds,
  };
}

export async function fetchMapboxForwardGeocode(params: {
  query: string;
  limit: number;
  language: string;
  country?: string | null;
  bbox?: string | null;
  proximityLatitude?: number | null;
  proximityLongitude?: number | null;
  featureTypes?: string[];
}): Promise<MapboxPlaceCandidate[]> {
  const token = readMapboxAccessToken();
  const url = new URL(`https://${MAPBOX_HOST}/search/geocode/v6/forward`);
  url.searchParams.set("access_token", token);
  url.searchParams.set("q", params.query);
  url.searchParams.set("autocomplete", "true");
  url.searchParams.set("format", "geojson");
  url.searchParams.set("limit", String(Math.min(params.limit, MAX_GEOCODE_LIMIT)));
  url.searchParams.set("language", params.language);
  url.searchParams.set("types", (params.featureTypes ?? Array.from(ALLOWED_GEOCODE_FEATURE_TYPES)).join(","));
  url.searchParams.set("routing", "true");
  url.searchParams.set("worldview", "us");

  const country = parseOptionalString(params.country);
  if (country) {
    url.searchParams.set("country", country.toUpperCase());
  }
  const bbox = parseOptionalString(params.bbox);
  if (bbox) {
    url.searchParams.set("bbox", bbox);
  }
  if (params.proximityLatitude != null && params.proximityLongitude != null) {
    validateLatLng(params.proximityLatitude, params.proximityLongitude);
    url.searchParams.set(
      "proximity",
      `${params.proximityLongitude},${params.proximityLatitude}`,
    );
  }

  const payload = await fetchMapboxJson<{features?: unknown[]}>(url);
  const features = Array.isArray(payload.features) ? payload.features : [];

  return features
    .filter((item): item is Record<string, unknown> => !!item && typeof item === "object")
    .map((feature) => toPlaceCandidate(feature))
    .filter((candidate): candidate is MapboxPlaceCandidate => candidate != null);
}

export function sanitizeGeocodeLimit(value: unknown, fallback = 8): number {
  const parsed =
    typeof value === "number" ? value : Number.parseInt(String(value ?? ""), 10);
  if (!Number.isFinite(parsed)) {
    return fallback;
  }
  return Math.max(1, Math.min(MAX_GEOCODE_LIMIT, parsed));
}

export function sanitizeFeatureTypes(value: unknown): string[] {
  return parseFeatureTypes(value);
}

export function sanitizeMatchingProfile(value: unknown): string {
  return parseMatchingProfile(value);
}
