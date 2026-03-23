import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByFamilyId,
} from "../services/fcmInstallations";

const MAX_TEXT_LENGTH = 1000;
const MAX_LEGACY_STICKER_TEXT_LENGTH = 32;
const MAX_STICKER_ID_LENGTH = 64;
const MAX_CLIENT_MESSAGE_ID_LENGTH = 120;
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

function resolveMessagePreviewText(type: string, text: string): string {
  switch (type) {
  case "image":
    return "[Photo]";
  case "sticker":
    return "[Sticker]";
  default:
    return text;
  }
}

function isValidTextPayload(text: string): boolean {
  return text.length > 0 && text.length <= MAX_TEXT_LENGTH;
}

function isValidStickerPayload(data: FirebaseFirestore.DocumentData): boolean {
  const stickerId = (data.stickerId ?? "").toString().trim();
  const legacyText = (data.text ?? "").toString().trim();

  if (stickerId) {
    return stickerId.length <= MAX_STICKER_ID_LENGTH;
  }

  return (
    legacyText.length > 0 &&
    legacyText.length <= MAX_LEGACY_STICKER_TEXT_LENGTH
  );
}

function isValidImagePayload(data: FirebaseFirestore.DocumentData): boolean {
  const imageUrl = (data.imageUrl ?? "").toString().trim();
  const imageWidth = Number(data.imageWidth ?? 0);
  const imageHeight = Number(data.imageHeight ?? 0);

  return (
    imageUrl.length > 0 &&
    imageUrl.length <= 2048 &&
    Number.isFinite(imageWidth) &&
    Number.isFinite(imageHeight) &&
    imageWidth > 0 &&
    imageHeight > 0
  );
}

async function markPendingMessageFailed(params: {
  ref: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  reason: string;
}) {
  await params.ref.set(
    {
      verifyState: "failed",
      verifyError: params.reason,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
}

async function finalizePendingFamilyMessage(params: {
  familyId: string;
  messageId: string;
  ref: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>;
  data: FirebaseFirestore.DocumentData;
}) {
  const familyId = params.familyId;
  const messageId = params.messageId;
  const ref = params.ref;
  const data = params.data ?? {};

  const senderUid = (data.senderUid ?? "").toString().trim();
  const senderRole = (data.senderRole ?? "").toString().trim();
  const senderName = (data.senderName ?? "").toString().trim() || "Family member";
  const text = (data.text ?? "").toString().trim();
  const familyIdInDoc = (data.familyId ?? "").toString().trim();
  const type = (data.type ?? "").toString().trim();
  const previewText = resolveMessagePreviewText(type, text);

  const isValidPayload =
    !!senderUid &&
    !!senderRole &&
    !!familyIdInDoc &&
    (
      (type === "text" && isValidTextPayload(text)) ||
      (type === "image" && isValidImagePayload(data)) ||
      (type === "sticker" && isValidStickerPayload(data))
    );

  if (!isValidPayload) {
    await markPendingMessageFailed({
      ref,
      reason: "invalid_message_payload",
    });
    return;
  }

  if (familyIdInDoc !== familyId) {
    await markPendingMessageFailed({
      ref,
      reason: "family_id_mismatch",
    });
    return;
  }

  const familyRef = db.doc(`families/${familyId}`);
  const membersSnap = await familyRef.collection("members").get();
  if (membersSnap.empty) {
    await markPendingMessageFailed({
      ref,
      reason: "family_has_no_members",
    });
    return;
  }

  const senderMember = membersSnap.docs.find((memberDoc) => memberDoc.id === senderUid);
  if (!senderMember) {
    await markPendingMessageFailed({
      ref,
      reason: "sender_not_in_family",
    });
    return;
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.set(
    ref,
    {
      verifyState: "verified",
      verifyError: admin.firestore.FieldValue.delete(),
      verifiedAt: now,
      createdAt: now,
    },
    { merge: true }
  );

  batch.set(
    familyRef,
    {
      lastMessageAt: now,
      lastMessageBy: senderUid,
      lastMessageText: previewText,
    },
    { merge: true }
  );

  const recipientUids: string[] = [];

  for (const memberDoc of membersSnap.docs) {
    const memberUid = memberDoc.id;
    const chatStateRef = familyRef.collection("chatStates").doc(memberUid);

    if (memberUid === senderUid) {
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
      continue;
    }

    recipientUids.push(memberUid);
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
      `users/${memberUid}/chatNotifications/${messageId}`
    );

    batch.set(
      chatNotifRef,
      {
        id: messageId,
        type: "family_chat",
        familyId,
        messageId,
        senderUid,
        senderName,
        body: previewText,
        route: "family_group_chat",
        isRead: false,
        createdAt: now,
      },
      { merge: true }
    );
  }

  await batch.commit();

  await sendFamilyChatPush({
    familyId,
    senderUid,
    senderName,
    text: previewText,
    messageId,
    recipientUids,
  });
}

export const sendFamilyMessage = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) {
    throw new HttpsError("unauthenticated", "Login required");
  }

  const uid = req.auth.uid;
  const text = mustString(req.data?.text, "text").trim();
  const clientMessageId =
    typeof req.data?.clientMessageId === "string"
      ? req.data.clientMessageId.trim()
      : "";

  if (text.length === 0) {
    throw new HttpsError("invalid-argument", "text is required");
  }

  if (text.length > MAX_TEXT_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `text must be <= ${MAX_TEXT_LENGTH} characters`
    );
  }

  if (clientMessageId.length > MAX_CLIENT_MESSAGE_ID_LENGTH) {
    throw new HttpsError(
      "invalid-argument",
      `clientMessageId must be <= ${MAX_CLIENT_MESSAGE_ID_LENGTH} characters`
    );
  }

  const userSnap = await db.doc(`users/${uid}`).get();
  const userData = userSnap.data() ?? {};
  const familyId =
    typeof userData.familyId === "string" ? userData.familyId.trim() : "";
  const role = typeof userData.role === "string" ? userData.role.trim() : "";

  if (!familyId) {
    throw new HttpsError("failed-precondition", "Missing familyId on user profile");
  }
  if (!role) {
    throw new HttpsError("failed-precondition", "Missing role on user profile");
  }

  const familyRef = db.doc(`families/${familyId}`);
  const membersSnap = await familyRef.collection("members").get();
  if (membersSnap.empty) {
    throw new HttpsError("failed-precondition", "Family has no members");
  }

  const senderName =
    (typeof userData.displayName === "string" && userData.displayName.trim()) ||
    (typeof userData.email === "string" && userData.email.trim()) ||
    "Family member";

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
    ...(clientMessageId ? { clientMessageId } : {}),
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

  return {
    ok: true,
    familyId,
    messageId: messageRef.id,
    ...(clientMessageId ? { clientMessageId } : {}),
  };
});

