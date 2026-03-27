import { randomUUID } from "crypto";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { OAuth2Client } from "google-auth-library";
import { admin, db } from "../bootstrap";
import {
REGION,
TZ,
SOS_DAILY_LIMIT,
SOS_MIN_INTERVAL_SEC,
RATE_DOC_TTL_DAYS,
REMIND_MAX_SECONDS,
getSosReminderRuntimeConfig,
} from "../config";
import {
mustString,
mustNumber,
dayKeyInTZ,
validateLatLng,
} from "../helpers";
import { getUserFamilyAndRole, requireFamilyActor } from "../services/user";
import { sendSosPush } from "../services/sosPush";
import { enqueueSosReminder } from "../services/tasks";

const REMINDER_LEASE_MS = 120_000;
const WORKER_MIN_INTERVAL_MS = 5_000;
const ALLOWED_OIDC_ISSUERS = new Set([
  "accounts.google.com",
  "https://accounts.google.com",
]);
const oidcClient = new OAuth2Client();

const sosReminderWorkerOptions = { region: REGION, invoker: "private" as const };

function parseFiniteNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }

  return null;
}

async function verifyReminderWorkerRequest(req: any): Promise<{
  ok: boolean;
  status: number;
  message: string;
}> {
  const runtimeConfig = getSosReminderRuntimeConfig();

  if (!runtimeConfig.taskCallerServiceAccount || !runtimeConfig.workerUrl) {
    console.error("[SOS] Worker auth is not configured");
    return {
      ok: false,
      status: 500,
      message: "Worker auth misconfigured",
    };
  }

  const authHeader = String(req.header("authorization") ?? "").trim();
  if (!authHeader.startsWith("Bearer ")) {
    return { ok: false, status: 401, message: "Missing bearer token" };
  }

  const idToken = authHeader.slice("Bearer ".length).trim();
  if (!idToken) {
    return { ok: false, status: 401, message: "Missing bearer token" };
  }

  try {
    const ticket = await oidcClient.verifyIdToken({
      idToken,
      audience: runtimeConfig.workerUrl,
    });
    const payload = ticket.getPayload();

    if (!payload) {
      return { ok: false, status: 401, message: "Invalid bearer token" };
    }

    const issuer = String(payload.iss ?? "");
    if (!ALLOWED_OIDC_ISSUERS.has(issuer)) {
      return { ok: false, status: 403, message: "Invalid token issuer" };
    }

    const email = String(payload.email ?? "").trim().toLowerCase();
    const expectedEmail = runtimeConfig.taskCallerServiceAccount.toLowerCase();
    const emailVerified =
      payload.email_verified === undefined || payload.email_verified === true;

    if (!emailVerified || email !== expectedEmail) {
      return { ok: false, status: 403, message: "Invalid task caller" };
    }

    return { ok: true, status: 200, message: "OK" };
  } catch (err: any) {
    console.error("[SOS] verifyReminderWorkerRequest error:", err?.stack ?? err);
    return { ok: false, status: 401, message: "Invalid bearer token" };
  }
}

async function claimReminderAttempt(params: {
  familyId: string;
  sosId: string;
  attempt: number;
  taskName: string;
}) {
  const { familyId, sosId, attempt, taskName } = params;
  const sosRef = db.doc(`families/${familyId}/sos/${sosId}`);
  const nowMs = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(sosRef);
    if (!snap.exists) {
      return { action: "skip" as const, reason: "SOS not found", sosRef, sos: null };
    }

    const sos = snap.data() as any;
    if (sos.status !== "active") {
      return { action: "skip" as const, reason: "SOS not active, stop", sosRef, sos };
    }

    const reminder = sos.reminder ?? {};
    const lastAttempt = Number(reminder.lastAttempt ?? 0);
    if (lastAttempt >= attempt) {
      return {
        action: "skip" as const,
        reason: `Attempt ${attempt} already processed`,
        sosRef,
        sos,
      };
    }

    const lastSentAt = reminder.lastSentAt as admin.firestore.Timestamp | undefined;
    if (lastSentAt) {
      const deltaMs = nowMs - lastSentAt.toMillis();
      if (deltaMs < WORKER_MIN_INTERVAL_MS) {
        return {
          action: "skip" as const,
          reason: "Reminder rate limited",
          sosRef,
          sos,
        };
      }
    }

    const leaseAttempt = Number(reminder.workerLeaseAttempt ?? 0);
    const leaseAt = reminder.workerLeaseAt as admin.firestore.Timestamp | undefined;
    if (leaseAttempt === attempt && leaseAt) {
      const leaseAgeMs = nowMs - leaseAt.toMillis();
      if (leaseAgeMs < REMINDER_LEASE_MS) {
        return {
          action: "skip" as const,
          reason: `Attempt ${attempt} already claimed`,
          sosRef,
          sos,
        };
      }
    }

    tx.set(
      sosRef,
      {
        reminder: {
          workerLeaseAttempt: attempt,
          workerLeaseTaskName: taskName || null,
          workerLeaseAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
      },
      { merge: true }
    );

    return { action: "process" as const, reason: "claimed", sosRef, sos };
  });
}

