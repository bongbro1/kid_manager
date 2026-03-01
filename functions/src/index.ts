import * as admin from "firebase-admin";
import { createHash, randomUUID } from "crypto";
import { onCall, HttpsError, onRequest } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { defineString } from "firebase-functions/params";
import { CloudTasksClient } from "@google-cloud/tasks";
//Khi nào có tiền thì bật minInstances =1;
admin.initializeApp();
//$env:FUNCTIONS_DISCOVERY_TIMEOUT=30
//firebase deploy --only functions
// =======================
// MIRROR USER -> RTDB
// =======================
export const mirrorUserToRtdb = onDocumentCreated(
  {
    document: "users/{uid}",
    region: "asia-southeast1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    const uid = event.params.uid;
    const parentUid = data.parentUid || null;

    await admin.database().ref(`users/${uid}`).set({ parentUid });
    console.log(`Mirrored user ${uid} → RTDB`);
  }
);

const db = admin.firestore();

setGlobalOptions({
  region: "asia-southeast1",
});

// =======================
// CLOUD TASKS (REMINDER)
// =======================
const SOS_REMINDER_WORKER_URL = defineString("SOS_REMINDER_WORKER_URL");
const tasksClient = new CloudTasksClient();
const TASK_LOCATION = "asia-southeast1";
const TASK_QUEUE = "sos-reminder-queue";
const REMIND_INTERVAL_SEC = 10;
const REMIND_MAX_SECONDS = 30 * 60;

// =======================
// CONFIG
// =======================
const TZ = "Asia/Ho_Chi_Minh";
const SOS_DAILY_LIMIT = 20;
const SOS_MIN_INTERVAL_SEC = 10;
const RATE_DOC_TTL_DAYS = 14;

// =======================
// TYPES / HELPERS
// =======================
type Platform = "android" | "ios";

function sha256Hex(input: string): string {
  return createHash("sha256").update(input).digest("hex");
}

function mustString(v: unknown, name: string): string {
  if (typeof v !== "string" || !v.trim()) {
    throw new HttpsError("invalid-argument", `${name} is required`);
  }
  return v.trim();
}

function mustNumber(v: unknown, name: string): number {
  if (typeof v !== "number" || !Number.isFinite(v)) {
    throw new HttpsError("invalid-argument", `${name} must be a finite number`);
  }
  return v;
}

function mustPlatform(v: unknown): Platform {
  if (v !== "android" && v !== "ios") {
    throw new HttpsError(
      "invalid-argument",
      "platform must be 'android' or 'ios'"
    );
  }
  return v;
}

function validateLatLng(lat: number, lng: number) {
  if (lat < -90 || lat > 90)
    throw new HttpsError("invalid-argument", "lat out of range");
  if (lng < -180 || lng > 180)
    throw new HttpsError("invalid-argument", "lng out of range");
}

function dayKeyInTZ(d: Date, timeZone = TZ): string {
  // en-CA => YYYY-MM-DD
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

function isInvalidTokenErrorCode(code?: string): boolean {
  return (
    code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token"
  );
}

async function getUserFamilyAndRole(
  uid: string
): Promise<{ familyId: string; role: string }> {
  const snap = await db.doc(`users/${uid}`).get();
  const d = snap.data() ?? {};
  const familyId = d.familyId;
  const role = d.role;

  if (typeof familyId !== "string" || !familyId) {
    throw new HttpsError("failed-precondition", "Missing familyId on user profile");
  }
  if (typeof role !== "string" || !role) {
    throw new HttpsError("failed-precondition", "Missing role on user profile");
  }
  return { familyId, role };
}

function getProjectId(): string {
  return (
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    process.env.PROJECT_ID ||
    ""
  );
}

async function enqueueSosReminder(params: {
  familyId: string;
  sosId: string;
  createdAtMs: number;
}) {
  const project = getProjectId();
  if (!project) throw new Error("Missing GCLOUD_PROJECT");

  const parent = tasksClient.queuePath(project, TASK_LOCATION, TASK_QUEUE);

  const workerUrl = SOS_REMINDER_WORKER_URL.value();
  if (!workerUrl) throw new Error("Missing SOS_REMINDER_WORKER_URL env");

  const scheduleTime = {
    seconds: Math.floor(Date.now() / 1000) + REMIND_INTERVAL_SEC,
  };

  const payload = Buffer.from(
    JSON.stringify({
      familyId: params.familyId,
      sosId: params.sosId,
      createdAtMs: params.createdAtMs,
    })
  ).toString("base64");

  const task = {
    httpRequest: {
      httpMethod: "POST" as const,
      url: workerUrl,
      headers: { "Content-Type": "application/json" },
      body: payload,
      oidcToken: {
        serviceAccountEmail: `${project}@appspot.gserviceaccount.com`,
      },
    },
    scheduleTime,
  };

  console.log("[enqueueSosReminder] creating task", {
    familyId: params.familyId,
    sosId: params.sosId,
  });

  await tasksClient.createTask({ parent, task });
}

async function requireFamilyMember(familyId: string, uid: string) {
  const memberRef = db.doc(`families/${familyId}/members/${uid}`);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists)
    throw new HttpsError("permission-denied", "Not a family member");
  return memberSnap.data() ?? {};
}

