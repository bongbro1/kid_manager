import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

export const markFamilyChatRead = onCall({ region: REGION }, async (req) => {
if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const uid = req.auth.uid;
  const { familyId } = await getUserFamilyAndRole(uid);
  await requireFamilyMember(familyId, uid);

  const now = admin.firestore.FieldValue.serverTimestamp();
  const chatStateRef = db.doc(`families/${familyId}/chatStates/${uid}`);

  await chatStateRef.set(
    {
      uid,
      unreadCount: 0,
      lastReadAt: now,
      updatedAt: now,
    },
    { merge: true }
  );

  return {
    ok: true,
    familyId,
    uid,
  };
});