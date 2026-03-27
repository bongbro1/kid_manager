import {
  CallableRequest,
  HttpsError,
  onCall,
} from "firebase-functions/https";
import { createHash, randomBytes, randomInt, timingSafeEqual } from "node:crypto";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";

const OTP_COLLECTION = "email_otps";
const MAIL_QUEUE_COLLECTION = "mail_queue";
const RATE_LIMIT_COLLECTION = "auth_rate_limits";
const RESET_SESSION_COLLECTION = "reset_sessions";
const USERS_COLLECTION = "users";

const OTP_TTL_MS = 5 * 60 * 1000;
const OTP_LOCK_MS = 10 * 60 * 1000;
const OTP_MAX_ATTEMPTS = 3;
const OTP_LENGTH = 6;

const RESET_SESSION_TTL_MS = 15 * 60 * 1000;

const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const RATE_LIMIT_MAX_REQUESTS = 5;

type OtpType = "verify-email" | "reset-password";
type MailQueueType = "verify_email" | "reset_password";

type UserIdentity = {
  uid: string;
  email: string | null;
};

type OtpChallengeRecord = {
  id: string;
  type: OtpType;
  uid: string | null;
  email: string;
  emailHash: string;
  otpHash: string;
  otpSalt: string;
  attempts: number;
  maxAttempts: number;
  lockedUntil: Date | null;
  expiresAt: Date;
  createdAt: Date;
  updatedAt: Date;
};

type ResetSessionRecord = {
  id: string;
  uid: string;
  emailHash: string;
  expiresAt: Date;
  used: boolean;
  createdAt: Date;
  usedAt: Date | null;
};

type ConsumeResetSessionResult =
  | { status: "ok"; session: ResetSessionRecord }
  | { status: "missing" | "expired" | "used" };

type MailJob = {
  to: string;
  type: MailQueueType;
  code: string;
  uid?: string | null;
  createdAt: Date;
  status: "pending";
};

export interface UserAuthStore {
  getUserByUid(uid: string): Promise<UserIdentity | null>;
  getUserByEmail(email: string): Promise<UserIdentity | null>;
  createOrReplaceOtp(record: OtpChallengeRecord): Promise<void>;
  getOtp(id: string): Promise<OtpChallengeRecord | null>;
  updateOtpFailure(params: {
    id: string;
    attempts: number;
    lockedUntil: Date | null;
    updatedAt: Date;
  }): Promise<void>;
  deleteOtp(id: string): Promise<void>;
  createMailJob(job: MailJob): Promise<void>;
  setUserActive(uid: string): Promise<void>;
  consumeRateLimit(params: {
    id: string;
    scope: string;
    key: string;
    now: Date;
    maxRequests: number;
    windowMs: number;
  }): Promise<boolean>;
  createResetSession(record: ResetSessionRecord): Promise<void>;
  consumeResetSession(params: {
    id: string;
    now: Date;
  }): Promise<ConsumeResetSessionResult>;
  updateUserPassword(uid: string, newPassword: string): Promise<void>;
  revokeRefreshTokens(uid: string): Promise<void>;
}

export interface UserAuthRuntime {
  now(): Date;
  randomOtp(): string;
  randomSalt(): string;
  randomToken(): string;
  getClientIp(request: CallableRequest<unknown>): string;
}

const defaultRuntime: UserAuthRuntime = {
  now: () => new Date(),
  randomOtp: () => {
    const upperBound = 10 ** OTP_LENGTH;
    const lowerBound = 10 ** (OTP_LENGTH - 1);
    return String(randomInt(lowerBound, upperBound));
  },
  randomSalt: () => randomBytes(16).toString("hex"),
  randomToken: () => randomBytes(32).toString("hex"),
  getClientIp: (request) => extractClientIp(request),
};

class FirestoreUserAuthStore implements UserAuthStore {
  async getUserByUid(uid: string): Promise<UserIdentity | null> {
    try {
      const user = await admin.auth().getUser(uid);
      return {
        uid: user.uid,
        email: user.email ?? null,
      };
    } catch (error: unknown) {
      if (isFirebaseAuthError(error, "auth/user-not-found")) {
        return null;
      }
      throw error;
    }
  }

  async getUserByEmail(email: string): Promise<UserIdentity | null> {
    try {
      const user = await admin.auth().getUserByEmail(email);
      return {
        uid: user.uid,
        email: user.email ?? null,
      };
    } catch (error: unknown) {
      if (isFirebaseAuthError(error, "auth/user-not-found")) {
        return null;
      }
      throw error;
    }
  }

