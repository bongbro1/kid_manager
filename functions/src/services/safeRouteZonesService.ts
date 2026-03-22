import { admin, db } from "../bootstrap";
import {
  RouteHazardRecord,
  RoutePointRecord,
  ZoneRiskLevel,
} from "../types";
import { distancePointToPolylineMeters } from "../utils/safeRouteGeo";

type RawZone = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  riskLevel: ZoneRiskLevel;
};

function asNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number.parseFloat(String(value ?? ""));
  return Number.isFinite(parsed) ? parsed : null;
}

function asRiskLevel(value: unknown): ZoneRiskLevel {
  const normalized = String(value ?? "").trim().toLowerCase();
  if (normalized === "high") return "high";
  if (normalized === "medium") return "medium";
  return "low";
}

function mapFirestoreZone(
  doc: FirebaseFirestore.QueryDocumentSnapshot
): RawZone | null {
  const data = doc.data() ?? {};
  const type = String(data.type ?? "").trim().toLowerCase();
  if (type && type !== "danger") return null;

  const latitude =
    asNumber(data.latitude) ??
    asNumber(data.lat);
  const longitude =
    asNumber(data.longitude) ??
    asNumber(data.lng);
  const radiusMeters =
    asNumber(data.radiusMeters) ??
    asNumber(data.radiusM);

  if (latitude == null || longitude == null || radiusMeters == null) {
    return null;
  }

  return {
    id: doc.id,
    name: String(data.name ?? "Danger zone"),
    latitude,
    longitude,
    radiusMeters,
    riskLevel: asRiskLevel(data.riskLevel),
  };
}

function mapRtdbZone(zoneId: string, data: any): RawZone | null {
  const type = String(data?.type ?? "").trim().toLowerCase();
  if (type && type !== "danger") return null;

  const latitude = asNumber(data?.latitude) ?? asNumber(data?.lat);
  const longitude = asNumber(data?.longitude) ?? asNumber(data?.lng);
  const radiusMeters = asNumber(data?.radiusMeters) ?? asNumber(data?.radiusM);

  if (latitude == null || longitude == null || radiusMeters == null) {
    return null;
  }

  return {
    id: zoneId,
    name: String(data?.name ?? "Danger zone"),
    latitude,
    longitude,
    radiusMeters,
    riskLevel: asRiskLevel(data?.riskLevel),
  };
}

async function listFirestoreDangerZones(childId: string) {
  const snap = await db
    .collection("zones")
    .where("childId", "==", childId)
    .get()
    .catch(() => null);

  if (!snap) return [] as RawZone[];

  return snap.docs
    .map((doc) => mapFirestoreZone(doc))
    .filter((zone): zone is RawZone => zone !== null);
}

async function listLegacyDangerZones(childId: string) {
  const snap = await admin.database().ref(`zonesByChild/${childId}`).get();
  if (!snap.exists()) return [] as RawZone[];

  const raw = snap.val() as Record<string, any>;
  return Object.entries(raw)
    .map(([zoneId, data]) => mapRtdbZone(zoneId, data))
    .filter((zone): zone is RawZone => zone !== null);
}

export async function listDangerZoneHazardsForChild(childId: string) {
  const firestoreZones = await listFirestoreDangerZones(childId);
  if (firestoreZones.length) {
    return firestoreZones.map<RouteHazardRecord>((zone) => ({
      id: zone.id,
      name: zone.name,
      latitude: zone.latitude,
      longitude: zone.longitude,
      radiusMeters: zone.radiusMeters,
      riskLevel: zone.riskLevel,
      sourceZoneId: zone.id,
    }));
  }

  const legacyZones = await listLegacyDangerZones(childId);
  return legacyZones.map<RouteHazardRecord>((zone) => ({
    id: zone.id,
    name: zone.name,
    latitude: zone.latitude,
    longitude: zone.longitude,
    radiusMeters: zone.radiusMeters,
    riskLevel: zone.riskLevel,
    sourceZoneId: zone.id,
  }));
}

export async function listRouteRelevantHazards(
  childId: string,
  routePoints: RoutePointRecord[],
  corridorWidthMeters: number
) {
  const allHazards = await listDangerZoneHazardsForChild(childId);
  return allHazards.filter((hazard) => {
    const distance = distancePointToPolylineMeters(
      hazard.latitude,
      hazard.longitude,
      routePoints
    );
    return distance <= hazard.radiusMeters + corridorWidthMeters;
  });
}

