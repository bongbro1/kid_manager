import { onSchedule } from "firebase-functions/v2/scheduler";
import { admin, db } from "../../bootstrap";
import { REGION, TZ } from "../../config";
import { parseTrustedLocationSignalRecord } from "../../services/trustedLocationService";
import {
  buildTrackingWatchStatusUpdate,
  isTrackingProtectedStatus,
  TRACKING_HEARTBEAT_STALE_AFTER_MS,
  TRACKING_WATCH_COLLECTION,
} from "../../services/trackingWatch";

const SCHEDULE = "every 2 minutes";
const PAGE_SIZE = 500;

type TrackingStatusDoc = {
  status?: unknown;
  childName?: unknown;
  updatedAt?: unknown;
  source?: unknown;
};

type TrackingWatchDoc = {
  familyId?: unknown;
  childUid?: unknown;
  isTracking?: unknown;
  lastTrustedHeartbeatAt?: unknown;
  nextHeartbeatCheckAt?: unknown;
  lastKnownStatus?: unknown;
  statusUpdatedAt?: unknown;
};

function asString(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function toMillis(value: unknown): number | null {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }

  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed) && parsed > 0) {
      return Math.trunc(parsed);
    }
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

  return null;
}

function toStatusUpdatedMillis(value: unknown): number | null {
  return toMillis(value);
}

async function readHeartbeatSignal(childUid: string) {
  const signalSnap = await admin.database().ref(`live_location_trust/${childUid}`).get();
  return signalSnap.exists()
    ? parseTrustedLocationSignalRecord(signalSnap.val())
    : null;
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
  nowMs: number;
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
      updatedAtMs: params.nowMs,
    },
    { merge: true }
  );
}

async function updateTrackingWatch(params: {
  familyId: string;
  childUid: string;
  heartbeatMs: number | null;
  status: string;
  statusUpdatedAtMs: number;
  nextHeartbeatCheckAt: number | null;
  isTracking: boolean;
}) {
  await db.collection(TRACKING_WATCH_COLLECTION).doc(params.childUid).set(
    {
      ...buildTrackingWatchStatusUpdate({
        familyId: params.familyId,
        childUid: params.childUid,
        status: params.status,
        updatedAtMs: params.statusUpdatedAtMs,
      }),
      lastTrustedHeartbeatAt: params.heartbeatMs,
      nextHeartbeatCheckAt: params.nextHeartbeatCheckAt,
      isTracking: params.isTracking,
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
    let cursor:
      | FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>
      | undefined;

    while (true) {
      let query = db
        .collection(TRACKING_WATCH_COLLECTION)
        .where("isTracking", "==", true)
        .where("nextHeartbeatCheckAt", "<=", nowMs)
        .orderBy("nextHeartbeatCheckAt")
        .limit(PAGE_SIZE);
      if (cursor != null) {
        query = query.startAfter(cursor);
      }

      const dueSnap = await query.get();
      if (dueSnap.empty) {
        break;
      }

      for (const watchDoc of dueSnap.docs) {
        scannedChildren++;

        const watchData = watchDoc.data() as TrackingWatchDoc;
        const familyId = asString(watchData.familyId);
        const childUid = asString(watchData.childUid) || watchDoc.id;
        const heartbeatMs = toMillis(watchData.lastTrustedHeartbeatAt);

        if (!familyId || !childUid || heartbeatMs == null) {
          await watchDoc.ref.set(
            {
              isTracking: false,
              nextHeartbeatCheckAt: null,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAtMs: nowMs,
            },
            { merge: true }
          );
          continue;
        }

        const statusRef = db.doc(`families/${familyId}/trackingStatus/${childUid}`);
        const [heartbeatSignal, statusSnap] = await Promise.all([
          readHeartbeatSignal(childUid),
          statusRef.get(),
        ]);

        const statusData = statusSnap.exists
          ? (statusSnap.data() as TrackingStatusDoc)
          : {};
        const currentStatus =
          asString(statusData.status) || asString(watchData.lastKnownStatus);
        const currentChildName = asString(statusData.childName);
        const currentSource = asString(statusData.source).toLowerCase();
        const statusUpdatedMs =
          toStatusUpdatedMillis(statusData.updatedAt) ??
          toMillis(watchData.statusUpdatedAt);
        const statusHeartbeatFresh =
          currentSource !== "scheduler" &&
          statusUpdatedMs != null &&
          nowMs - statusUpdatedMs <= TRACKING_HEARTBEAT_STALE_AFTER_MS;
        const staleMs = nowMs - heartbeatMs;
        const isStale = staleMs > TRACKING_HEARTBEAT_STALE_AFTER_MS;

        if (isTrackingProtectedStatus(currentStatus)) {
          await updateTrackingWatch({
            familyId,
            childUid,
            heartbeatMs,
            status: currentStatus,
            statusUpdatedAtMs: statusUpdatedMs ?? nowMs,
            nextHeartbeatCheckAt: null,
            isTracking: false,
          });
          continue;
        }

        if (isStale) {
          if (statusHeartbeatFresh) {
            const nextStatus = currentStatus === "location_stale" ? "ok" : currentStatus;
            if (currentStatus === "location_stale") {
              const childName = await resolveChildName(childUid, currentChildName);
              await setTrackingStatus({
                familyId,
                childUid,
                childName,
                newStatus: "ok",
                prevStatus: currentStatus,
                message: "Tracking heartbeat active while stationary",
                nowMs,
              });
              updatedStatuses++;
            }

            await updateTrackingWatch({
              familyId,
              childUid,
              heartbeatMs,
              status: nextStatus || "ok",
              statusUpdatedAtMs: nowMs,
              nextHeartbeatCheckAt: nowMs + TRACKING_HEARTBEAT_STALE_AFTER_MS,
              isTracking: true,
            });
            continue;
          }

          if (currentStatus === "location_stale") {
            await updateTrackingWatch({
              familyId,
              childUid,
              heartbeatMs,
              status: currentStatus,
              statusUpdatedAtMs: statusUpdatedMs ?? nowMs,
              nextHeartbeatCheckAt: nowMs + TRACKING_HEARTBEAT_STALE_AFTER_MS,
              isTracking: true,
            });
            continue;
          }

          const childName = await resolveChildName(childUid, currentChildName);
          const staleMinutes = Math.max(1, Math.floor(staleMs / 60000));
          const hasRecentRejectedRawPoints =
            heartbeatSignal?.lastRejectedAt != null &&
            nowMs - heartbeatSignal.lastRejectedAt <= TRACKING_HEARTBEAT_STALE_AFTER_MS;
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
            nowMs,
          });
          await updateTrackingWatch({
            familyId,
            childUid,
            heartbeatMs,
            status: "location_stale",
            statusUpdatedAtMs: nowMs,
            nextHeartbeatCheckAt: nowMs + TRACKING_HEARTBEAT_STALE_AFTER_MS,
            isTracking: true,
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
            nowMs,
          });
          updatedStatuses++;
        }

        await updateTrackingWatch({
          familyId,
          childUid,
          heartbeatMs,
          status: currentStatus === "location_stale" ? "ok" : currentStatus || "ok",
          statusUpdatedAtMs: nowMs,
          nextHeartbeatCheckAt: heartbeatMs + TRACKING_HEARTBEAT_STALE_AFTER_MS,
          isTracking: true,
        });
      }

      if (dueSnap.size < PAGE_SIZE) {
        break;
      }
      cursor = dueSnap.docs[dueSnap.docs.length - 1];
    }

    console.log(
      `[checkTrackingHeartbeat] scanned=${scannedChildren} updated=${updatedStatuses}`
    );
  }
);
