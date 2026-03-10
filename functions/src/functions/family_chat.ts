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

  for (const memberDoc of membersSnap.docs) {
    const memberUid = memberDoc.id;
    if (memberUid === uid) continue;

    const tokenSnap = await db.collection(`users/${memberUid}/fcmTokens`).get();
    if (tokenSnap.empty) continue;

    const tokens = tokenSnap.docs
      .map((d) => d.data()?.token)
      .filter((t): t is string => typeof t === "string" && t.length > 0);

    if (!tokens.length) continue;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: senderName,
        body: text,
      },
      data: {
        type: "family_chat",
        route: "family_group_chat",
        familyId,
        messageId: messageRef.id,
        senderUid: uid,
        senderName,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "chat_messages",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });
  }

  return {
    ok: true,
    familyId,
    messageId: messageRef.id,
  };
});