  async createOrReplaceOtp(record: OtpChallengeRecord): Promise<void> {
    await db.collection(OTP_COLLECTION).doc(record.id).set({
      type: record.type,
      uid: record.uid,
      email: record.email,
      emailHash: record.emailHash,
      otpHash: record.otpHash,
      otpSalt: record.otpSalt,
      attempts: record.attempts,
      maxAttempts: record.maxAttempts,
      lockedUntil: toTimestamp(record.lockedUntil),
      expiresAt: toTimestamp(record.expiresAt),
      createdAt: toTimestamp(record.createdAt),
      updatedAt: toTimestamp(record.updatedAt),
    });
  }

  async getOtp(id: string): Promise<OtpChallengeRecord | null> {
    const snap = await db.collection(OTP_COLLECTION).doc(id).get();
    if (!snap.exists) {
      return null;
    }

    const data = snap.data();
    if (!data) {
      return null;
    }

    return {
      id: snap.id,
      type: String(data.type) as OtpType,
      uid: data.uid == null ? null : String(data.uid),
      email: String(data.email ?? ""),
      emailHash: String(data.emailHash ?? ""),
      otpHash: String(data.otpHash ?? ""),
      otpSalt: String(data.otpSalt ?? ""),
      attempts: Number(data.attempts ?? 0),
      maxAttempts: Number(data.maxAttempts ?? OTP_MAX_ATTEMPTS),
      lockedUntil: fromTimestamp(data.lockedUntil),
      expiresAt: fromTimestampRequired(data.expiresAt),
      createdAt: fromTimestampRequired(data.createdAt),
      updatedAt: fromTimestampRequired(data.updatedAt),
    };
  }

  async updateOtpFailure(params: {
    id: string;
    attempts: number;
    lockedUntil: Date | null;
    updatedAt: Date;
  }): Promise<void> {
    await db.collection(OTP_COLLECTION).doc(params.id).update({
      attempts: params.attempts,
      lockedUntil: toTimestamp(params.lockedUntil),
      updatedAt: toTimestamp(params.updatedAt),
    });
  }

  async deleteOtp(id: string): Promise<void> {
    await db.collection(OTP_COLLECTION).doc(id).delete();
  }

  async createMailJob(job: MailJob): Promise<void> {
    await db.collection(MAIL_QUEUE_COLLECTION).add({
      to: job.to,
      type: job.type,
      code: job.code,
      uid: job.uid ?? null,
      createdAt: toTimestamp(job.createdAt),
      status: job.status,
    });
  }

  async setUserActive(uid: string): Promise<void> {
    await db.collection(USERS_COLLECTION).doc(uid).update({
      isActive: true,
      lastActiveAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  async consumeRateLimit(params: {
    id: string;
    scope: string;
    key: string;
    now: Date;
    maxRequests: number;
    windowMs: number;
  }): Promise<boolean> {
    const ref = db.collection(RATE_LIMIT_COLLECTION).doc(params.id);
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const expiresAt = params.now.getTime() + params.windowMs;

      if (!snap.exists) {
        tx.set(ref, {
          scope: params.scope,
          key: params.key,
          count: 1,
          createdAt: toTimestamp(params.now),
          updatedAt: toTimestamp(params.now),
          expiresAt: toTimestamp(new Date(expiresAt)),
        });
        return true;
      }

      const data = snap.data() ?? {};
      const currentExpiry = fromTimestamp(data.expiresAt);
      const currentCount = Number(data.count ?? 0);

      if (!currentExpiry || currentExpiry.getTime() <= params.now.getTime()) {
        tx.set(ref, {
          scope: params.scope,
          key: params.key,
          count: 1,
          createdAt: toTimestamp(params.now),
          updatedAt: toTimestamp(params.now),
          expiresAt: toTimestamp(new Date(expiresAt)),
        });
        return true;
      }

      if (currentCount >= params.maxRequests) {
        return false;
      }

      tx.update(ref, {
        count: currentCount + 1,
        updatedAt: toTimestamp(params.now),
      });
      return true;
    });
  }

  async createResetSession(record: ResetSessionRecord): Promise<void> {
    await db.collection(RESET_SESSION_COLLECTION).doc(record.id).set({
      uid: record.uid,
      emailHash: record.emailHash,
      expiresAt: toTimestamp(record.expiresAt),
      used: record.used,
      createdAt: toTimestamp(record.createdAt),
      usedAt: toTimestamp(record.usedAt),
    });
  }

  async consumeResetSession(params: {
    id: string;
    now: Date;
  }): Promise<ConsumeResetSessionResult> {
    const ref = db.collection(RESET_SESSION_COLLECTION).doc(params.id);
    return db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) {
        return { status: "missing" } as const;
      }

      const data = snap.data() ?? {};
      const expiresAt = fromTimestamp(data.expiresAt);
      if (!expiresAt || expiresAt.getTime() <= params.now.getTime()) {
        return { status: "expired" } as const;
      }

      if (data.used === true) {
        return { status: "used" } as const;
      }

      tx.update(ref, {
        used: true,
        usedAt: toTimestamp(params.now),
      });

      return {
        status: "ok",
        session: {
          id: snap.id,
          uid: String(data.uid ?? ""),
          emailHash: String(data.emailHash ?? ""),
          expiresAt,
          used: false,
          createdAt: fromTimestampRequired(data.createdAt),
          usedAt: null,
        },
      } as const;
    });
  }

  async updateUserPassword(uid: string, newPassword: string): Promise<void> {
    await admin.auth().updateUser(uid, {
      password: newPassword,
    });
  }

  async revokeRefreshTokens(uid: string): Promise<void> {
    await admin.auth().revokeRefreshTokens(uid);
  }
}

