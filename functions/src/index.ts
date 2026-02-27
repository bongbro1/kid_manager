import * as admin from "firebase-admin";
import { createHash, randomUUID } from "crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions/v2";

admin.initializeApp();
#$env:FUNCTIONS_DISCOVERY_TIMEOUT=30
#firebase deploy --only functions
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

    await admin.database().ref(`users/${uid}`).set({
      parentUid,
    });

    console.log(`Mirrored user ${uid} → RTDB`);
  }
);



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
    region: "asia-southeast1",
  },
  async (req) => {
    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

    const uid = req.auth.uid;
    console.log("AUTH:", req.auth);
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

export const unregisterFcmToken = onCall( {
    region: "asia-southeast1",
  },async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

  const uid = req.auth.uid;
  const token = mustString(req.data?.token, "token");
  const tokenHash = sha256Hex(token);
 console.log("AUTH:", req.auth);
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
export const createSos = onCall(
  { region: "asia-southeast1" },
  async (req) => {
    console.log("[createSos] invoked");
    console.log("[createSos] AUTH:", req.auth);

    if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
    const uid = req.auth.uid;

    const eventId = mustString(req.data?.eventId, "eventId");
    const lat = mustNumber(req.data?.lat, "lat");
    const lng = mustNumber(req.data?.lng, "lng");
    const acc = req.data?.acc == null ? null : mustNumber(req.data?.acc, "acc");

    console.log("[createSos] input", { uid, eventId, lat, lng, acc });

    validateLatLng(lat, lng);

    const now = new Date();
    const dayKey = dayKeyInTZ(now, TZ);
    const nowTs = admin.firestore.Timestamp.now();

    console.log("[createSos] before getUserFamilyAndRole");
    const { familyId, role } = await getUserFamilyAndRole(uid);
    console.log("[createSos] familyId/role", { familyId, role, dayKey });

    if (role !== "child") {
      console.log("[createSos] role not child -> deny");
      throw new HttpsError("permission-denied", "Only child can trigger SOS");
    }

    console.log("[createSos] before requireFamilyMember");
    await requireFamilyMember(familyId, uid);
    console.log("[createSos] member ok");

    const sosRef = db.doc(`families/${familyId}/sos/${eventId}`);
    const rateRef = db.doc(`families/${familyId}/rateLimits/sosDaily_${uid}_${dayKey}`);

    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(now.getTime() + RATE_DOC_TTL_DAYS * 24 * 60 * 60 * 1000)
    );

    console.log("[createSos] starting transaction", {
      sosPath: sosRef.path,
      ratePath: rateRef.path,
    });

    const result = await db.runTransaction(async (tx) => {
      console.log("[createSos] tx begin");

      const existingSos = await tx.get(sosRef);
      if (existingSos.exists) {
        console.log("[createSos] tx: sos already exists -> idempotent");
        return { sosId: eventId, created: false, dayKey, limited: false };
      }

      const rateSnap = await tx.get(rateRef);
      const currentCount = rateSnap.exists ? ((rateSnap.get("count") as number) ?? 0) : 0;

      console.log("[createSos] tx: currentCount", currentCount);

      if (currentCount >= SOS_DAILY_LIMIT) {
        console.log("[createSos] tx: DAILY LIMIT HIT", { currentCount, limit: SOS_DAILY_LIMIT });
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
        console.log("[createSos] tx: deltaMs", deltaMs);

        if (deltaMs < SOS_MIN_INTERVAL_SEC * 1000) {
          console.log("[createSos] tx: BURST LIMIT HIT", { deltaMs });
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
        childUid: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "active",
        location: { lat, lng, acc },
        dayKey,
      });

      console.log("[createSos] tx end -> will commit");
      return { sosId: eventId, created: true, dayKey, limited: false };
    });

    console.log("[createSos] transaction result", result);

    const response = {
      ok: true,
      ...result,
      familyId,
      limitPerDay: SOS_DAILY_LIMIT,
      minIntervalSec: SOS_MIN_INTERVAL_SEC,
      timezone: TZ,
    };

    console.log("[createSos] response", response);
    return response;
  }
);

// =======================
// FIRESTORE TRIGGER: SOS CREATED -> FANOUT PUSH
// - idempotent lease lock (avoid double send)
// - chunk <= 500 tokens per multicast
// - cleanup invalid tokens
// =======================
export const onSosCreated = onDocumentCreated(
  {
    document: "families/{familyId}/sos/{sosId}",
    region: "asia-southeast1",
    retry: true,
  },
console.log("[SOS] INVOKED", JSON.stringify(event.params));
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("[SOS] event.data is null -> skip");
      return;
    }

    const { familyId, sosId } = event.params as { familyId: string; sosId: string };
    const sos = snap.data() as any;

    const childUid: string | undefined = sos.childUid;
    const status: string = sos.status ?? "active";
    const loc = sos.location ?? {};
    const lat = loc.lat;
    const lng = loc.lng;

    console.log(`[SOS] TRIGGERED familyId=${familyId} sosId=${sosId}`);
    console.log(`[SOS] payload childUid=${childUid ?? "null"} status=${status} lat=${lat ?? "null"} lng=${lng ?? "null"}`);

    if (!childUid) {
      console.log("[SOS] Missing childUid -> skip");
      return;
    }
    if (status !== "active") {
      console.log(`[SOS] status=${status} (not active) -> skip`);
      return;
    }

    const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);

    // ====== IDP LOCK (avoid duplicate fanout)
    const CLAIM_LEASE_MS = 120_000; // 2 phút
    const claimId = randomUUID();
    const nowTs = admin.firestore.Timestamp.now();

    try {
      const shouldSend = await db.runTransaction(async (tx) => {
        const cur = await tx.get(sosRef);
        const d = cur.data() ?? {};
        const fanout = d.fanout ?? {};

        const sentAt: admin.firestore.Timestamp | undefined = fanout.sentAt;
        if (sentAt) {
          console.log(`[SOS] Already sent at ${sentAt.toDate().toISOString()} -> skip`);
          return false;
        }

        const claimedAt: admin.firestore.Timestamp | undefined = fanout.claimedAt;
        const prevClaimId: string | undefined = fanout.claimId;

        if (claimedAt) {
          const ageMs = nowTs.toMillis() - claimedAt.toMillis();
          if (ageMs < CLAIM_LEASE_MS) {
            console.log(`[SOS] Already claimed by ${prevClaimId ?? "unknown"} ageMs=${ageMs} -> skip`);
            return false;
          }
          console.log(`[SOS] Previous claim expired (ageMs=${ageMs}), taking over...`);
        }

        tx.update(sosRef, {
          "fanout.claimedAt": nowTs,
          "fanout.claimId": claimId,
          "fanout.attempted": admin.firestore.FieldValue.increment(1),
        });

        console.log(`[SOS] Claimed fanout claimId=${claimId}`);
        return true;
      });

      if (!shouldSend) return;

      // ===== fetch tokens under family
      const tokenSnap = await db.collection(`families/${familyId}/fcmTokens`).get();
      console.log(`[SOS] family tokens docs=${tokenSnap.size}`);

      const tokens: Array<{ token: string; tokenHash: string; uid: string; platform?: string }> = [];
      tokenSnap.forEach((doc) => {
        const data = doc.data() as any;
        const token: string | undefined = data.token;
        const uid: string | undefined = data.uid;
        if (!token || !uid) return;

        if (uid === childUid) return; // không gửi cho chính bé
        tokens.push({ token, tokenHash: doc.id, uid, platform: data.platform });
      });

      console.log(`[SOS] usableTokens=${tokens.length} (excluded childUid=${childUid})`);

      if (!tokens.length) {
        console.log("[SOS] No tokens to send -> mark sentAt with 0 recipients");
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
      console.log(`[SOS] Sending in chunks=${tokenChunks.length}`);

      let success = 0;
      let invalidRemoved = 0;
      let totalAttempt = 0;

      for (let idx = 0; idx < tokenChunks.length; idx++) {
        const c = tokenChunks[idx];
        totalAttempt += c.length;

        console.log(`[SOS] Chunk ${idx + 1}/${tokenChunks.length} size=${c.length}`);

        const multicast: admin.messaging.MulticastMessage = {
          ...baseMessage,
          tokens: c.map((x) => x.token),
        };

        const resp = await admin.messaging().sendEachForMulticast(multicast);
        console.log(
          `[SOS] Chunk ${idx + 1} result success=${resp.successCount} failure=${resp.failureCount}`
        );

        success += resp.successCount;

        // cleanup invalid tokens
        const batch = db.batch();
        let hasDeletes = false;
        let chunkInvalid = 0;

        resp.responses.forEach((r, i) => {
          if (r.success) return;
          const err = r.error as any;
          const code: string | undefined = err?.code;

          // log lỗi 1-2 cái đầu để debug (tránh spam)
          if (i < 2) {
            console.log(`[SOS] Fail sample i=${i} code=${code ?? "unknown"} msg=${err?.message ?? ""}`);
          }

          if (isInvalidTokenErrorCode(code)) {
            const meta = c[i];
            invalidRemoved++;
            chunkInvalid++;

            batch.delete(db.doc(`families/${familyId}/fcmTokens/${meta.tokenHash}`));
            batch.delete(db.doc(`users/${meta.uid}/fcmTokens/${meta.tokenHash}`));
            hasDeletes = true;
          }
        });

        if (hasDeletes) {
          await batch.commit();
          console.log(`[SOS] Chunk ${idx + 1} removed invalid tokens=${chunkInvalid}`);
        }
      }

      await sosRef.update({
        "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
        "fanout.attemptedRecipients": totalAttempt,
        "fanout.success": success,
        "fanout.invalidTokensRemoved": invalidRemoved,
        "fanout.claimedAt": admin.firestore.FieldValue.delete(),
        "fanout.claimId": admin.firestore.FieldValue.delete(),
      });

      console.log(
        `[SOS] DONE familyId=${familyId} sosId=${sosId} attempted=${totalAttempt} success=${success} invalidRemoved=${invalidRemoved}`
      );
    } catch (err: any) {
      console.error(`[SOS] ERROR familyId=${familyId} sosId=${sosId} claimId=${claimId}`);
      console.error(err?.stack ?? err);

      // best-effort: bỏ claim để instance khác retry
      try {
        await sosRef.update({
          "fanout.claimedAt": admin.firestore.FieldValue.delete(),
          "fanout.claimId": admin.firestore.FieldValue.delete(),
          "fanout.lastError": String(err?.message ?? err),
          "fanout.lastErrorAt": admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (e) {
        console.error("[SOS] Failed to clear claim / write lastError", e);
      }

      // throw để retry=true có tác dụng
      throw err;
    }
  }
);