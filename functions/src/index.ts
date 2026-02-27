import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

export const mirrorUserToRtdb = functions.firestore
  .document("users/{uid}")
  .onCreate(async (snap, context) => {

    const data = snap.data();
    const uid = context.params.uid;

    const parentUid = data.parentUid || null;

    await admin.database()
      .ref(`users/${uid}`)
      .set({
        parentUid: parentUid,
      });

    console.log(`Mirrored user ${uid} → RTDB`);
  });


import * as admin from "firebase-admin";
import { createHash, randomUUID } from "crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({
  region: "asia-southeast1", // gần VN (Singapore)
});

// =======================
// CONFIG
// =======================
const TZ = "Asia/Ho_Chi_Minh";

// Limit SOS per child per day
const SOS_DAILY_LIMIT = 20;

// Burst limit: tối thiểu X giây giữa 2 SOS của cùng 1 child
const SOS_MIN_INTERVAL_SEC = 10;

// TTL optional: giữ rate limit docs bao lâu rồi tự dọn (Firestore TTL)
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
    throw new HttpsError("invalid-argument", "platform must be 'android' or 'ios'");
  }
  return v;
}

function validateLatLng(lat: number, lng: number) {
  if (lat < -90 || lat > 90) throw new HttpsError("invalid-argument", "lat out of range");
  if (lng < -180 || lng > 180) throw new HttpsError("invalid-argument", "lng out of range");
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

async function getUserFamilyAndRole(uid: string): Promise<{ familyId: string; role: string }> {
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

async function requireFamilyMember(familyId: string, uid: string) {
  const memberRef = db.doc(`families/${familyId}/members/${uid}`);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists) throw new HttpsError("permission-denied", "Not a family member");
  return memberSnap.data() ?? {};
}

// =======================
// TOKEN REGISTRY (CALLABLE)
// =======================
export const registerFcmToken = onCall(
  {
    // production khuyến nghị bật AppCheck khi bạn setup xong
    // enforceAppCheck: true,
  },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

    const uid = req.auth.uid;
    const token = mustString(req.data?.token, "token");
    const platform = mustPlatform(req.data?.platform);

    // sanity
    if (token.length < 20) throw new HttpsError("invalid-argument", "token too short");

    const { familyId } = await getUserFamilyAndRole(uid);

    // đảm bảo là member thật
    await requireFamilyMember(familyId, uid);

    const tokenHash = sha256Hex(token);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const userTokenRef = db.doc(`users/${uid}/fcmTokens/${tokenHash}`);
    const familyTokenRef = db.doc(`families/${familyId}/fcmTokens/${tokenHash}`);

    const batch = db.batch();
    batch.set(
      userTokenRef,
      { token, platform, familyId, updatedAt: now },
      { merge: true }
    );
    batch.set(
      familyTokenRef,
      { token, platform, uid, updatedAt: now },
      { merge: true }
    );
    await batch.commit();

    return { ok: true, tokenHash, familyId };
  }
);

export const unregisterFcmToken = onCall(async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

  const uid = req.auth.uid;
  const token = mustString(req.data?.token, "token");
  const tokenHash = sha256Hex(token);

  const { familyId } = await getUserFamilyAndRole(uid);

  // best-effort delete
  const userTokenRef = db.doc(`users/${uid}/fcmTokens/${tokenHash}`);
  const familyTokenRef = db.doc(`families/${familyId}/fcmTokens/${tokenHash}`);

  const batch = db.batch();
  batch.delete(userTokenRef);
  batch.delete(familyTokenRef);
  await batch.commit();

  return { ok: true };
});

