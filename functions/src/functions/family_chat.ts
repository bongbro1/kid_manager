import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

const MAX_TEXT_LENGTH = 1000;
const MULTICAST_LIMIT = 500;
const TOKEN_MIN_LENGTH = 20;

type FamilyTokenRecord = {
  docId: string;
  uid: string;
  token: string;
};

function splitIntoChunks<T>(items: T[], size: number): T[][] {
  if (size <= 0) return [items];

  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

function shouldDeleteInvalidToken(code: string): boolean {
  return (
    code.includes("messaging/registration-token-not-registered") ||
    code.includes("messaging/invalid-registration-token")
  );
}

async function cleanupInvalidFamilyTokens(
  familyId: string,
  invalidTokens: FamilyTokenRecord[]
) {
  if (!invalidTokens.length) return;

  // One invalid token deletes 2 docs (family + user), so keep chunks <= 250 tokens.
  const chunks = splitIntoChunks(invalidTokens, 200);
  for (const chunk of chunks) {
    const batch = db.batch();

    for (const tokenRecord of chunk) {
      batch.delete(db.doc(`families/${familyId}/fcmTokens/${tokenRecord.docId}`));
      batch.delete(db.doc(`users/${tokenRecord.uid}/fcmTokens/${tokenRecord.docId}`));
    }

    await batch.commit();
  }
}

async function sendFamilyChatPush(params: {
  familyId: string;
  senderUid: string;
  senderName: string;
  text: string;
  messageId: string;
  recipientUids: string[];
}) {
  if (!params.recipientUids.length) return;

  const recipientUidSet = new Set(params.recipientUids);
  const familyTokenSnap = await db
    .collection(`families/${params.familyId}/fcmTokens`)
    .get();

  if (familyTokenSnap.empty) return;

  const tokenRecords: FamilyTokenRecord[] = [];

  for (const tokenDoc of familyTokenSnap.docs) {
    const data = tokenDoc.data() ?? {};
    const token = typeof data.token === "string" ? data.token.trim() : "";
    const tokenUid = typeof data.uid === "string" ? data.uid : "";

    if (token.length < TOKEN_MIN_LENGTH) continue;
    if (!tokenUid || !recipientUidSet.has(tokenUid)) continue;

    tokenRecords.push({
      docId: tokenDoc.id,
      uid: tokenUid,
      token,
    });
  }

  if (!tokenRecords.length) return;

  // Deduplicate repeated tokens to avoid duplicate push sends.
  const seenTokens = new Set<string>();
  const uniqueTokenRecords: FamilyTokenRecord[] = [];
  for (const tokenRecord of tokenRecords) {
    if (seenTokens.has(tokenRecord.token)) continue;
    seenTokens.add(tokenRecord.token);
    uniqueTokenRecords.push(tokenRecord);
  }

  const tokenChunks = splitIntoChunks(uniqueTokenRecords, MULTICAST_LIMIT);

  const sendResponses = await Promise.all(
    tokenChunks.map((chunk) =>
      admin.messaging().sendEachForMulticast({
        tokens: chunk.map((record) => record.token),
        notification: {
          title: params.senderName,
          body: params.text,
        },
        data: {
          type: "family_chat",
          route: "family_group_chat",
          familyId: params.familyId,
          messageId: params.messageId,
          senderUid: params.senderUid,
          senderName: params.senderName,
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
      })
    )
  );

  const invalidTokens: FamilyTokenRecord[] = [];

  sendResponses.forEach((response, chunkIndex) => {
    const chunk = tokenChunks[chunkIndex];

    response.responses.forEach((sendResult, tokenIndex) => {
      if (sendResult.success) return;

      const code = sendResult.error?.code ?? "";
      if (!shouldDeleteInvalidToken(code)) return;

      const tokenRecord = chunk[tokenIndex];
      if (tokenRecord) {
        invalidTokens.push(tokenRecord);
      }
    });
  });

  await cleanupInvalidFamilyTokens(params.familyId, invalidTokens);
}

export const sendFamilyMessage = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const uid = req.auth.uid;
  const text = mustString(req.data?.text, "text").trim();

  if (text.length === 0) {
    throw new HttpsError("invalid-argument", "text is required");
  }

  if (text.length > MAX_TEXT_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `text must be <= ${MAX_TEXT_LENGTH} characters`
    );
  }

  const { familyId, role } = await getUserFamilyAndRole(uid);
  const familyRef = db.doc(`families/${familyId}`);

  const memberValidationPromise = requireFamilyMember(familyId, uid);
  const membersSnapPromise = familyRef.collection("members").get();
  const userSnapPromise = db.doc(`users/${uid}`).get();

  await memberValidationPromise;
  const [membersSnap, userSnap] = await Promise.all([
    membersSnapPromise,
    userSnapPromise,
  ]);

  if (membersSnap.empty) {
    throw new HttpsError("failed-precondition", "Family has no members");
  }

  const userData = userSnap.data() ?? {};
  const senderName =
    (typeof userData.displayName === "string" && userData.displayName.trim()) ||
    (typeof userData.email === "string" && userData.email.trim()) ||
    "Family member";

  const recipientUids = membersSnap.docs
    .map((memberDoc) => memberDoc.id)
    .filter((memberUid) => memberUid !== uid);

  const messageRef = familyRef.collection("messages").doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Persist message, family metadata, chat states, and chat notifications in one commit.
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

      const chatNotifRef = db.doc(
        `users/${memberUid}/chatNotifications/${messageRef.id}`
      );

      batch.set(
        chatNotifRef,
        {
          id: messageRef.id,
          type: "family_chat",
          familyId,
          messageId: messageRef.id,
          senderUid: uid,
          senderName,
          body: text,
          route: "family_group_chat",
          isRead: false,
          createdAt: now,
        },
        { merge: true }
      );
    }
  }

  await batch.commit();

  try {
    await sendFamilyChatPush({
      familyId,
      senderUid: uid,
      senderName,
      text,
      messageId: messageRef.id,
      recipientUids,
    });
  } catch (error) {
    console.error("[sendFamilyMessage] push delivery failed", {
      familyId,
      messageId: messageRef.id,
      error,
    });
  }

  return {
    ok: true,
    familyId,
    messageId: messageRef.id,
  };
});