export const onFamilyChatMessageCreated = onDocumentCreated(
  {
    region: REGION,
    document: "families/{familyId}/messages/{messageId}",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const familyId = event.params.familyId;
    const messageId = event.params.messageId;
    const currentSnapshot = await snapshot.ref.get();
    if (!currentSnapshot.exists) {
      return;
    }
    const data = currentSnapshot.data() ?? {};
    const verifyState = (data.verifyState ?? "").toString().trim();

    if (verifyState === "pending") {
      try {
        await finalizePendingFamilyMessage({
          familyId,
          messageId,
          ref: snapshot.ref,
          data,
        });
      } catch (error) {
        console.error("[onFamilyChatMessageCreated] finalize pending failed", {
          familyId,
          messageId,
          error,
        });
        await markPendingMessageFailed({
          ref: snapshot.ref,
          reason: "processing_failed",
        });
      }
      return;
    }

    if (verifyState === "failed") {
      return;
    }

    const senderUid = (data.senderUid ?? "").toString().trim();
    const senderName = (data.senderName ?? "Family member").toString().trim();
    const text = (data.text ?? "").toString().trim();
    const type = (data.type ?? "text").toString().trim();
    const previewText = resolveMessagePreviewText(type, text);

    if (!senderUid || !previewText) {
      return;
    }

    try {
      const membersSnap = await db
        .collection("families")
        .doc(familyId)
        .collection("members")
        .get();

      const recipientUids = membersSnap.docs
        .map((memberDoc) => memberDoc.id)
        .filter((memberUid) => memberUid !== senderUid);

      await sendFamilyChatPush({
        familyId,
        senderUid,
        senderName: senderName || "Family member",
        text: previewText,
        messageId,
        recipientUids,
      });
    } catch (error) {
      console.error("[onFamilyChatMessageCreated] push delivery failed", {
        familyId,
        messageId,
        error,
      });
    }
  }
);
