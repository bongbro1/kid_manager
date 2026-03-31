import { LiveLocationRecord } from "../types";
import { parseLiveLocationRecord } from "./safeRouteMonitoringService";
import { haversineMeters } from "../utils/safeRouteGeo";

export const LOCATION_TRUST_MAX_SPEED_MPS = 60;
export const LOCATION_TRUST_MAX_CLOCK_SKEW_MS = 60 * 1000;
export const LOCATION_TRUST_MAX_CURRENT_AGE_MS = 10 * 60 * 1000;
export const LOCATION_TRUST_MAX_SAFETY_ACCURACY_M = 80;
export const LOCATION_TRUST_REJECT_WINDOW_MS = 10 * 60 * 1000;
export const LOCATION_TRUST_SUSPICIOUS_REJECT_STREAK = 3;

export type LocationTrustReason =
  | "invalid_coordinates"
  | "invalid_timestamp"
  | "future_timestamp"
  | "stale_timestamp"
  | "mock_location"
  | "impossible_jump";

export type TrustedLocationAssessment = {
  location: LiveLocationRecord;
  mirrorEligible: boolean;
  safetyEligible: boolean;
  reason: LocationTrustReason | null;
};

type TrustedLocationAssessmentOptions = {
  enforceCurrentAge?: boolean;
};

export type TrustedLocationSignalRecord = {
  childId: string;
  lastEvaluatedAt: number;
  lastRawTimestamp: number | null;
  lastAcceptedAt: number | null;
  lastTrustedHeartbeatAt: number | null;
  lastTrustedTimestamp: number | null;
  lastRejectedAt: number | null;
  lastRejectedReason: LocationTrustReason | null;
  consecutiveRejectCount: number;
  rejectWindowStartedAt: number | null;
  suspicious: boolean;
};

function isFiniteNumber(value: number): boolean {
  return Number.isFinite(value);
}

function toMillis(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed) && parsed > 0) {
      return Math.trunc(parsed);
    }
  }

  return null;
}

function toNonNegativeInt(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed) && parsed >= 0) {
      return Math.trunc(parsed);
    }
  }

  return 0;
}

function hasValidCoordinates(location: LiveLocationRecord): boolean {
  return (
    isFiniteNumber(location.latitude) &&
    isFiniteNumber(location.longitude) &&
    location.latitude >= -90 &&
    location.latitude <= 90 &&
    location.longitude >= -180 &&
    location.longitude <= 180
  );
}

function hasValidTimestamp(location: LiveLocationRecord): boolean {
  return isFiniteNumber(location.timestamp) && location.timestamp > 0;
}

function isImpossibleJump(params: {
  previousTrusted: LiveLocationRecord | null;
  current: LiveLocationRecord;
}): boolean {
  const { previousTrusted, current } = params;
  if (previousTrusted == null) {
    return false;
  }
  if (current.timestamp <= previousTrusted.timestamp) {
    return false;
  }

  const dtSec = Math.max(
    1,
    (current.timestamp - previousTrusted.timestamp) / 1000,
  );
  const distanceMeters = haversineMeters(
    current.latitude,
    current.longitude,
    previousTrusted.latitude,
    previousTrusted.longitude,
  );
  const accuracyEnvelope = Math.max(
    25,
    current.accuracy + previousTrusted.accuracy,
  );
  const allowedDistanceMeters = Math.max(
    150,
    dtSec * LOCATION_TRUST_MAX_SPEED_MPS + accuracyEnvelope,
  );

  return distanceMeters > allowedDistanceMeters;
}

export function assessTrustedLiveLocation(params: {
  current: LiveLocationRecord;
  previousTrusted: LiveLocationRecord | null;
  nowMs?: number;
  options?: TrustedLocationAssessmentOptions;
}): TrustedLocationAssessment {
  const nowMs = params.nowMs ?? Date.now();
  const { current, previousTrusted } = params;
  const enforceCurrentAge = params.options?.enforceCurrentAge !== false;

  if (!hasValidCoordinates(current)) {
    return {
      location: current,
      mirrorEligible: false,
      safetyEligible: false,
      reason: "invalid_coordinates",
    };
  }

  if (!hasValidTimestamp(current)) {
    return {
      location: current,
      mirrorEligible: false,
      safetyEligible: false,
      reason: "invalid_timestamp",
    };
  }

  if (current.timestamp - nowMs > LOCATION_TRUST_MAX_CLOCK_SKEW_MS) {
    return {
      location: current,
      mirrorEligible: false,
      safetyEligible: false,
      reason: "future_timestamp",
    };
  }

  if (
    enforceCurrentAge &&
    nowMs - current.timestamp > LOCATION_TRUST_MAX_CURRENT_AGE_MS
  ) {
    return {
      location: current,
      mirrorEligible: false,
      safetyEligible: false,
      reason: "stale_timestamp",
    };
  }

  if (current.isMock) {
    return {
      location: current,
      mirrorEligible: false,
      safetyEligible: false,
      reason: "mock_location",
    };
  }

  if (isImpossibleJump({ previousTrusted, current })) {
    return {
      location: current,
      mirrorEligible: false,
      safetyEligible: false,
      reason: "impossible_jump",
    };
  }

  return {
    location: current,
    mirrorEligible: true,
    safetyEligible:
      isFiniteNumber(current.accuracy) &&
      current.accuracy > 0 &&
      current.accuracy <= LOCATION_TRUST_MAX_SAFETY_ACCURACY_M,
    reason: null,
  };
}

export function buildTrustedLiveLocationPayload(params: {
  location: LiveLocationRecord;
  nowMs?: number;
}) {
  const nowMs = params.nowMs ?? Date.now();
  return {
    ...params.location,
    source: "server_trusted_location",
    trustState: "trusted",
    trustEvaluatedAt: nowMs,
    trustedHeartbeatAt: nowMs,
    trustedRawTimestamp: params.location.timestamp,
  };
}

