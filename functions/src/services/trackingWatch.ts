import { admin } from "../bootstrap";

export const TRACKING_WATCH_COLLECTION = "tracking_watch";
export const TRACKING_HEARTBEAT_STALE_AFTER_MS = 3 * 60 * 1000;

const TRACKING_ACTIVE_STATUSES = new Set([
  "ok",
  "location_stale",
]);

const TRACKING_PROTECTED_STATUSES = new Set([
  "location_service_off",
  "location_permission_denied",
  "background_disabled",
]);

function normalizeStatus(status: string | null | undefined): string {
  return String(status ?? "").trim().toLowerCase();
}

export function isTrackingProtectedStatus(status: string | null | undefined) {
  return TRACKING_PROTECTED_STATUSES.has(normalizeStatus(status));
}

export function isTrackingActiveStatus(status: string | null | undefined) {
  return TRACKING_ACTIVE_STATUSES.has(normalizeStatus(status));
}

export function buildTrackingWatchHeartbeatUpdate(params: {
  familyId: string;
  childUid: string;
  heartbeatMs: number;
  nowMs?: number;
}) {
  const nowMs = params.nowMs ?? Date.now();
  return {
    familyId: params.familyId,
    childUid: params.childUid,
    isTracking: true,
    lastTrustedHeartbeatAt: params.heartbeatMs,
    nextHeartbeatCheckAt: params.heartbeatMs + TRACKING_HEARTBEAT_STALE_AFTER_MS,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAtMs: nowMs,
  };
}

export function buildTrackingWatchStoppedUpdate(params: {
  familyId: string;
  childUid: string;
  nowMs?: number;
}) {
  const nowMs = params.nowMs ?? Date.now();
  return {
    familyId: params.familyId,
    childUid: params.childUid,
    isTracking: false,
    nextHeartbeatCheckAt: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAtMs: nowMs,
  };
}

export function buildTrackingWatchStatusUpdate(params: {
  familyId: string;
  childUid: string;
  status: string;
  updatedAtMs?: number;
}) {
  const status = normalizeStatus(params.status);
  const updatedAtMs = params.updatedAtMs ?? Date.now();

  const update: Record<string, unknown> = {
    familyId: params.familyId,
    childUid: params.childUid,
    lastKnownStatus: status,
    statusUpdatedAt: updatedAtMs,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAtMs,
  };

  if (isTrackingProtectedStatus(status)) {
    update.isTracking = false;
    update.nextHeartbeatCheckAt = null;
  } else if (isTrackingActiveStatus(status)) {
    update.isTracking = true;
  }

  return update;
}
