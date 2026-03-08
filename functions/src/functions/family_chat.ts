import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

const MAX_TEXT_LENGTH = 1000;

export const sendFamilyMessage = onCall({ region: REGION }, async (req) => {
if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");

  const uid = req.auth.uid;
  const text = mustString(req.data?.text, "text");

  if (text.length > MAX_TEXT_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `text must be <= ${MAX_TEXT_LENGTH} characters`
    );
  }

  const { familyId, role } = await getUserFamilyAndRole(uid);
  await requireFamilyMember(familyId, uid);

  const userSnap = await db.doc(`users/${uid}`).get();
  const userData = userSnap.data() ?? {};

  const senderName =
    (typeof userData.displayName === "string" && userData.displayName.trim()) ||
    (typeof userData.email === "string" && userData.email.trim()) ||

  const messageRef = db.collection(`families/${familyId}/messages`).doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  const batch = db.batch();
  batch.set(messageRef, {
    id: messageRef.id,
    familyId,
    senderUid: uid,
    senderRole: role,
    senderName,
    text,
    type: "text",
    createdAt: now,
  });

  batch.set(
    db.doc(`families/${familyId}`),
    {
      lastMessageAt: now,
      lastMessageBy: uid,
      lastMessageText: text,
    },
    { merge: true }
  );

  await batch.commit();

  return {
    ok: true,
    familyId,
    messageId: messageRef.id,
  };
});
