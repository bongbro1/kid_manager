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
import { consumeFamilyChatRateLimit } from "../services/familyChatRateLimit";

const MAX_TEXT_LENGTH = 1000;
const MAX_LEGACY_STICKER_TEXT_LENGTH = 32;
const MAX_STICKER_ID_LENGTH = 64;
const MAX_CLIENT_MESSAGE_ID_LENGTH = 120;
const MULTICAST_LIMIT = 500;
const TOKEN_MIN_LENGTH = 20;
const MAX_IMAGE_URL_LENGTH = 2048;
const MAX_IMAGE_PATH_LENGTH = 512;
const MAX_IMAGE_BYTES = 2 * 1024 * 1024;
const FAMILY_CHAT_IMAGE_CONTENT_TYPE = "image/jpeg";

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

function expectedFamilyChatImagePath(params: {
  familyId: string;
  senderUid: string;
  messageId: string;
}) {
  return `families/${params.familyId}/chat/${params.senderUid}/${params.messageId}.jpg`;
}

function buildFirebaseStorageDownloadUrl(params: {
  bucketName: string;
  storagePath: string;
  token: string;
}) {
  return (
    `https://firebasestorage.googleapis.com/v0/b/${params.bucketName}/o/` +
    `${encodeURIComponent(params.storagePath)}?alt=media&token=${encodeURIComponent(params.token)}`
  );
}

function looksLikeStorageUrlForPath(imageUrl: string, storagePath: string) {
  const normalizedUrl = imageUrl.trim();
  if (!normalizedUrl) return false;

  const encodedPath = encodeURIComponent(storagePath);
  return normalizedUrl.includes(encodedPath) || normalizedUrl.includes(storagePath);
}

function resolveDownloadTokens(metadata: any): string[] {
  const rawValue =
    metadata?.metadata?.firebaseStorageDownloadTokens ??
    metadata?.firebaseStorageDownloadTokens ??
    "";

  return String(rawValue)
    .split(",")
    .map((token) => token.trim())
    .filter((token) => token.length > 0);
}

