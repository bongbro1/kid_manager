import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../../bootstrap";
import { REGION } from "../../config";
import { mustString } from "../../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../../services/user";

const ALLOWED_STATUS = new Set([
"ok",
"location_service_off",
"location_permission_denied",
"background_disabled",
"location_stale",
]);

export const reportTrackingStatus = onCall({ region: REGION }, async (req) => {
if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const uid = req.auth.uid;
  const status = mustString(req.data?.status, "status");
  const message = typeof req.data?.message === "string" ? req.data.message : "";

  if (!ALLOWED_STATUS.has(status)) {
    throw new HttpsError("invalid-argument", "invalid status");
  }

  const { familyId } = await getUserFamilyAndRole(uid);
  await requireFamilyMember(familyId, uid);

  const userSnap = await db.doc(`users/${uid}`).get();
  const childName =
    (userSnap.exists ? userSnap.get("displayName") : null) ||
    (userSnap.exists ? userSnap.get("name") : null) ||
    "Con";

  const prevRef = db.doc(`families/${familyId}/trackingStatus/${uid}`);
  const prevSnap = await prevRef.get();
  const prevStatus = prevSnap.exists ? String(prevSnap.get("status") || "") : "";

  await prevRef.set(
    {
      childId: uid,
      childName,
      familyId,
      status,
      message,
      prevStatus,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  return { ok: true };
});