async function ensureNextReminder(params: {
  familyId: string;
  sosId: string;
  createdAtMs: number;
  currentAttempt: number;
  sosRef: FirebaseFirestore.DocumentReference;
  sos: any;
}) {
  const { familyId, sosId, createdAtMs, currentAttempt, sosRef, sos } = params;
  const reminder = sos?.reminder ?? {};
  const lastAttempt = Number(reminder.lastAttempt ?? 0);
  const nextAttemptStored = Number(reminder.nextAttempt ?? 0);
  const nextAttempt = currentAttempt + 1;

  if (lastAttempt !== currentAttempt || nextAttemptStored >= nextAttempt) {
    return false;
  }

  const enqueueRes = await enqueueSosReminder({
    familyId,
    sosId,
    createdAtMs,
    attempt: nextAttempt,
  });

  await sosRef.set(
    {
      reminder: {
        nextAttempt:
          enqueueRes && enqueueRes.enqueued ? nextAttempt : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    { merge: true }
  );

  return enqueueRes?.enqueued === true;
}

// WORKER
export const sosReminderWorker = onRequest(
  sosReminderWorkerOptions,
  async (req, res) => {
    let claimedSosRef: FirebaseFirestore.DocumentReference | null = null;

    try {
      if (req.method !== "POST") {
        return void res.status(405).send("Method not allowed");
      }

      const auth = await verifyReminderWorkerRequest(req);
      if (!auth.ok) {
        return void res.status(auth.status).send(auth.message);
      }

      const rawBody = req.body ?? {};
      const familyId =
        typeof rawBody.familyId === "string" ? rawBody.familyId.trim() : "";
      const sosId = typeof rawBody.sosId === "string" ? rawBody.sosId.trim() : "";
      const createdAtMs = parseFiniteNumber(rawBody.createdAtMs);
      const currentAttempt = parseFiniteNumber(rawBody.attempt);

      if (
        !familyId ||
        !sosId ||
        createdAtMs == null ||
        currentAttempt == null ||
        !Number.isInteger(currentAttempt) ||
        currentAttempt <= 0
      ) {
        return void res.status(400).send("Missing params");
      }

      const ageSec = (Date.now() - createdAtMs) / 1000;
      if (ageSec > REMIND_MAX_SECONDS) {
        return void res.status(200).send("Expired reminder window");
      }

      const taskName = String(req.header("X-CloudTasks-TaskName") ?? "").trim();
      const claim = await claimReminderAttempt({
        familyId,
        sosId,
        attempt: currentAttempt,
        taskName,
      });

      if (claim.action !== "process") {
        if (claim.sosRef && claim.sos) {
          await ensureNextReminder({
            familyId,
            sosId,
            createdAtMs,
            currentAttempt,
            sosRef: claim.sosRef,
            sos: claim.sos,
          });
        }
        return void res.status(200).send(claim.reason);
      }

      claimedSosRef = claim.sosRef;
      const sos = claim.sos ?? {};
      const loc = sos.location ?? {};
      const childUid = sos.createdBy ?? "";
      const createdByName = sos.createdByName ?? "";

      const pushRes = await sendSosPush({
        familyId,
        sosId,
        createdByUid: String(childUid),
        lat: loc.lat != null ? Number(loc.lat) : null,
        lng: loc.lng != null ? Number(loc.lng) : null,
        createdByName: String(createdByName),
        attempt: currentAttempt,
      });

      await claimedSosRef.set(
        {
          reminder: {
            lastAttempt: currentAttempt,
            lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
            lastSuccess: pushRes.success,
            lastTaskName: taskName || null,
            workerLeaseAttempt: admin.firestore.FieldValue.delete(),
            workerLeaseTaskName: admin.firestore.FieldValue.delete(),
            workerLeaseAt: admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );

      const nextAttempt = currentAttempt + 1;
      const enqueueRes = await enqueueSosReminder({
        familyId,
        sosId,
        createdAtMs,
        attempt: nextAttempt,
      });

      await claimedSosRef.set(
        {
          reminder: {
            nextAttempt:
              enqueueRes && enqueueRes.enqueued ? nextAttempt : null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );

      return void res.status(200).send("OK");
    } catch (e: any) {
      if (claimedSosRef) {
        try {
          await claimedSosRef.set(
            {
              reminder: {
                workerLeaseAttempt: admin.firestore.FieldValue.delete(),
                workerLeaseTaskName: admin.firestore.FieldValue.delete(),
                workerLeaseAt: admin.firestore.FieldValue.delete(),
                lastError: String(e?.message ?? e),
                lastErrorAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              },
            },
            { merge: true }
          );
        } catch {}
      }

      console.error("sosReminderWorker error:", e?.stack ?? e);
      return void res.status(500).send("ERR");
    }
  }
);

// CREATE SOS
export const createSos = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }
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
    typeof createdByNameRaw === "string"
      ? createdByNameRaw.trim().slice(0, 80)
      : "";

  await requireFamilyActor({
    familyId,
    uid,
    allowedRoles: ["child", "parent", "guardian"],
  });

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
    const currentCount = rateSnap.exists
      ? ((rateSnap.get("count") as number) ?? 0)
      : 0;

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
      createdByName,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "active",
      location: { lat, lng, acc },
      dayKey,
      reminder: {
        initialPushSent: false,
        lastAttempt: 0,
      },
    });

    return { sosId: eventId, created: true, dayKey, limited: false };
  });

  return {
    ok: true,
    ...result,
    familyId,
    debugVersion: "createSos-v2026-03-14-01",
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
  if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }
  const uid = req.auth.uid;

  const familyId = mustString(req.data?.familyId, "familyId");
  const sosId = mustString(req.data?.sosId, "sosId");

  await requireFamilyActor({
    familyId,
    uid,
    allowedRoles: ["parent", "guardian"],
  });

  const ref = db.doc(`families/${familyId}/sos/${sosId}`);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "SOS not found");
    }
    if (snap.data()!.status === "resolved") {
      return;
    }

    tx.update(ref, {
      status: "resolved",
      resolvedBy: uid,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      "reminder.stoppedAt": admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

// FALLBACK TRIGGER
export const onSosCreated = onDocumentCreated(
  {
    document: "families/{familyId}/sos/{sosId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const { familyId, sosId } = event.params as {
      familyId: string;
      sosId: string;
    };

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
        createdByUid: String(createdBy),
        lat: loc.lat != null ? Number(loc.lat) : null,
        lng: loc.lng != null ? Number(loc.lng) : null,
        createdByName: sos.createdByName ?? "",
        attempt: 0,
      });

      await sosRef.update({
        "fanout.sentAt": admin.firestore.FieldValue.serverTimestamp(),
        "fanout.attemptedRecipients": pushRes.attemptedRecipients,
        "fanout.success": pushRes.success,
        "fanout.invalidTokensRemoved": pushRes.invalidTokensRemoved,
        "fanout.claimedAt": admin.firestore.FieldValue.delete(),
        "fanout.claimId": admin.firestore.FieldValue.delete(),
        "reminder.initialPushSent": true,
        "reminder.lastAttempt": 0,
        "reminder.lastSentAt": admin.firestore.FieldValue.serverTimestamp(),
      });

      await enqueueSosReminder({
        familyId,
        sosId,
        createdAtMs: Date.now(),
        attempt: 1,
      });

      await sosRef.set(
        {
          reminder: {
            nextAttempt: 1,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        { merge: true }
      );
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
