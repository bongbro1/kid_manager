import { HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";

export const FAMILY_CHAT_RATE_LIMIT_WINDOW_MS = 30 * 1000;
export const FAMILY_CHAT_RATE_LIMIT_MAX_MESSAGES = 8;
export const FAMILY_CHAT_RATE_LIMIT_COOLDOWN_MS = 30 * 1000;

type FamilyChatRateLimitState = {
  windowStartedAtMs: number | null;
  messageCount: number;
  cooldownUntilMs: number;
};

function toPositiveInteger(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number.parseInt(value, 10);
    if (Number.isFinite(parsed) && parsed >= 0) {
      return parsed;
    }
  }

  return null;
}

export function parseFamilyChatRateLimitState(
  value: unknown,
): FamilyChatRateLimitState {
  const raw =
    value && typeof value === "object"
      ? (value as Record<string, unknown>)
      : {};

  return {
    windowStartedAtMs: toPositiveInteger(raw.windowStartedAtMs),
    messageCount: toPositiveInteger(raw.messageCount) ?? 0,
    cooldownUntilMs: toPositiveInteger(raw.cooldownUntilMs) ?? 0,
  };
}

export function evaluateFamilyChatRateLimit(params: {
  nowMs: number;
  currentState: FamilyChatRateLimitState;
}) {
  const { nowMs, currentState } = params;

  if (currentState.cooldownUntilMs > nowMs) {
    return {
      allowed: false,
      retryAfterMs: currentState.cooldownUntilMs - nowMs,
      nextState: currentState,
    };
  }

  if (
    currentState.windowStartedAtMs == null ||
    nowMs - currentState.windowStartedAtMs >= FAMILY_CHAT_RATE_LIMIT_WINDOW_MS
  ) {
    return {
      allowed: true,
      retryAfterMs: 0,
      nextState: {
        windowStartedAtMs: nowMs,
        messageCount: 1,
        cooldownUntilMs: 0,
      },
    };
  }

  if (currentState.messageCount >= FAMILY_CHAT_RATE_LIMIT_MAX_MESSAGES) {
    return {
      allowed: false,
      retryAfterMs: FAMILY_CHAT_RATE_LIMIT_COOLDOWN_MS,
      nextState: {
        ...currentState,
        cooldownUntilMs: nowMs + FAMILY_CHAT_RATE_LIMIT_COOLDOWN_MS,
      },
    };
  }

  return {
    allowed: true,
    retryAfterMs: 0,
    nextState: {
      windowStartedAtMs: currentState.windowStartedAtMs,
      messageCount: currentState.messageCount + 1,
      cooldownUntilMs: 0,
    },
  };
}

function familyChatRateLimitRef(params: { familyId: string; senderUid: string }) {
  return db.doc(
    `families/${params.familyId}/rateLimits/family_chat__${params.senderUid}`,
  );
}

export async function consumeFamilyChatRateLimit(params: {
  familyId: string;
  senderUid: string;
}) {
  const ref = familyChatRateLimitRef(params);
  const nowMs = Date.now();

  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);
    const currentState = parseFamilyChatRateLimitState(snap.exists ? snap.data() : null);
    const evaluation = evaluateFamilyChatRateLimit({
      nowMs,
      currentState,
    });

    transaction.set(
      ref,
      {
        familyId: params.familyId,
        senderUid: params.senderUid,
        windowStartedAtMs: evaluation.nextState.windowStartedAtMs,
        messageCount: evaluation.nextState.messageCount,
        cooldownUntilMs: evaluation.nextState.cooldownUntilMs,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    if (!evaluation.allowed) {
      throw new HttpsError(
        "resource-exhausted",
        "Too many family chat messages. Please wait a bit and try again.",
        { retryAfterMs: evaluation.retryAfterMs },
      );
    }
  });
}