// =======================
// SOS PUSH FANOUT (shared)
// =======================
async function sendSosPush(params: {
  familyId: string;
  sosId: string;
  childUid: string;
  lat?: number | null;
  lng?: number | null;
}): Promise<{
  attemptedRecipients: number;
  success: number;
  invalidTokensRemoved: number;
}> {
  const { familyId, sosId, childUid, lat, lng } = params;

  const tokenSnap = await db.collection(`families/${familyId}/fcmTokens`).get();

  const tokens: Array<{
    token: string;
    tokenHash: string;
    uid: string;
    platform?: string;
  }> = [];

  tokenSnap.forEach((doc) => {
    const data = doc.data() as any;
    const token: string | undefined = data.token;
    const uid: string | undefined = data.uid;
    if (!token || !uid) return;
    if (uid === childUid) return; // exclude sender
    tokens.push({ token, tokenHash: doc.id, uid, platform: data.platform });
  });

  if (!tokens.length) {
    return { attemptedRecipients: 0, success: 0, invalidTokensRemoved: 0 };
  }

  const baseMessage: Omit<admin.messaging.MulticastMessage, "tokens"> = {
    notification: {
      title: "🚨 SOS KHẨN CẤP",
      body: "Có thành viên đang cầu cứu. Chạm để xem vị trí.",
    },
    data: {
      type: "SOS",
      familyId: String(familyId),
      sosId: String(sosId),
      childUid: String(childUid),
      lat: lat != null ? String(lat) : "",
      lng: lng != null ? String(lng) : "",
    },
    android: {
      priority: "high",
      collapseKey: `sos_${sosId}`,
      notification: {
        channelId: "sos_channel_v2",
        sound: "sos",
        defaultVibrateTimings: true,
        visibility: "public",
        tag: `sos_${sosId}`,
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-collapse-id": `sos_${sosId}`,
      },
      payload: { aps: { sound: "sos.caf" } },
    },
  };

  const tokenChunks = chunk(tokens, 500);

  let success = 0;
  let invalidRemoved = 0;
  let totalAttempt = 0;

  for (const c of tokenChunks) {
    totalAttempt += c.length;

    const multicast: admin.messaging.MulticastMessage = {
      ...baseMessage,
      tokens: c.map((x) => x.token),
    };

    const resp = await admin.messaging().sendEachForMulticast(multicast);
    success += resp.successCount;

    const batch = db.batch();
    let hasDeletes = false;

    resp.responses.forEach((r, i) => {
      if (r.success) return;
      const err = r.error as any;
      const code: string | undefined = err?.code;
      if (isInvalidTokenErrorCode(code)) {
        const meta = c[i];
        invalidRemoved++;
        batch.delete(db.doc(`families/${familyId}/fcmTokens/${meta.tokenHash}`));
        batch.delete(db.doc(`users/${meta.uid}/fcmTokens/${meta.tokenHash}`));
        hasDeletes = true;
      }
    });

    if (hasDeletes) await batch.commit();
  }

  return {
    attemptedRecipients: totalAttempt,
    success,
    invalidTokensRemoved: invalidRemoved,
  };
}

// =======================
// WORKER: SOS REMINDER
// =======================
export const sosReminderWorker = onRequest(
  { region: "asia-southeast1" },
  async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).send("Method not allowed");
        return;
      }

      const { familyId, sosId, createdAtMs } = req.body ?? {};
      if (!familyId || !sosId || !createdAtMs) {
        res.status(400).send("Missing params");
        return;
      }

      const ageSec = (Date.now() - Number(createdAtMs)) / 1000;
      if (ageSec > REMIND_MAX_SECONDS) {
        res.status(200).send("Expired reminder window");
        return;
      }

      const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);
      const snap = await sosRef.get();
      if (!snap.exists) {
        res.status(200).send("SOS not found");
        return;
      }

      const sos = snap.data() as any;
      const status = sos.status;
      if (status !== "active") {
        res.status(200).send("SOS not active, stop");
        return;
      }

      const loc = sos.location ?? {};
      const lat = loc.lat;
      const lng = loc.lng;
      const childUid = sos.createdBy ?? "";

      // ✅ send using shared helper
      await sendSosPush({
        familyId: String(familyId),
        sosId: String(sosId),
        childUid: String(childUid),
        lat: lat != null ? Number(lat) : null,
        lng: lng != null ? Number(lng) : null,
      });

      // Enqueue tiếp
      await enqueueSosReminder({
        familyId: String(familyId),
        sosId: String(sosId),
        createdAtMs: Number(createdAtMs),
      });

      res.status(200).send("OK");
    } catch (e: any) {
      console.error("sosReminderWorker error:", e?.stack ?? e);
      res.status(500).send("ERR");
    }
  }
);

