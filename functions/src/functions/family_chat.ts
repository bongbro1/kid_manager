import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByFamilyId,
} from "../services/fcmInstallations";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

const MAX_TEXT_LENGTH = 1000;
const MULTICAST_LIMIT = 500;
const TOKEN_MIN_LENGTH = 20;

type FamilyTokenRecord = {
  installationId: string;
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
  invalidTokens: FamilyTokenRecord[]
) {
  if (!invalidTokens.length) return;
  await deleteInstallationsByIds(
    invalidTokens.map((tokenRecord) => tokenRecord.installationId)
  );
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
  const familyInstallations = await listInstallationsByFamilyId(params.familyId);
  if (!familyInstallations.length) return;

  const tokenRecords: FamilyTokenRecord[] = [];

  for (const installation of familyInstallations) {
    if (installation.token.length < TOKEN_MIN_LENGTH) continue;
    if (!recipientUidSet.has(installation.uid)) continue;

    tokenRecords.push({
      installationId: installation.installationId,
      uid: installation.uid,
      token: installation.token,
    });
  }

  if (!tokenRecords.length) return;
  const tokenGroups = groupInstallationsByToken(tokenRecords);
  const tokenChunks = splitIntoChunks(tokenGroups, MULTICAST_LIMIT);

  const sendResponses = await Promise.all(
    tokenChunks.map((chunk) =>
      admin.messaging().sendEachForMulticast({
        tokens: chunk.map((group) => group.token),
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

      const tokenGroup = chunk[tokenIndex];
      if (tokenGroup) {
        invalidTokens.push(...tokenGroup.records);
      }
    });
  });

  await cleanupInvalidFamilyTokens(invalidTokens);
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