function toTimestamp(value: Date | null): admin.firestore.Timestamp | null {
  if (!value) {
    return null;
  }
  return admin.firestore.Timestamp.fromDate(value);
}

function fromTimestamp(value: unknown): Date | null {
  if (!value) {
    return null;
  }
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  return null;
}

function fromTimestampRequired(value: unknown): Date {
  const parsed = fromTimestamp(value);
  if (!parsed) {
    throw new Error("Missing timestamp field");
  }
  return parsed;
}

function isFirebaseAuthError(error: unknown, code: string): boolean {
  return typeof error === "object"
    && error !== null
    && "code" in error
    && (error as { code?: unknown }).code === code;
}

function normalizeEmail(input: unknown): string {
  return String(input ?? "").trim().toLowerCase();
}

function validateEmail(email: string): void {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError("invalid-argument", "Invalid email");
  }
}

function normalizeOtp(input: unknown): string {
  return String(input ?? "").trim();
}

function validateOtp(otp: string): void {
  const otpRegex = new RegExp(`^\\d{${OTP_LENGTH}}$`);
  if (!otpRegex.test(otp)) {
    throw new HttpsError("invalid-argument", "Invalid OTP format");
  }
}

function normalizePassword(input: unknown): string {
  return String(input ?? "").trim();
}

function validatePassword(password: string): void {
  if (password.length < 8 || password.length > 128) {
    throw new HttpsError("invalid-argument", "Invalid password");
  }
}

function sha256Hex(value: string): string {
  return createHash("sha256").update(value).digest("hex");
}

function hashWithSalt(secret: string, salt: string): string {
  return sha256Hex(`${salt}:${secret}`);
}

function constantTimeEqualHex(leftHex: string, rightHex: string): boolean {
  const left = Buffer.from(leftHex, "hex");
  const right = Buffer.from(rightHex, "hex");

  if (left.length !== right.length) {
    return false;
  }

  return timingSafeEqual(left, right);
}

function hashEmail(email: string): string {
  return sha256Hex(`email:${email}`);
}

function buildVerifyEmailOtpId(uid: string): string {
  return `verify-email:${uid}`;
}

function buildResetPasswordOtpId(emailHash: string): string {
  return `reset-password:${emailHash}`;
}

function buildRateLimitId(scope: string, key: string): string {
  return sha256Hex(`rate:${scope}:${key}`);
}

function buildResetSessionId(token: string): string {
  return sha256Hex(`reset-session:${token}`);
}

function extractClientIp(request: CallableRequest<unknown>): string {
  const forwardedFor = request.rawRequest.headers["x-forwarded-for"];
  if (typeof forwardedFor === "string" && forwardedFor.trim().length > 0) {
    return forwardedFor.split(",")[0].trim();
  }

  const ip = request.rawRequest.ip;
  if (typeof ip === "string" && ip.trim().length > 0) {
    return ip.trim();
  }

  return "unknown";
}

function addMilliseconds(date: Date, milliseconds: number): Date {
  return new Date(date.getTime() + milliseconds);
}

