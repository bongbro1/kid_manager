import { db } from "../bootstrap";
import { TripRecord } from "../types";

type TimedSafeRouteAlertKind =
  | "deviated"
  | "backOnRoute"
  | "returnedToStart";

const TIMED_ALERT_FIELD_BY_KIND: Record<
  TimedSafeRouteAlertKind,
  keyof Pick<
    TripRecord,
    | "lastDeviationAlertAt"
    | "lastBackOnRouteAlertAt"
    | "lastReturnedToStartAlertAt"
  >
> = {
  deviated: "lastDeviationAlertAt",
  backOnRoute: "lastBackOnRouteAlertAt",
  returnedToStart: "lastReturnedToStartAlertAt",
};

function readNullableEpochMillis(
  data: FirebaseFirestore.DocumentData,
  fieldName: string
): number | null {
  const raw = data[fieldName];
  if (raw == null) {
    return null;
  }

  const parsed =
    typeof raw === "number" ? raw : Number.parseInt(String(raw), 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return null;
  }

  return Math.trunc(parsed);
}

function readNullableString(
  data: FirebaseFirestore.DocumentData,
  fieldName: string
): string | null {
  const raw = data[fieldName];
  if (raw == null) {
    return null;
  }

  const normalized = String(raw).trim();
  return normalized.length > 0 ? normalized : null;
}

export async function claimTimedSafeRouteAlertDispatch(params: {
  tripId: string;
  kind: TimedSafeRouteAlertKind;
  nowMs: number;
  cooldownMs: number;
}): Promise<boolean> {
  const lastAlertField = TIMED_ALERT_FIELD_BY_KIND[params.kind];

  return db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(params.tripId);
    const tripSnap = await transaction.get(tripRef);
    if (!tripSnap.exists) {
      return false;
    }

    const tripData = tripSnap.data() ?? {};
    const lastAlertAt = readNullableEpochMillis(tripData, lastAlertField);
    const cooldownActive =
      lastAlertAt != null && lastAlertAt + params.cooldownMs > params.nowMs;
    if (cooldownActive) {
      return false;
    }

    transaction.set(
      tripRef,
      {
        [lastAlertField]: params.nowMs,
      } satisfies Partial<TripRecord>,
      { merge: true }
    );
    return true;
  });
}

export async function claimDangerZoneSafeRouteAlertDispatch(params: {
  tripId: string;
  nowMs: number;
  cooldownMs: number;
  hazardId: string;
}): Promise<boolean> {
  return db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(params.tripId);
    const tripSnap = await transaction.get(tripRef);
    if (!tripSnap.exists) {
      return false;
    }

    const tripData = tripSnap.data() ?? {};
    const lastAlertAt = readNullableEpochMillis(tripData, "lastDangerAlertAt");
    const lastHazardId = readNullableString(tripData, "lastDangerHazardId");
    const cooldownActive =
      lastHazardId === params.hazardId &&
      lastAlertAt != null &&
      lastAlertAt + params.cooldownMs > params.nowMs;
    if (cooldownActive) {
      return false;
    }

    transaction.set(
      tripRef,
      {
        lastDangerAlertAt: params.nowMs,
        lastDangerHazardId: params.hazardId,
      } satisfies Partial<TripRecord>,
      { merge: true }
    );
    return true;
  });
}

export async function claimStationarySafeRouteAlertDispatch(params: {
  tripId: string;
  nowMs: number;
}): Promise<boolean> {
  return db.runTransaction(async (transaction) => {
    const tripRef = db.collection("trips").doc(params.tripId);
    const tripSnap = await transaction.get(tripRef);
    if (!tripSnap.exists) {
      return false;
    }

    const tripData = tripSnap.data() ?? {};
    if (tripData.hasStationaryAlertActive === true) {
      return false;
    }

    transaction.set(
      tripRef,
      {
        lastStationaryAlertAt: params.nowMs,
        hasStationaryAlertActive: true,
      } satisfies Partial<TripRecord>,
      { merge: true }
    );
    return true;
  });
}
