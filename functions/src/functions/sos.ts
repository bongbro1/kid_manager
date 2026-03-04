import { randomUUID } from "crypto";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin, db } from "../bootstrap";
import { REGION, TZ, SOS_DAILY_LIMIT, SOS_MIN_INTERVAL_SEC, RATE_DOC_TTL_DAYS, REMIND_MAX_SECONDS } from "../config";
import { mustString, mustNumber, dayKeyInTZ, validateLatLng } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";
import { sendSosPush } from "../services/sosPush";
import { enqueueSosReminder } from "../services/tasks";

// WORKER
export const sosReminderWorker = onRequest({ region: REGION }, async (req, res) => {
try {
if (req.method !== "POST") return void res.status(405).send("Method not allowed");

    const { familyId, sosId, createdAtMs } = req.body ?? {};
    if (!familyId || !sosId || !createdAtMs) return void res.status(400).send("Missing params");

    const ageSec = (Date.now() - Number(createdAtMs)) / 1000;
    if (ageSec > REMIND_MAX_SECONDS) return void res.status(200).send("Expired reminder window");

    const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);
    const snap = await sosRef.get();
    if (!snap.exists) return void res.status(200).send("SOS not found");

    const sos = snap.data() as any;
    if (sos.status !== "active") return void res.status(200).send("SOS not active, stop");

    const loc = sos.location ?? {};
    const childUid = sos.createdBy ?? "";
    const createdByName = sos.createdByName ?? "";

    await sendSosPush({
      familyId: String(familyId),
      sosId: String(sosId),
      childUid: String(childUid),
      lat: loc.lat != null ? Number(loc.lat) : null,
      lng: loc.lng != null ? Number(loc.lng) : null,
      createdByName: String(createdByName),
    });

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
});

// CREATE SOS
export const createSos = onCall({ region: REGION }, async (req) => {
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

  const createdByNameRaw = req.data?.createdByName;
  const createdByName =
    typeof createdByNameRaw === "string" ? createdByNameRaw.trim().slice(0, 80) : "";

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
    if (existingSos.exists) return { sosId: eventId, created: false, dayKey, limited: false };

    const rateSnap = await tx.get(rateRef);
    const currentCount = rateSnap.exists ? ((rateSnap.get("count") as number) ?? 0) : 0;

    if (currentCount >= SOS_DAILY_LIMIT) {
      throw new HttpsError("resource-exhausted", `Daily SOS limit reached (${SOS_DAILY_LIMIT}/day). dayKey=${dayKey}`);
    }

    const lastAt = rateSnap.exists
      ? (rateSnap.get("lastSosAt") as admin.firestore.Timestamp | undefined)
      : undefined;

    if (lastAt) {
      const deltaMs = nowTs.toMillis() - lastAt.toMillis();
      if (deltaMs < SOS_MIN_INTERVAL_SEC * 1000) {
        throw new HttpsError("resource-exhausted", `SOS too frequent. Wait at least ${SOS_MIN_INTERVAL_SEC}s between SOS.`);
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
      createdByName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "active",
      location: { lat, lng, acc },
      dayKey,
    });

    return { sosId: eventId, created: true, dayKey, limited: false };
  });

  if (result.created) {
    const pushRes = await sendSosPush({ familyId, sosId: eventId, childUid: uid, lat, lng, createdByName });

    await sosRef.update({
      "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
      "fanout.attemptedRecipients": pushRes.attemptedRecipients,
      "fanout.success": pushRes.success,
      "fanout.invalidTokensRemoved": pushRes.invalidTokensRemoved,
    });

    await enqueueSosReminder({ familyId, sosId: eventId, createdAtMs: Date.now() });
  }

  return {
    ok: true,
    ...result,
    familyId,
    debugVersion: "createSos-v2026-03-02-01",
    createdByNameEcho: createdByName,
    createdByNameRawEcho: req.data?.createdByName ?? null,
    keysEcho: Object.keys(req.data ?? {}),
    limitPerDay: SOS_DAILY_LIMIT,
    minIntervalSec: SOS_MIN_INTERVAL_SEC,
    timezone: TZ,
  };
});

// RESOLVE
export const resolveSos = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;

  const familyId = mustString(req.data?.familyId, "familyId");
  const sosId = mustString(req.data?.sosId, "sosId");

  await requireFamilyMember(familyId, uid);

  const ref = db.doc(`families/${familyId}/sos/${sosId}`);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError("not-found", "SOS not found");
    if (snap.data()!.status === "resolved") return;

    tx.update(ref, {
      status: "resolved",
      resolvedBy: uid,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

// FALLBACK TRIGGER
export const onSosCreated = onDocumentCreated(
  { document: "families/{familyId}/sos/{sosId}", region: REGION, retry: true },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { familyId, sosId } = event.params as { familyId: string; sosId: string };
    const sos = snap.data() as any;

    const createdBy: string | undefined = sos.createdBy;
    if (!createdBy) return;
    if (sos.status !== "active") return;

    const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);

    const CLAIM_LEASE_MS = 120_000;
    const claimId = randomUUID();
    const nowTs = admin.firestore.Timestamp.now();

    try {
      const shouldSend = await db.runTransaction(async (tx) => {
        const cur = await tx.get(sosRef);
        if (!cur.exists) return false;

        const d = cur.data() ?? {};
        const fanout = d.fanout ?? {};

        if (fanout.sentAt) return false;

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

      const loc = sos.location ?? {};
      const pushRes = await sendSosPush({
        familyId,
        sosId,
        childUid: String(createdBy),
        lat: loc.lat != null ? Number(loc.lat) : null,
        lng: loc.lng != null ? Number(loc.lng) : null,
      });

      await sosRef.update({
        "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
        "fanout.attemptedRecipients": pushRes.attemptedRecipients,
        "fanout.success": pushRes.success,
        "fanout.invalidTokensRemoved": pushRes.invalidTokensRemoved,
        "fanout.claimedAt": admin.firestore.FieldValue.delete(),
        "fanout.claimId": admin.firestore.FieldValue.delete(),
      });

      await enqueueSosReminder({ familyId, sosId, createdAtMs: Date.now() });
    } catch (err: any) {
      console.error(`[SOS] ERROR familyId=${familyId} sosId=${sosId} claimId=${claimId}`);
      console.error(err?.stack ?? err);

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