import { onSchedule } from "firebase-functions/v2/scheduler";
import { admin, db } from "../../bootstrap";
import { REGION, TZ } from "../../config";
import {
  parseTrustedLocationSignalRecord,
  resolveTrustedHeartbeatMillis,
} from "../../services/trustedLocationService";

const SCHEDULE = "every 2 minutes";
const STALE_AFTER_MS = 3 * 60 * 1000;

const PROTECTED_STATUSES = new Set([
  "location_service_off",
  "location_permission_denied",
  "background_disabled",
]);

type TrackingStatusDoc = {
  status?: unknown;
  childName?: unknown;
  updatedAt?: unknown;
  source?: unknown;
};

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
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

function toStatusUpdatedMillis(value: unknown): number | null {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }

  if (typeof value === "object" && value !== null) {
    const maybe = value as { seconds?: unknown; _seconds?: unknown };
    const seconds =
      (typeof maybe.seconds === "number" ? maybe.seconds : null) ??
      (typeof maybe._seconds === "number" ? maybe._seconds : null);
    if (seconds != null && Number.isFinite(seconds) && seconds > 0) {
      return Math.trunc(seconds * 1000);
    }
  }

  return toMillis(value);
}

async function readHeartbeatState(childUid: string): Promise<{
  heartbeatMs: number | null;
  signal: ReturnType<typeof parseTrustedLocationSignalRecord>;
}> {
  const [signalSnap, trustedLiveSnap] = await Promise.all([
    admin.database().ref(`live_location_trust/${childUid}`).get(),
    admin.database().ref(`live_locations/${childUid}`).get(),
  ]);

  const signal = signalSnap.exists()
    ? parseTrustedLocationSignalRecord(signalSnap.val())
    : null;
  const trustedLiveLocation =
    trustedLiveSnap.exists() && trustedLiveSnap.val()
      ? (trustedLiveSnap.val() as Record<string, unknown>)
      : null;

  return {
    heartbeatMs: resolveTrustedHeartbeatMillis({
      signal,
      trustedLiveLocation,
    }),
    signal,
  };
}

async function resolveChildName(childUid: string, fallback: string): Promise<string> {
  if (fallback) return fallback;

  const userSnap = await db.doc(`users/${childUid}`).get();
  const d = userSnap.exists ? (userSnap.data() as Record<string, unknown>) : {};
  return asString(d.displayName) || asString(d.name) || "Con";
}

async function setTrackingStatus(params: {
  familyId: string;
  childUid: string;
  childName: string;
  newStatus: string;
  prevStatus: string;
  message: string;
}) {
  await db.doc(`families/${params.familyId}/trackingStatus/${params.childUid}`).set(
    {
      childId: params.childUid,
      childName: params.childName,
      familyId: params.familyId,
      status: params.newStatus,
      message: params.message,
      prevStatus: params.prevStatus,
      source: "scheduler",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

export const checkTrackingHeartbeat = onSchedule(
  {
    region: REGION,
    schedule: SCHEDULE,
    timeZone: TZ,
  },
  async () => {
    const nowMs = Date.now();
    let scannedChildren = 0;
    let updatedStatuses = 0;

    const familiesSnap = await db.collection("families").get();

    for (const familyDoc of familiesSnap.docs) {
      const familyId = familyDoc.id;
      const childMembersSnap = await db
        .collection(`families/${familyId}/members`)
        .where("role", "==", "child")
        .get();

      for (const childDoc of childMembersSnap.docs) {
        scannedChildren++;

        const childUid = childDoc.id;
        const statusRef = db.doc(`families/${familyId}/trackingStatus/${childUid}`);

        const [heartbeatState, statusSnap] = await Promise.all([
          readHeartbeatState(childUid),
          statusRef.get(),
        ]);
        const heartbeatMs = heartbeatState.heartbeatMs;
        const heartbeatSignal = heartbeatState.signal;

        // No location ever written -> skip to avoid false alarms for inactive kids.
        if (heartbeatMs == null) continue;

        const statusData = statusSnap.exists
          ? (statusSnap.data() as TrackingStatusDoc)
          : {};

        const currentStatus = asString(statusData.status);
        const currentChildName = asString(statusData.childName);
        const currentSource = asString(statusData.source).toLowerCase();
        const statusUpdatedMs = toStatusUpdatedMillis(statusData.updatedAt);
        const statusHeartbeatFresh =
          currentSource !== "scheduler" &&
          statusUpdatedMs != null && nowMs - statusUpdatedMs <= STALE_AFTER_MS;
        const staleMs = nowMs - heartbeatMs;
        const isStale = staleMs > STALE_AFTER_MS;

        if (isStale) {
          // App can be alive but intentionally stationary (no new location points).
          if (statusHeartbeatFresh) {
            if (currentStatus === "location_stale") {
              const childName = await resolveChildName(childUid, currentChildName);
              await setTrackingStatus({
                familyId,
                childUid,
                childName,
                newStatus: "ok",
                prevStatus: currentStatus,
                message: "Tracking heartbeat active while stationary",
              });
              updatedStatuses++;
            }
            continue;
          }

          if (
            currentStatus === "location_stale" ||
            PROTECTED_STATUSES.has(currentStatus)
          ) {
            continue;
          }

          const childName = await resolveChildName(childUid, currentChildName);
          const staleMinutes = Math.max(1, Math.floor(staleMs / 60000));
          const hasRecentRejectedRawPoints =
            heartbeatSignal?.lastRejectedAt != null &&
            nowMs - heartbeatSignal.lastRejectedAt <= STALE_AFTER_MS;
          const staleMessage = hasRecentRejectedRawPoints
            ? `No trusted location update for ${staleMinutes} minutes; recent raw points were rejected`
            : `No trusted location update for ${staleMinutes} minutes`;

          await setTrackingStatus({
            familyId,
            childUid,
            childName,
            newStatus: "location_stale",
            prevStatus: currentStatus,
            message: staleMessage,
          });
          updatedStatuses++;
          continue;
        }

        if (currentStatus === "location_stale") {
          const childName = await resolveChildName(childUid, currentChildName);

          await setTrackingStatus({
            familyId,
            childUid,
            childName,
            newStatus: "ok",
            prevStatus: currentStatus,
            message: "Location updates restored",
          });
          updatedStatuses++;
        }
      }
    }

    console.log(
      `[checkTrackingHeartbeat] scanned=${scannedChildren} updated=${updatedStatuses}`
    );
  }
);