// =======================
// CREATE SOS (CALLABLE) — PRODUCTION LIMITS
// - daily limit: 20 / day / child
// - burst limit: >= 10s between SOS
// - idempotent: eventId as docId
// =======================
export const createSos = onCall(async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;

  const eventId = mustString(req.data?.eventId, "eventId"); // UUID v4 from client
  const lat = mustNumber(req.data?.lat, "lat");
  const lng = mustNumber(req.data?.lng, "lng");
  const acc = req.data?.acc == null ? null : mustNumber(req.data?.acc, "acc");

  validateLatLng(lat, lng);

  const now = new Date();
  const dayKey = dayKeyInTZ(now, TZ);
  const nowTs = admin.firestore.Timestamp.now();

  const { familyId, role } = await getUserFamilyAndRole(uid);
  if (role !== "child") throw new HttpsError("permission-denied", "Only child can trigger SOS");

  await requireFamilyMember(familyId, uid);

  const sosRef = db.doc(`families/${familyId}/sos/${eventId}`);
  const rateRef = db.doc(`families/${familyId}/rateLimits/sosDaily_${uid}_${dayKey}`);

  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(now.getTime() + RATE_DOC_TTL_DAYS * 24 * 60 * 60 * 1000)
  );

  const result = await db.runTransaction(async (tx) => {
    // Idempotency: nếu SOS đã tồn tại -> return luôn, không trừ quota lại
    const existingSos = await tx.get(sosRef);
    if (existingSos.exists) {
      return { sosId: eventId, created: false, dayKey, limited: false };
    }

    const rateSnap = await tx.get(rateRef);

    const currentCount = rateSnap.exists ? (rateSnap.get("count") as number ?? 0) : 0;
    if (currentCount >= SOS_DAILY_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        `Daily SOS limit reached (${SOS_DAILY_LIMIT}/day). dayKey=${dayKey}`
      );
    }

    // Burst limit
    const lastAt = rateSnap.exists ? (rateSnap.get("lastSosAt") as admin.firestore.Timestamp | undefined) : undefined;
    if (lastAt) {
      const deltaSec = nowTs.toMillis() - lastAt.toMillis();
      if (deltaSec < SOS_MIN_INTERVAL_SEC * 1000) {
        throw new HttpsError(
          "resource-exhausted",
          `SOS too frequent. Wait at least ${SOS_MIN_INTERVAL_SEC}s between SOS.`
        );
      }
    }

    // update rate doc
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

    // create SOS doc
    tx.create(sosRef, {
      childUid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "active",
      location: { lat, lng, acc },
      dayKey,
    });

    return { sosId: eventId, created: true, dayKey, limited: false };
  });

  return {
    ok: true,
    ...result,
    familyId,
    limitPerDay: SOS_DAILY_LIMIT,
    minIntervalSec: SOS_MIN_INTERVAL_SEC,
    timezone: TZ,
  };
});

// =======================
// FIRESTORE TRIGGER: SOS CREATED -> FANOUT PUSH
// - idempotent lease lock (avoid double send)
// - chunk <= 500 tokens per multicast
// - cleanup invalid tokens
// =======================
export const onSosCreated = onDocumentCreated(
  {
    document: "families/{familyId}/sos/{sosId}",
    retry: true,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { familyId, sosId } = event.params as { familyId: string; sosId: string };
    const sos = snap.data() as any;

    const childUid: string | undefined = sos.childUid;
    const status: string = sos.status ?? "active";
    const loc = sos.location ?? {};
    const lat = loc.lat;
    const lng = loc.lng;

    if (!childUid) return;
    if (status !== "active") return;

    const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);

    // ===== idempotent lease lock
    const CLAIM_LEASE_MS = 120_000;
    const claimId = randomUUID();
    const nowTs = admin.firestore.Timestamp.now();

    const shouldSend = await db.runTransaction(async (tx) => {
      const cur = await tx.get(sosRef);
      const d = cur.data() ?? {};
      const fanout = d.fanout ?? {};

      const sentAt: admin.firestore.Timestamp | undefined = fanout.sentAt;
      if (sentAt) return false;

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

    // ===== fetch tokens under family
    const tokenSnap = await db.collection(`families/${familyId}/fcmTokens`).get();

    const tokens: Array<{ token: string; tokenHash: string; uid: string; platform?: string }> = [];
    tokenSnap.forEach((doc) => {
      const data = doc.data() as any;
      const token: string | undefined = data.token;
      const uid: string | undefined = data.uid;
      if (!token || !uid) return;

      // gửi tất cả members; thường bỏ bé để khỏi tự nhận
      if (uid === childUid) return;

      tokens.push({ token, tokenHash: doc.id, uid, platform: data.platform });
    });

    if (!tokens.length) {
      await sosRef.update({
        "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
        "fanout.success": 0,
        "fanout.attemptedRecipients": 0,
        "fanout.invalidTokensRemoved": 0,
        "fanout.claimedAt": admin.firestore.FieldValue.delete(),
        "fanout.claimId": admin.firestore.FieldValue.delete(),
      });
      return;
    }

    const baseMessage: Omit<admin.messaging.MulticastMessage, "tokens"> = {
      notification: {
        title: "🚨 SOS KHẨN CẤP",
        body: "Có thành viên đang cầu cứu. Chạm để xem vị trí.",
      },
      data: {
        type: "SOS",
        familyId,
        sosId,
        childUid,
        lat: lat != null ? String(lat) : "",
        lng: lng != null ? String(lng) : "",
      },
      android: {
        priority: "high",
        collapseKey: `sos_${sosId}`,
        notification: {
          channelId: "sos_channel",
          sound: "sos", // res/raw/sos.mp3
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
        payload: {
          aps: {
            sound: "sos.caf",
          },
        },
      },
    };

    const tokenChunks = chunk(tokens, 500);

    let success = 0;
    let invalidRemoved = 0;

    for (const c of tokenChunks) {
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

    await sosRef.update({
      "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
      "fanout.attemptedRecipients": tokens.length,
      "fanout.success": success,
      "fanout.invalidTokensRemoved": invalidRemoved,
      "fanout.claimedAt": admin.firestore.FieldValue.delete(),
      "fanout.claimId": admin.firestore.FieldValue.delete(),
    });
  }
);