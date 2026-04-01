import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";

export const FREE_ZONE_LIMIT = 3;
export const FREE_SAFE_ROUTE_LIMIT = 3;
export const ZONE_LIMIT_ERROR = "FREE_PLAN_ZONE_LIMIT_REACHED";
export const SAFE_ROUTE_LIMIT_ERROR = "FREE_PLAN_SAFE_ROUTE_LIMIT_REACHED";

function readMillis(value: unknown): number | null {
  if (value == null) return null;
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }
  if (value instanceof Date) {
    return value.getTime();
  }
  if (
    typeof value === "object" &&
    value !== null &&
    "toMillis" in value &&
    typeof (value as { toMillis: () => number }).toMillis === "function"
  ) {
    return (value as { toMillis: () => number }).toMillis();
  }
  return null;
}

function isUnlimitedSubscription(data: Record<string, unknown>) {
  const raw = data.subscription;
  if (raw == null || typeof raw !== "object") {
    return false;
  }

  const subscription = raw as Record<string, unknown>;
  const plan = String(subscription.plan ?? "free").trim().toLowerCase();
  const status = String(subscription.status ?? "").trim().toLowerCase();
  const endAtMs = readMillis(subscription.endAt);

  if (status !== "active" && status !== "trial") {
    return false;
  }
  if (endAtMs != null && endAtMs < Date.now()) {
    return false;
  }

  return (
    plan === "pro" ||
    plan === "vip" ||
    plan === "premium"
  );
}

export async function hasUnlimitedQuota(uid: string) {
  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    return false;
  }

  const data = (userSnap.data() ?? {}) as Record<string, unknown>;
  return isUnlimitedSubscription(data);
}

export async function getQuotaOwnerUidForChild(
  childUid: string,
  fallbackUid: string
) {
  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) {
    return fallbackUid;
  }

  const data = (childSnap.data() ?? {}) as Record<string, unknown>;
  const parentUid = data.parentUid;
  return typeof parentUid === "string" && parentUid.trim()
    ? parentUid.trim()
    : fallbackUid;
}

export async function getRemainingQuota(params: {
  ownerUid: string;
  limit: number;
  currentCount: number;
}) {
  const unlimited = await hasUnlimitedQuota(params.ownerUid);
  if (unlimited) {
    return {
      unlimited: true,
      remaining: Number.POSITIVE_INFINITY,
    };
  }

  return {
    unlimited: false,
    remaining: Math.max(0, params.limit - params.currentCount),
  };
}

export async function enforceQuota(params: {
  ownerUid: string;
  currentCount: number;
  limit: number;
  errorMessage: string;
  feature: "zone" | "safe_route";
}) {
  const { unlimited } = await getRemainingQuota(params);
  if (unlimited || params.currentCount < params.limit) {
    return;
  }

  throw new HttpsError("resource-exhausted", params.errorMessage, {
    feature: params.feature,
    limit: params.limit,
    requiredPlan: "vip",
  });
}