// =======================
// TOKEN REGISTRY (CALLABLE)
// =======================
export const registerFcmToken = onCall(
  { region: "asia-southeast1" },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

    const uid = req.auth.uid;
    const token = mustString(req.data?.token, "token");
    const platform = mustPlatform(req.data?.platform);

    if (token.length < 20) throw new HttpsError("invalid-argument", "token too short");

    const { familyId } = await getUserFamilyAndRole(uid);
    await requireFamilyMember(familyId, uid);

    const tokenHash = sha256Hex(token);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const userTokenRef = db.doc(`users/${uid}/fcmTokens/${tokenHash}`);
    const familyTokenRef = db.doc(`families/${familyId}/fcmTokens/${tokenHash}`);

    const batch = db.batch();
    batch.set(userTokenRef, { token, platform, familyId, updatedAt: now }, { merge: true });
    batch.set(familyTokenRef, { token, platform, uid, updatedAt: now }, { merge: true });
    await batch.commit();

    return { ok: true, tokenHash, familyId };
  }
);

export const unregisterFcmToken = onCall(
  { region: "asia-southeast1" },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

    const uid = req.auth.uid;
    const token = mustString(req.data?.token, "token");
    const tokenHash = sha256Hex(token);

    const { familyId } = await getUserFamilyAndRole(uid);

    const userTokenRef = db.doc(`users/${uid}/fcmTokens/${tokenHash}`);
    const familyTokenRef = db.doc(`families/${familyId}/fcmTokens/${tokenHash}`);

    const batch = db.batch();
    batch.delete(userTokenRef);
    batch.delete(familyTokenRef);
    await batch.commit();

    return { ok: true };
  }
);

// =======================
// CREATE SOS (CALLABLE) — FAST PATH
// =======================
export const createSos = onCall(
  { region: "asia-southeast1"},
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
    const uid = req.auth.uid;

    const eventId = mustString(req.data?.eventId, "eventId");
    const lat = mustNumber(req.data?.lat, "lat");
    const lng = mustNumber(req.data?.lng, "lng");
    const acc = req.data?.acc == null ? null : mustNumber(req.data?.acc, "acc");

    validateLatLng(lat, lng);

    const now = new Date();
    const dayKey = dayKeyInTZ(now, TZ);
    const nowTs = admin.firestore.Timestamp.now();

    const { familyId, role } = await getUserFamilyAndRole(uid);

    if (role !== "child" && role !== "parent") {
      throw new HttpsError("permission-denied", "Only family members can trigger SOS");
    }

    await requireFamilyMember(familyId, uid);

    const sosRef = db.doc(`families/${familyId}/sos/${eventId}`);
    const rateRef = db.doc(`families/${familyId}/rateLimits/sosDaily_${uid}_${dayKey}`);

    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(now.getTime() + RATE_DOC_TTL_DAYS * 24 * 60 * 60 * 1000)
    );

    const result = await db.runTransaction(async (tx) => {
      const existingSos = await tx.get(sosRef);
      if (existingSos.exists) {
        return { sosId: eventId, created: false, dayKey, limited: false };
      }

      const rateSnap = await tx.get(rateRef);
      const currentCount = rateSnap.exists ? ((rateSnap.get("count") as number) ?? 0) : 0;

      if (currentCount >= SOS_DAILY_LIMIT) {
        throw new HttpsError(
          "resource-exhausted",
          `Daily SOS limit reached (${SOS_DAILY_LIMIT}/day). dayKey=${dayKey}`
        );
      }

      const lastAt = rateSnap.exists
        ? (rateSnap.get("lastSosAt") as admin.firestore.Timestamp | undefined)
        : undefined;

      if (lastAt) {
        const deltaMs = nowTs.toMillis() - lastAt.toMillis();
        if (deltaMs < SOS_MIN_INTERVAL_SEC * 1000) {
          throw new HttpsError(
            "resource-exhausted",
            `SOS too frequent. Wait at least ${SOS_MIN_INTERVAL_SEC}s between SOS.`
          );
        }
      }

      if (rateSnap.exists) {
        tx.update(rateRef, {
          count: currentCount + 1,
          lastSosAt: nowTs,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt,
        });
      } else {
        tx.create(rateRef, {
          type: "sosDaily",
          uid,
          dayKey,
          count: 1,
          lastSosAt: nowTs,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt,
        });
      }

      tx.create(sosRef, {
        createdBy: uid,
        createdByRole: role,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "active",
        location: { lat, lng, acc },
        dayKey,
      });

      return { sosId: eventId, created: true, dayKey, limited: false };
    });

    // ✅ FAST PATH: push ngay tại đây (khỏi đợi trigger)
    if (result.created) {
      const pushRes = await sendSosPush({
        familyId,
        sosId: eventId,
        childUid: uid,
        lat,
        lng,
      });

      await sosRef.update({
        "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
        "fanout.attemptedRecipients": pushRes.attemptedRecipients,
        "fanout.success": pushRes.success,
        "fanout.invalidTokensRemoved": pushRes.invalidTokensRemoved,
      });

      await enqueueSosReminder({
        familyId,
        sosId: eventId,
        createdAtMs: Date.now(),
      });
    }

    return {
      ok: true,
      ...result,
      familyId,
      limitPerDay: SOS_DAILY_LIMIT,
      minIntervalSec: SOS_MIN_INTERVAL_SEC,
      timezone: TZ,
    };
  }
);