function toMailQueueType(type: OtpType): MailQueueType {
  return type === "verify-email" ? "verify_email" : "reset_password";
}

async function enforceRateLimit(params: {
  store: UserAuthStore;
  scope: string;
  email: string;
  ip: string;
  now: Date;
}): Promise<boolean> {
  const emailAllowed = await params.store.consumeRateLimit({
    id: buildRateLimitId(params.scope, `email:${params.email}`),
    scope: params.scope,
    key: `email:${params.email}`,
    now: params.now,
    maxRequests: RATE_LIMIT_MAX_REQUESTS,
    windowMs: RATE_LIMIT_WINDOW_MS,
  });

  if (!emailAllowed) {
    return false;
  }

  return params.store.consumeRateLimit({
    id: buildRateLimitId(params.scope, `ip:${params.ip}`),
    scope: params.scope,
    key: `ip:${params.ip}`,
    now: params.now,
    maxRequests: RATE_LIMIT_MAX_REQUESTS,
    windowMs: RATE_LIMIT_WINDOW_MS,
  });
}

async function issueOtp(params: {
  store: UserAuthStore;
  runtime: UserAuthRuntime;
  type: OtpType;
  id: string;
  uid: string | null;
  email: string;
  sendEmail: boolean;
}): Promise<void> {
  const now = params.runtime.now();
  const otp = params.runtime.randomOtp();
  const otpSalt = params.runtime.randomSalt();
  const emailHash = hashEmail(params.email);

  await params.store.createOrReplaceOtp({
    id: params.id,
    type: params.type,
    uid: params.uid,
    email: params.email,
    emailHash,
    otpHash: hashWithSalt(otp, otpSalt),
    otpSalt,
    attempts: 0,
    maxAttempts: OTP_MAX_ATTEMPTS,
    lockedUntil: null,
    expiresAt: addMilliseconds(now, OTP_TTL_MS),
    createdAt: now,
    updatedAt: now,
  });

  if (!params.sendEmail) {
    return;
  }

  await params.store.createMailJob({
    to: params.email,
    type: toMailQueueType(params.type),
    code: otp,
    uid: params.uid,
    createdAt: now,
    status: "pending",
  });
}

async function verifyOtpRecord(params: {
  store: UserAuthStore;
  now: Date;
  expectedType: OtpType;
  id: string;
  otp: string;
}): Promise<OtpChallengeRecord> {
  const record = await params.store.getOtp(params.id);

  if (!record || record.type !== params.expectedType) {
    throw new HttpsError("invalid-argument", "Invalid OTP");
  }

  if (record.expiresAt.getTime() <= params.now.getTime()) {
    await params.store.deleteOtp(record.id);
    throw new HttpsError("failed-precondition", "OTP expired");
  }

  if (record.lockedUntil && record.lockedUntil.getTime() > params.now.getTime()) {
    throw new HttpsError("resource-exhausted", "Too many attempts");
  }

  const candidateHash = hashWithSalt(params.otp, record.otpSalt);
  const isMatch = constantTimeEqualHex(candidateHash, record.otpHash);

  if (!isMatch) {
    const attempts = record.attempts + 1;
    const lockedUntil = attempts >= record.maxAttempts
      ? addMilliseconds(params.now, OTP_LOCK_MS)
      : null;

    await params.store.updateOtpFailure({
      id: record.id,
      attempts,
      lockedUntil,
      updatedAt: params.now,
    });

    if (attempts >= record.maxAttempts) {
      throw new HttpsError("resource-exhausted", "Too many attempts");
    }

    throw new HttpsError("invalid-argument", "Invalid OTP");
  }

  await params.store.deleteOtp(record.id);
  return record;
}

function successResponse(): { success: true } {
  return { success: true };
}

