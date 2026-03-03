import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString, mustPlatform, sha256Hex } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

export const registerFcmToken = onCall({ region: REGION }, async (req) => {
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
});

export const unregisterFcmToken = onCall({ region: REGION }, async (req) => {
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
});