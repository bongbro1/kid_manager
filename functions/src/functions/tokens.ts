import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../bootstrap";
import { REGION } from "../config";
import { mustPlatform, mustString } from "../helpers";
import { getFcmInstallationRef } from "../services/fcmInstallations";
import { db } from "../bootstrap";
import { requireFamilyMember } from "../services/user";

export const registerFcmToken = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

  const uid = req.auth.uid;
  const installationId = mustString(
    req.data?.installationId,
    "installationId"
  ).trim();
  const token = mustString(req.data?.token, "token");
  const platform = mustPlatform(req.data?.platform);

  if (installationId.length < 8) {
    throw new HttpsError("invalid-argument", "installationId too short");
  }
  if (token.length < 20) {
    throw new HttpsError("invalid-argument", "token too short");
  }

  const userSnap = await db.doc(`users/${uid}`).get();
  if (!userSnap.exists) {
    throw new HttpsError("failed-precondition", "User profile not found");
  }

  const userData = userSnap.data() ?? {};
  const rawFamilyId =
    typeof userData.familyId === "string" ? userData.familyId.trim() : "";
  let familyId: string | null = rawFamilyId || null;

  if (familyId) {
    const familySnap = await db.doc(`families/${familyId}`).get();
    if (!familySnap.exists) {
      console.warn("[registerFcmToken] skip family binding because family is missing", {
        uid,
        familyId,
      });
      familyId = null;
    } else {
      await requireFamilyMember(familyId, uid);
    }
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  await getFcmInstallationRef(installationId).set({
    installationId,
    token,
    uid,
    familyId,
    platform,
    updatedAt: now,
    lastSeenAt: now,
  });

  return { ok: true, installationId, familyId };
});

export const unregisterFcmToken = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

  const uid = req.auth.uid;
  const installationId = mustString(
    req.data?.installationId,
    "installationId"
  ).trim();

  if (installationId.length < 8) {
    throw new HttpsError("invalid-argument", "installationId too short");
  }

  const installationRef = getFcmInstallationRef(installationId);
  const installationSnap = await installationRef.get();

  if (installationSnap.exists) {
    const ownerUid = installationSnap.get("uid");
    if (typeof ownerUid === "string" && ownerUid.trim() && ownerUid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "installation does not belong to current user"
      );
    }
  }

  await installationRef.delete();

  return { ok: true, installationId, deletedCount: installationSnap.exists ? 1 : 0 };
});
