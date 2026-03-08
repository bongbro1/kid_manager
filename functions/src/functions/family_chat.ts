import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

const MAX_TEXT_LENGTH = 1000;

export const sendFamilyMessage = onCall({ region: REGION }, async (req) => {
if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const uid = req.auth.uid;
  const text = mustString(req.data?.text, "text").trim();

  if (text.isEmpty) {
    throw new HttpsError("invalid-argument", "text is required");
  }

  if (text.length > MAX_TEXT_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `text must be <= ${MAX_TEXT_LENGTH} characters`
    );
  }

  const { familyId, role } = await getUserFamilyAndRole(uid);
  await requireFamilyMember(familyId, uid);

  const familyRef = db.doc(`families/${familyId}`);
  const membersSnap = await familyRef.collection("members").get();

  const userSnap = await db.doc(`users/${uid}`).get();
  const userData = userSnap.data() ?? {};

  const senderName =
    (typeof userData.displayName === "string" && userData.displayName.trim()) ||
    (typeof userData.email === "string" && userData.email.trim()) ||
    "Family member";

  const messageRef = familyRef.collection("messages").doc();
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
    familyRef,
    {
      lastMessageAt: now,
      lastMessageBy: uid,
      lastMessageText: text,
    },
    { merge: true }
  );

  for (const memberDoc of membersSnap.docs) {
    const memberUid = memberDoc.id;
    const chatStateRef = familyRef.collection("chatStates").doc(memberUid);

    if (memberUid === uid) {
      batch.set(
        chatStateRef,
        {
          uid: memberUid,
          unreadCount: 0,
          lastReadAt: now,
          updatedAt: now,
        },
        { merge: true }
      );
    } else {
      batch.set(
        chatStateRef,
        {
          uid: memberUid,
          unreadCount: admin.firestore.FieldValue.increment(1),
          updatedAt: now,
        },
        { merge: true }
      );
    }
  }

  await batch.commit();

  // Tao notification sau khi gui tin nhan thanh cong
  const notifyBatch = db.batch();

  for (const memberDoc of membersSnap.docs) {
    const memberUid = memberDoc.id;
    if (memberUid === uid) continue;

    const notifRef = db.collection("notifications").doc();

    notifyBatch.set(notifRef, {
      senderId: uid,
      receiverId: memberUid,
      type: "family_chat",
      title: senderName,
      body: text,
      familyId,
      isRead: false,
      status: "pending",
      createdAt: now,
      data: {
        familyId,
        messageId: messageRef.id,
        route: "family_group_chat",
        senderUid: uid,
      },
    });
  }

  await notifyBatch.commit();

  return {
    ok: true,
    familyId,
    messageId: messageRef.id,
  };
});