export function createUserAuthHandlers(
  store: UserAuthStore,
  runtime: UserAuthRuntime = defaultRuntime,
) {
  return {
    requestEmailOtp: async (request: CallableRequest<unknown>) => {
      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Login required");
      }

      const user = await store.getUserByUid(uid);
      const email = normalizeEmail(user?.email);
      if (!email) {
        throw new HttpsError("failed-precondition", "Email not found");
      }

      const now = runtime.now();
      const ip = runtime.getClientIp(request);
      const allowed = await enforceRateLimit({
        store,
        scope: "request-email-otp",
        email,
        ip,
        now,
      });

      if (!allowed) {
        throw new HttpsError("resource-exhausted", "Too many requests");
      }

      await issueOtp({
        store,
        runtime,
        type: "verify-email",
        id: buildVerifyEmailOtpId(uid),
        uid,
        email,
        sendEmail: true,
      });

      return successResponse();
    },

    verifyEmailOtp: async (request: CallableRequest<unknown>) => {
      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Login required");
      }

      const otp = normalizeOtp((request.data as { otp?: unknown } | null)?.otp);
      validateOtp(otp);

      const record = await verifyOtpRecord({
        store,
        now: runtime.now(),
        expectedType: "verify-email",
        id: buildVerifyEmailOtpId(uid),
        otp,
      });

      if (!record.uid || record.uid !== uid) {
        throw new HttpsError("permission-denied", "OTP does not belong to caller");
      }

      await store.setUserActive(uid);
      return successResponse();
    },

    requestPasswordReset: async (request: CallableRequest<unknown>) => {
      const email = normalizeEmail((request.data as { email?: unknown } | null)?.email);
      validateEmail(email);

      const now = runtime.now();
      const ip = runtime.getClientIp(request);
      const allowed = await enforceRateLimit({
        store,
        scope: "request-password-reset",
        email,
        ip,
        now,
      });

      if (!allowed) {
        return successResponse();
      }

      const user = await store.getUserByEmail(email);
      await issueOtp({
        store,
        runtime,
        type: "reset-password",
        id: buildResetPasswordOtpId(hashEmail(email)),
        uid: user?.uid ?? null,
        email,
        sendEmail: Boolean(user?.uid),
      });

      return successResponse();
    },

    verifyPasswordResetOtp: async (request: CallableRequest<unknown>) => {
      const data = request.data as { email?: unknown; otp?: unknown } | null;
      const email = normalizeEmail(data?.email);
      const otp = normalizeOtp(data?.otp);

      validateEmail(email);
      validateOtp(otp);

      const record = await verifyOtpRecord({
        store,
        now: runtime.now(),
        expectedType: "reset-password",
        id: buildResetPasswordOtpId(hashEmail(email)),
        otp,
      });

      if (!record.uid) {
        throw new HttpsError("invalid-argument", "Invalid OTP");
      }

      const resetSessionToken = runtime.randomToken();
      const now = runtime.now();

      await store.createResetSession({
        id: buildResetSessionId(resetSessionToken),
        uid: record.uid,
        emailHash: record.emailHash,
        expiresAt: addMilliseconds(now, RESET_SESSION_TTL_MS),
        used: false,
        createdAt: now,
        usedAt: null,
      });

      return {
        success: true as const,
        resetSessionToken,
      };
    },

    resetUserPassword: async (request: CallableRequest<unknown>) => {
      const data = request.data as {
        resetSessionToken?: unknown;
        newPassword?: unknown;
      } | null;

      const resetSessionToken = String(data?.resetSessionToken ?? "").trim();
      const newPassword = normalizePassword(data?.newPassword);

      if (!resetSessionToken) {
        throw new HttpsError("invalid-argument", "Missing reset session token");
      }

      validatePassword(newPassword);

      const consumeResult = await store.consumeResetSession({
        id: buildResetSessionId(resetSessionToken),
        now: runtime.now(),
      });

      if (consumeResult.status === "missing") {
        throw new HttpsError("failed-precondition", "Reset session not found");
      }

      if (consumeResult.status === "expired") {
        throw new HttpsError("failed-precondition", "Reset session expired");
      }

      if (consumeResult.status === "used") {
        throw new HttpsError("failed-precondition", "Reset session already used");
      }

      if (consumeResult.status !== "ok") {
        throw new HttpsError("internal", "Unexpected reset session state");
      }

      const uid = consumeResult.session.uid;
      await store.updateUserPassword(uid, newPassword);
      await store.revokeRefreshTokens(uid);

      return successResponse();
    },
  };
}

const store = new FirestoreUserAuthStore();
const handlers = createUserAuthHandlers(store, defaultRuntime);

export const requestEmailOtp = onCall(
  { region: REGION },
  handlers.requestEmailOtp,
);

export const verifyEmailOtp = onCall(
  { region: REGION },
  handlers.verifyEmailOtp,
);

export const requestPasswordReset = onCall(
  { region: REGION },
  handlers.requestPasswordReset,
);

export const verifyPasswordResetOtp = onCall(
  { region: REGION },
  handlers.verifyPasswordResetOtp,
);

export const resetUserPassword = onCall(
  { region: REGION },
  handlers.resetUserPassword,
);
