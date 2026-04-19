import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { convertDataToString } from "../helpers";
import { t } from "../i18n";
import { normalizeClientNotificationCreateInput } from "../services/authorizedNotifications";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByUid,
} from "../services/fcmInstallations";
import { createGlobalNotificationRecord } from "../services/globalNotifications";

function normalizeEventKey(raw: string): string {
  const key = (raw || "").trim();
  if (key.endsWith(".title") || key.endsWith(".body")) {
    const cut = key.lastIndexOf(".");
    if (cut > 0) return key.substring(0, cut);
  }
  return key;
}

function looksLikeLocalizedKey(value: string): boolean {
  const v = (value || "").trim();
  return /^[a-z0-9_.-]+\.(title|body)$/i.test(v);
}

function readTrimmedStringField(data: Record<string, unknown>, field: string): string {
  const value = data[field];
  return typeof value === "string" ? value.trim() : "";
}

export const enqueueAuthorizedNotification = onCall(
  { region: REGION },
  async (req) => {
    if (!req.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const senderUid = req.auth.uid;
    const normalized = normalizeClientNotificationCreateInput({
      type: req.data?.type,
      title: req.data?.title,
      body: req.data?.body,
      receiverId: req.data?.receiverId,
      familyId: req.data?.familyId,
      data: req.data?.data,
    });

    const [senderSnap, receiverSnap] = await Promise.all([
      db.doc(`users/${senderUid}`).get(),
      db.doc(`users/${normalized.receiverId}`).get(),
    ]);

    if (!senderSnap.exists) {
      throw new HttpsError("not-found", "Sender not found");
    }
    if (!receiverSnap.exists) {
      throw new HttpsError("not-found", "Receiver not found");
    }

    const senderData = (senderSnap.data() ?? {}) as Record<string, unknown>;
    const receiverData = (receiverSnap.data() ?? {}) as Record<string, unknown>;
    const senderFamilyId = readTrimmedStringField(senderData, "familyId");
    const receiverFamilyId = readTrimmedStringField(receiverData, "familyId");

    if (!senderFamilyId || !receiverFamilyId || senderFamilyId !== receiverFamilyId) {
      throw new HttpsError(
        "permission-denied",
        "Sender and receiver must belong to the same family",
      );
    }

    if (normalized.familyId != null && normalized.familyId !== senderFamilyId) {
      throw new HttpsError(
        "permission-denied",
        "familyId does not match the authenticated sender scope",
      );
    }

    const canonicalFamilyId = normalized.familyId ?? senderFamilyId;
    const canonicalData = {
      ...normalized.data,
      senderId: senderUid,
      receiverId: normalized.receiverId,
      familyId: canonicalFamilyId,
      type: normalized.type,
    };

    const notificationId = await createGlobalNotificationRecord({
      receiverId: normalized.receiverId,
      senderId: senderUid,
      type: normalized.type,
      title: normalized.title,
      body: normalized.body,
      familyId: canonicalFamilyId,
      data: canonicalData,
    });

    return {
      ok: true,
      notificationId,
    };
  },
);

export const onNotificationCreated = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    region: REGION,
    retry: true,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const notificationId = event.params.notificationId;
    const data = snap.data() as any;

    const toUid: string | undefined = data.receiverId;
    if (!toUid) {
      console.log("[NOTI] Missing receiverId -> skip");
      return;
    }

    const payloadData = convertDataToString(data.data ?? {});
    const traceId = String(
      data.traceId ?? payloadData.debugTraceId ?? payloadData.traceId ?? "",
    );

    console.log(
      `[NOTI] Triggered id=${notificationId} toUid=${toUid} traceId=${traceId} type=${String(
        data.type ?? "",
      )}`,
    );

    const installationGroups = groupInstallationsByToken(
      await listInstallationsByUid(toUid)
    );
    if (!installationGroups.length) {
      console.log(`[NOTI] No tokens -> skip traceId=${traceId}`);
      return;
    }
    const tokens = installationGroups.map((group) => group.token);

    const userSnap = await db.doc(`users/${toUid}`).get();
    const user = userSnap.exists ? (userSnap.data() as any) : {};
    const lang = (user.lang ?? user.locale ?? "vi").toString().toLowerCase();

    const rawTitle = String(data.title ?? "");
    const rawBody = String(data.body ?? "");

    let eventKey = normalizeEventKey(String(data.eventKey ?? payloadData.eventKey ?? ""));
    if (!eventKey) {
      if (rawTitle.endsWith(".title")) eventKey = normalizeEventKey(rawTitle);
      else if (rawBody.endsWith(".body")) eventKey = normalizeEventKey(rawBody);
    }

    let safeTitle =
      rawTitle || (lang.startsWith("en") ? "Notification" : "Thong bao");
    let safeBody =
      rawBody ||
      (lang.startsWith("en")
        ? "You have a new notification."
        : "Bạn có thông báo mới");

    if (eventKey) {
      const localizedTitle = t(lang, `${eventKey}.title`, payloadData);
      const localizedBody = t(lang, `${eventKey}.body`, payloadData);

      if (!looksLikeLocalizedKey(localizedTitle)) {
        safeTitle = localizedTitle;
      }
      if (!looksLikeLocalizedKey(localizedBody)) {
        safeBody = localizedBody;
      }
    }

    if (looksLikeLocalizedKey(safeTitle)) {
      safeTitle = lang.startsWith("en") ? "Notification" : "Thong bao";
    }
    if (looksLikeLocalizedKey(safeBody)) {
      safeBody = lang.startsWith("en")
        ? "You have a new notification."
        : "Bạn có thông báo mới.";
    }

    const resp = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: safeTitle,
        body: safeBody,
      },
      data: {
        ...payloadData,
        receiverId: toUid,
        title: safeTitle,
        body: safeBody,
        type: String(data.type ?? "GENERIC"),
        notificationId,
        eventKey,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "general_notifications",
          priority: "high",
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: {
              title: safeTitle,
              body: safeBody,
            },
            sound: "default",
          },
        },
        headers: { "apns-priority": "10" },
      },
    });

    console.log(
      `[VIOLATION_TRACE] push_sent traceId=${traceId} notificationId=${notificationId} tokens=${tokens.length}`,
    );

    const invalidInstallationIds: string[] = [];

    resp.responses.forEach((result, index) => {
      if (result.success) return;

      const code = result.error?.code ?? "";
      const shouldDelete =
        code.includes("messaging/registration-token-not-registered") ||
        code.includes("messaging/invalid-registration-token");
      if (!shouldDelete) return;

      const group = installationGroups[index];
      if (!group) return;
      invalidInstallationIds.push(
        ...group.records.map((installation) => installation.installationId)
      );
    });

    await deleteInstallationsByIds(invalidInstallationIds);

    await snap.ref.update({
      title: safeTitle,
      body: safeBody,
      status: "sent",
    });
  }
);