// =======================
// RESOLVE SOS
// =======================
export const resolveSos = onCall(
  { region: "asia-southeast1" },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
    const uid = req.auth.uid;

    const familyId = mustString(req.data?.familyId, "familyId");
    const sosId = mustString(req.data?.sosId, "sosId");

    await requireFamilyMember(familyId, uid);

    const ref = db.doc(`families/${familyId}/sos/${sosId}`);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new HttpsError("not-found", "SOS not found");
      const d = snap.data()!;
      if (d.status === "resolved") return;

      tx.update(ref, {
        status: "resolved",
        resolvedBy: uid,
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { ok: true };
  }
);

// =======================
// FIRESTORE TRIGGER: SOS CREATED (fallback)
// =======================
export const onSosCreated = onDocumentCreated(
  {
    document: "families/{familyId}/sos/{sosId}",
    region: "asia-southeast1",
    retry: true,

  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { familyId, sosId } = event.params as { familyId: string; sosId: string };
    const sos = snap.data() as any;

    const createdBy: string | undefined = sos.createdBy;
    const status: string | undefined = sos.status;
    const childUid = createdBy;

    if (!createdBy) return;

    const loc = sos.location ?? {};
    const lat = loc.lat;
    const lng = loc.lng;

    if (status !== "active") return;

    const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);

    // lock tránh duplicate send
    const CLAIM_LEASE_MS = 120_000;
    const claimId = randomUUID();
    const nowTs = admin.firestore.Timestamp.now();

    try {
      const shouldSend = await db.runTransaction(async (tx) => {
        const cur = await tx.get(sosRef);
        if (!cur.exists) return false;

        const d = cur.data() ?? {};
        const fanout = d.fanout ?? {};

        const sentAt: admin.firestore.Timestamp | undefined = fanout.sentAt;
        if (sentAt) return false; // ✅ createSos đã gửi rồi

        const claimedAt: admin.firestore.Timestamp | undefined = fanout.claimedAt;
        if (claimedAt) {
          const ageMs = nowTs.toMillis() - claimedAt.toMillis();
          if (ageMs < CLAIM_LEASE_MS) return false;
        }

        tx.update(sosRef, {
          "fanout.claimedAt": nowTs,
          "fanout.claimId": claimId,
          "fanout.attempted": admin.firestore.FieldValue.increment(1),
        });
        return true;
      });

      if (!shouldSend) return;

      const pushRes = await sendSosPush({
        familyId,
        sosId,
        childUid: String(childUid),
        lat: lat != null ? Number(lat) : null,
        lng: lng != null ? Number(lng) : null,
      });

      await sosRef.update({
        "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
        "fanout.attemptedRecipients": pushRes.attemptedRecipients,
        "fanout.success": pushRes.success,
        "fanout.invalidTokensRemoved": pushRes.invalidTokensRemoved,
        "fanout.claimedAt": admin.firestore.FieldValue.delete(),
        "fanout.claimId": admin.firestore.FieldValue.delete(),
      });

      await enqueueSosReminder({
        familyId,
        sosId,
        createdAtMs: Date.now(),
      });
    } catch (err: any) {
      console.error(`[SOS] ERROR familyId=${familyId} sosId=${sosId} claimId=${claimId}`);
      console.error(err?.stack ?? err);

      // clear claim để retry
      try {
        await sosRef.update({
          "fanout.claimedAt": admin.firestore.FieldValue.delete(),
          "fanout.claimId": admin.firestore.FieldValue.delete(),
          "fanout.lastError": String(err?.message ?? err),
          "fanout.lastErrorAt": admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch {}

      throw err;
    }
  }
);