export function parseTrustedLocationSignalRecord(
  raw: unknown,
): TrustedLocationSignalRecord | null {
  if (!raw || typeof raw !== "object") {
    return null;
  }

  const data = raw as Record<string, unknown>;
  const childId =
    typeof data.childId === "string" && data.childId.trim()
      ? data.childId.trim()
      : null;
  if (!childId) {
    return null;
  }

  const lastRejectedReason = data.lastRejectedReason;
  return {
    childId,
    lastEvaluatedAt: toMillis(data.lastEvaluatedAt) ?? 0,
    lastRawTimestamp: toMillis(data.lastRawTimestamp),
    lastAcceptedAt: toMillis(data.lastAcceptedAt),
    lastTrustedHeartbeatAt: toMillis(data.lastTrustedHeartbeatAt),
    lastTrustedTimestamp: toMillis(data.lastTrustedTimestamp),
    lastRejectedAt: toMillis(data.lastRejectedAt),
    lastRejectedReason:
      typeof lastRejectedReason === "string" && lastRejectedReason.trim()
        ? (lastRejectedReason.trim() as LocationTrustReason)
        : null,
    consecutiveRejectCount: toNonNegativeInt(data.consecutiveRejectCount),
    rejectWindowStartedAt: toMillis(data.rejectWindowStartedAt),
    suspicious: data.suspicious === true,
  };
}

export function resolveTrustedHeartbeatMillis(params: {
  signal: TrustedLocationSignalRecord | null;
  trustedLiveLocation: Record<string, unknown> | null;
}) {
  const signalHeartbeat = params.signal?.lastTrustedHeartbeatAt ?? null;
  if (signalHeartbeat != null) {
    return signalHeartbeat;
  }

  const trustedLiveLocation = params.trustedLiveLocation;
  if (trustedLiveLocation == null) {
    return null;
  }

  return (
    toMillis(trustedLiveLocation.trustedHeartbeatAt) ??
    toMillis(trustedLiveLocation.trustEvaluatedAt)
  );
}

export function buildAcceptedTrustedLocationSignal(params: {
  childId: string;
  previousSignal: TrustedLocationSignalRecord | null;
  location: LiveLocationRecord;
  nowMs?: number;
}): TrustedLocationSignalRecord {
  const nowMs = params.nowMs ?? Date.now();
  return {
    childId: params.childId,
    lastEvaluatedAt: nowMs,
    lastRawTimestamp: params.location.timestamp,
    lastAcceptedAt: nowMs,
    lastTrustedHeartbeatAt: nowMs,
    lastTrustedTimestamp: params.location.timestamp,
    lastRejectedAt: params.previousSignal?.lastRejectedAt ?? null,
    lastRejectedReason: params.previousSignal?.lastRejectedReason ?? null,
    consecutiveRejectCount: 0,
    rejectWindowStartedAt: null,
    suspicious: false,
  };
}

export function buildRejectedTrustedLocationSignal(params: {
  childId: string;
  previousSignal: TrustedLocationSignalRecord | null;
  previousTrusted: LiveLocationRecord | null;
  assessment: TrustedLocationAssessment;
  nowMs?: number;
}): TrustedLocationSignalRecord {
  const nowMs = params.nowMs ?? Date.now();
  const previousSignal = params.previousSignal;
  const keepRejectWindow =
    previousSignal?.lastRejectedAt != null &&
    nowMs - previousSignal.lastRejectedAt <= LOCATION_TRUST_REJECT_WINDOW_MS;
  const consecutiveRejectCount = keepRejectWindow
    ? (previousSignal?.consecutiveRejectCount ?? 0) + 1
    : 1;
  const rejectWindowStartedAt = keepRejectWindow
    ? previousSignal?.rejectWindowStartedAt ??
      previousSignal?.lastRejectedAt ??
      nowMs
    : nowMs;
  const lastTrustedHeartbeatAt =
    previousSignal?.lastTrustedHeartbeatAt ?? null;
  const lastTrustedTimestamp =
    previousSignal?.lastTrustedTimestamp ??
    params.previousTrusted?.timestamp ??
    null;

  return {
    childId: params.childId,
    lastEvaluatedAt: nowMs,
    lastRawTimestamp: params.assessment.location.timestamp,
    lastAcceptedAt: previousSignal?.lastAcceptedAt ?? null,
    lastTrustedHeartbeatAt,
    lastTrustedTimestamp,
    lastRejectedAt: nowMs,
    lastRejectedReason: params.assessment.reason,
    consecutiveRejectCount,
    rejectWindowStartedAt,
    suspicious:
      consecutiveRejectCount >= LOCATION_TRUST_SUSPICIOUS_REJECT_STREAK,
  };
}

export function parseTrustedLocationHistoryPoints(params: {
  childUid: string;
  points: Record<string, any>[];
  nowMs?: number;
}) {
  const sortedPoints = [...params.points].sort(
    (left, right) =>
      Number(left.timestamp ?? 0) - Number(right.timestamp ?? 0),
  );

  const trustedPoints: Record<string, any>[] = [];
  let previousTrusted: LiveLocationRecord | null = null;

  for (const point of sortedPoints) {
    const location = parseLiveLocationRecord(params.childUid, point);
    const assessment = assessTrustedLiveLocation({
      current: location,
      previousTrusted,
      nowMs: params.nowMs,
      options: {
        enforceCurrentAge: false,
      },
    });
    if (!assessment.mirrorEligible) {
      continue;
    }

    previousTrusted = assessment.location;
    trustedPoints.push({
      ...point,
      timestamp: assessment.location.timestamp,
    });
  }

  return trustedPoints;
}