async function verifyFamilyChatImagePayload(params: {
  familyId: string;
  senderUid: string;
  messageId: string;
  data: FirebaseFirestore.DocumentData;
}) {
  const imageUrl = (params.data.imageUrl ?? "").toString().trim();
  const imagePath = (params.data.imagePath ?? "").toString().trim();
  const imageWidth = Number(params.data.imageWidth ?? 0);
  const imageHeight = Number(params.data.imageHeight ?? 0);

  if (!imageUrl || imageUrl.length > MAX_IMAGE_URL_LENGTH) {
    return { ok: false, reason: "invalid_image_url" } as const;
  }

  if (!imagePath || imagePath.length > MAX_IMAGE_PATH_LENGTH) {
    return { ok: false, reason: "invalid_image_path" } as const;
  }

  if (
    !Number.isFinite(imageWidth) ||
    !Number.isFinite(imageHeight) ||
    imageWidth <= 0 ||
    imageHeight <= 0
  ) {
    return { ok: false, reason: "invalid_image_dimensions" } as const;
  }

  const expectedPath = expectedFamilyChatImagePath({
    familyId: params.familyId,
    senderUid: params.senderUid,
    messageId: params.messageId,
  });

  if (imagePath !== expectedPath) {
    return { ok: false, reason: "image_path_mismatch" } as const;
  }

  const bucket = admin.storage().bucket();
  const file = bucket.file(imagePath);

  try {
    const [metadata] = await file.getMetadata();
    const contentType = String(metadata.contentType ?? "").trim().toLowerCase();
    const size = Number(metadata.size ?? 0);
    const customMetadata = metadata.metadata ?? {};

    if (!contentType.startsWith("image/")) {
      return { ok: false, reason: "invalid_image_content_type" } as const;
    }

    if (contentType !== FAMILY_CHAT_IMAGE_CONTENT_TYPE) {
      return { ok: false, reason: "unexpected_image_encoding" } as const;
    }

    if (!Number.isFinite(size) || size <= 0 || size > MAX_IMAGE_BYTES) {
      return { ok: false, reason: "invalid_image_size" } as const;
    }

    if (String(customMetadata.familyId ?? "").trim() !== params.familyId) {
      return { ok: false, reason: "image_family_mismatch" } as const;
    }

    if (String(customMetadata.senderUid ?? "").trim() !== params.senderUid) {
      return { ok: false, reason: "image_sender_mismatch" } as const;
    }

    if (String(customMetadata.messageId ?? "").trim() !== params.messageId) {
      return { ok: false, reason: "image_message_mismatch" } as const;
    }

    const downloadTokens = resolveDownloadTokens(metadata);
    const canonicalImageUrl = downloadTokens.length > 0
      ? buildFirebaseStorageDownloadUrl({
        bucketName: bucket.name,
        storagePath: imagePath,
        token: downloadTokens[0],
      })
      : looksLikeStorageUrlForPath(imageUrl, imagePath)
        ? imageUrl
        : "";

    if (!canonicalImageUrl) {
      return { ok: false, reason: "missing_image_download_token" } as const;
    }

    return {
      ok: true,
      imageUrl: canonicalImageUrl,
      imagePath,
      imageWidth,
      imageHeight,
    } as const;
  } catch (error) {
    console.error("[family_chat] verifyFamilyChatImagePayload failed", {
      familyId: params.familyId,
      senderUid: params.senderUid,
      messageId: params.messageId,
      imagePath,
      error,
    });
    return { ok: false, reason: "image_object_not_found" } as const;
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
  const imagePath = (data.imagePath ?? "").toString().trim();
  const imageWidth = Number(data.imageWidth ?? 0);
  const imageHeight = Number(data.imageHeight ?? 0);

  return (
    imageUrl.length > 0 &&
    imageUrl.length <= MAX_IMAGE_URL_LENGTH &&
    imagePath.length > 0 &&
    imagePath.length <= MAX_IMAGE_PATH_LENGTH &&
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
  const text = (data.text ?? "").toString().trim();
  const familyIdInDoc = (data.familyId ?? "").toString().trim();
  const type = (data.type ?? "").toString().trim();
  const isValidPayload = !!senderUid && !!familyIdInDoc;

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

  const senderMemberData = senderMember.data() ?? {};
  const senderRole =
    (senderMemberData.role ?? data.senderRole ?? "").toString().trim();
  const senderName =
    (senderMemberData.displayName ??
      senderMemberData.email ??
      data.senderName ??
      "Family member")
      .toString()
      .trim() ||
    "Family member";

  if (!senderRole) {
    await markPendingMessageFailed({
      ref,
      reason: "missing_sender_role",
    });
    return;
  }

  let normalizedText = text;
  let normalizedStickerId: string | undefined;
  let normalizedImageUrl: string | undefined;
  let normalizedImagePath: string | undefined;
  let normalizedImageWidth: number | undefined;
  let normalizedImageHeight: number | undefined;

  if (type === "text") {
    if (!isValidTextPayload(normalizedText)) {
      await markPendingMessageFailed({
        ref,
        reason: "invalid_message_payload",
      });
      return;
    }
  } else if (type === "sticker") {
    if (!isValidStickerPayload(data)) {
      await markPendingMessageFailed({
        ref,
        reason: "invalid_message_payload",
      });
      return;
    }
    normalizedStickerId = (data.stickerId ?? "").toString().trim();
  } else if (type === "image") {
    if (!isValidImagePayload(data)) {
      await markPendingMessageFailed({
        ref,
        reason: "invalid_message_payload",
      });
      return;
    }

    const verifiedImage = await verifyFamilyChatImagePayload({
      familyId,
      senderUid,
      messageId,
      data,
    });
    if (!verifiedImage.ok) {
      await markPendingMessageFailed({
        ref,
        reason: verifiedImage.reason,
      });
      return;
    }

    normalizedImageUrl = verifiedImage.imageUrl;
    normalizedImagePath = verifiedImage.imagePath;
    normalizedImageWidth = verifiedImage.imageWidth;
    normalizedImageHeight = verifiedImage.imageHeight;
  } else {
    await markPendingMessageFailed({
      ref,
      reason: "unsupported_message_type",
    });
    return;
  }

  const previewText = resolveMessagePreviewText(type, normalizedText);
  try {
    await consumeFamilyChatRateLimit({
      familyId,
      senderUid,
    });
  } catch (error) {
    if (error instanceof HttpsError && error.code === "resource-exhausted") {
      await markPendingMessageFailed({
        ref,
        reason: "rate_limited",
      });
      return;
    }
    throw error;
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
      senderRole,
      senderName,
      text: normalizedText,
      stickerId: normalizedStickerId ?? admin.firestore.FieldValue.delete(),
      imageUrl: normalizedImageUrl ?? admin.firestore.FieldValue.delete(),
      imagePath: normalizedImagePath ?? admin.firestore.FieldValue.delete(),
      imageWidth: normalizedImageWidth ?? admin.firestore.FieldValue.delete(),
      imageHeight: normalizedImageHeight ?? admin.firestore.FieldValue.delete(),
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

  const senderMember = membersSnap.docs.find((memberDoc) => memberDoc.id === uid);
  if (!senderMember) {
    throw new HttpsError(
      "permission-denied",
      "Sender is not an active member of this family"
    );
  }

  const senderMemberData = senderMember.data() ?? {};
  const senderRole =
    (typeof senderMemberData.role === "string" && senderMemberData.role.trim()) ||
    role;
  const senderName =
    (typeof senderMemberData.displayName === "string" &&
      senderMemberData.displayName.trim()) ||
    (typeof senderMemberData.email === "string" &&
      senderMemberData.email.trim()) ||
    (typeof userData.displayName === "string" && userData.displayName.trim()) ||
    (typeof userData.email === "string" && userData.email.trim()) ||
    "Family member";

  await consumeFamilyChatRateLimit({
    familyId,
    senderUid: uid,
  });

  const messageRef = familyRef.collection("messages").doc();
  const now = admin.firestore.FieldValue.serverTimestamp();

  // Persist message, family metadata, chat states, and chat notifications in one commit.
  const batch = db.batch();

  batch.set(messageRef, {
    id: messageRef.id,
    familyId,
    senderUid: uid,
    senderRole,
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
