import { pointInCircleMeters } from "../utils/safeRouteGeo";
import { validateLatLng } from "../helpers";

export type TrustedZoneRecord = {
  id: string;
  name: string;
  type: "safe" | "danger";
  lat: number;
  lng: number;
  radiusM: number;
  enabled: boolean;
};

export type ZoneObservationRecord = {
  childUid: string;
  latitude: number;
  longitude: number;
  timestamp: number;
};

export type ZonePresenceRecord = {
  inside: boolean;
  zoneType: "safe" | "danger";
  zoneName: string;
  enterAt: number;
  updatedAt: number;
};

export type CanonicalZoneEventRecord = {
  canonical: true;
  source: "server_zone_evaluator";
  childUid: string;
  zoneId: string;
  zoneType: "safe" | "danger";
  action: "enter" | "exit";
  zoneName: string;
  timestamp: number;
  lat: number;
  lng: number;
  enterAt: number | null;
  durationSec: number;
  durationMin: number;
};

function asFiniteNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }
  return null;
}

function asPositiveInt(value: unknown): number | null {
  const parsed = asFiniteNumber(value);
  if (parsed == null) {
    return null;
  }
  return Math.trunc(parsed);
}

function asZoneType(value: unknown): "safe" | "danger" | null {
  const normalized =
    typeof value === "string" ? value.trim().toLowerCase() : "";
  if (normalized === "safe" || normalized === "danger") {
    return normalized;
  }
  return null;
}

function optionalTrimmedString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized ? normalized : null;
}

export function parseTrustedZones(raw: unknown): TrustedZoneRecord[] {
  if (!raw || typeof raw !== "object") {
    return [];
  }

  return Object.entries(raw as Record<string, unknown>)
    .map(([zoneId, value]) => {
      if (!value || typeof value !== "object") {
        return null;
      }

      const record = value as Record<string, unknown>;
      const type = asZoneType(record.type);
      const lat = asFiniteNumber(record.lat);
      const lng = asFiniteNumber(record.lng);
      const radiusM = asFiniteNumber(record.radiusM);
      const name = optionalTrimmedString(record.name);

      if (
        !zoneId.trim() ||
        type == null ||
        lat == null ||
        lng == null ||
        radiusM == null ||
        name == null
      ) {
        return null;
      }

      validateLatLng(lat, lng);

      return {
        id: zoneId.trim(),
        name,
        type,
        lat,
        lng,
        radiusM,
        enabled: record.enabled !== false,
      } satisfies TrustedZoneRecord;
    })
    .filter((zone): zone is TrustedZoneRecord => zone != null && zone.enabled);
}

export function parseZoneObservation(
  childUid: string,
  raw: unknown,
): ZoneObservationRecord | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }

  const record = raw as Record<string, unknown>;
  const latitude = asFiniteNumber(record.latitude ?? record.lat);
  const longitude = asFiniteNumber(record.longitude ?? record.lng);
  if (latitude == null || longitude == null) {
    return null;
  }
  validateLatLng(latitude, longitude);

  const timestamp = asPositiveInt(record.timestamp) ?? Date.now();
  return {
    childUid,
    latitude,
    longitude,
    timestamp,
  };
}

export function parseZonePresenceRecord(raw: unknown): ZonePresenceRecord | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }

  const record = raw as Record<string, unknown>;
  const zoneType = asZoneType(record.zoneType);
  const zoneName = optionalTrimmedString(record.zoneName);
  const enterAt = asPositiveInt(record.enterAt);
  const updatedAt = asPositiveInt(record.updatedAt) ?? enterAt ?? 0;

  if (record.inside !== true || zoneType == null || zoneName == null || enterAt == null) {
    return null;
  }

  return {
    inside: true,
    zoneType,
    zoneName,
    enterAt,
    updatedAt,
  };
}

function buildEnterEvent(params: {
  childUid: string;
  zone: TrustedZoneRecord;
  observation: ZoneObservationRecord;
}): CanonicalZoneEventRecord {
  const { childUid, zone, observation } = params;
  return {
    canonical: true,
    source: "server_zone_evaluator",
    childUid,
    zoneId: zone.id,
    zoneType: zone.type,
    action: "enter",
    zoneName: zone.name,
    timestamp: observation.timestamp,
    lat: observation.latitude,
    lng: observation.longitude,
    enterAt: observation.timestamp,
    durationSec: 0,
    durationMin: 0,
  };
}

function buildExitEvent(params: {
  childUid: string;
  zone: TrustedZoneRecord;
  observation: ZoneObservationRecord;
  presence: ZonePresenceRecord;
}): CanonicalZoneEventRecord {
  const { childUid, zone, observation, presence } = params;
  const durationSec = Math.max(
    0,
    Math.floor((observation.timestamp - presence.enterAt) / 1000),
  );
  const durationMin =
    durationSec > 0 ? Math.max(1, Math.round(durationSec / 60)) : 0;

  return {
    canonical: true,
    source: "server_zone_evaluator",
    childUid,
    zoneId: zone.id,
    zoneType: zone.type,
    action: "exit",
    zoneName: zone.name,
    timestamp: observation.timestamp,
    lat: observation.latitude,
    lng: observation.longitude,
    enterAt: presence.enterAt,
    durationSec,
    durationMin,
  };
}

export function computeCanonicalZoneEvents(params: {
  childUid: string;
  observation: ZoneObservationRecord;
  zones: TrustedZoneRecord[];
  presenceByZone: Record<string, unknown>;
}): CanonicalZoneEventRecord[] {
  const { childUid, observation, zones, presenceByZone } = params;
  const events: CanonicalZoneEventRecord[] = [];

  for (const zone of zones) {
    const isInside = pointInCircleMeters(
      observation.latitude,
      observation.longitude,
      zone.lat,
      zone.lng,
      zone.radiusM,
    );
    const presence = parseZonePresenceRecord(presenceByZone[zone.id]);
    const wasInside = presence?.inside == true;

    if (isInside && !wasInside) {
      events.push(buildEnterEvent({ childUid, zone, observation }));
      continue;
    }

    if (!isInside && wasInside && presence != null) {
      events.push(buildExitEvent({ childUid, zone, observation, presence }));
    }
  }

  return events;
}

export function isCanonicalZoneEventRecord(
  raw: unknown,
): raw is CanonicalZoneEventRecord {
  if (!raw || typeof raw !== "object") {
    return false;
  }

  const record = raw as Record<string, unknown>;
  const zoneType = asZoneType(record.zoneType);
  const action =
    typeof record.action === "string" ? record.action.trim().toLowerCase() : "";

  return (
    record.canonical === true &&
    record.source === "server_zone_evaluator" &&
    typeof record.childUid === "string" &&
    record.childUid.trim().length > 0 &&
    typeof record.zoneId === "string" &&
    record.zoneId.trim().length > 0 &&
    zoneType != null &&
    (action === "enter" || action === "exit") &&
    optionalTrimmedString(record.zoneName) != null &&
    asFiniteNumber(record.lat) != null &&
    asFiniteNumber(record.lng) != null &&
    asPositiveInt(record.timestamp) != null
  );
}
