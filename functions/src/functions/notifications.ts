import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { convertDataToString } from "../helpers";
import { t } from "../i18n";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByUid,
} from "../services/fcmInstallations";

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

    console.log(`[NOTI] Triggered id=${notificationId} toUid=${toUid}`);

    const installationGroups = groupInstallationsByToken(
      await listInstallationsByUid(toUid)
    );
    if (!installationGroups.length) {
      console.log("[NOTI] No tokens -> skip");
      return;
    }
    const tokens = installationGroups.map((group) => group.token);

    const userSnap = await db.doc(`users/${toUid}`).get();
    const user = userSnap.exists ? (userSnap.data() as any) : {};
    const lang = (user.lang ?? user.locale ?? "vi").toString().toLowerCase();

    const payloadData = convertDataToString(data.data ?? {});

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
        title: safeTitle,
        body: safeBody,
        type: String(data.type ?? "GENERIC"),
        notificationId,
        eventKey,
      },
      android: {
        priority: "high",
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

    console.log(`[NOTI] Sent to ${tokens.length} devices`);

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

    await snap.ref.update({ status: "sent" });
  }
);
