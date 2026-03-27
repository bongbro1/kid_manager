import { HttpsError, onCall } from "firebase-functions/v2/https";
import { MAPBOX_ACCESS_TOKEN, REGION } from "../config";
import { mustString } from "../helpers";
import {
  fetchMapboxForwardGeocode,
  fetchMapboxTraceMatch,
  sanitizeFeatureTypes,
  sanitizeGeocodeLimit,
  sanitizeMatchingProfile,
} from "../services/mapboxGateway";

function parseOptionalFiniteNumber(
  value: unknown,
  fieldName: string,
): number | null {
  if (value == null) {
    return null;
  }

  const parsed = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(parsed)) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} must be a finite number`,
    );
  }

  return parsed;
}

export const searchMapPlaces = onCall(
  {
    region: REGION,
    secrets: [MAPBOX_ACCESS_TOKEN],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const query = mustString(request.data?.query, "query");
    const language =
      typeof request.data?.language === "string" && request.data.language.trim()
        ? request.data.language.trim()
        : "vi,en";

    const results = await fetchMapboxForwardGeocode({
      query,
      limit: sanitizeGeocodeLimit(request.data?.limit, 8),
      language,
      country:
        typeof request.data?.country === "string"
          ? request.data.country.trim()
          : null,
      bbox:
        typeof request.data?.bbox === "string"
          ? request.data.bbox.trim()
          : null,
      proximityLatitude: parseOptionalFiniteNumber(
        request.data?.proximityLatitude,
        "proximityLatitude",
      ),
      proximityLongitude: parseOptionalFiniteNumber(
        request.data?.proximityLongitude,
        "proximityLongitude",
      ),
      featureTypes: sanitizeFeatureTypes(request.data?.featureTypes),
    });

    return {
      ok: true,
      results,
    };
  },
);

export const matchMapTrace = onCall(
  {
    region: REGION,
    secrets: [MAPBOX_ACCESS_TOKEN],
  },
  async (request) => {
    if (!request.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    if (!Array.isArray(request.data?.points)) {
      throw new HttpsError("invalid-argument", "points must be an array");
    }

    const result = await fetchMapboxTraceMatch({
      points: request.data.points,
      profile: sanitizeMatchingProfile(request.data?.profile),
      tidy: request.data?.tidy !== false,
    });

    return {
      ok: true,
      ...result,
    };
  },
);
