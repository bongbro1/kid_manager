import { admin, db } from "../../bootstrap";
import { t } from "../../i18n";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByUid,
} from "../../services/fcmInstallations";

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

export async function sendLocalizedNotification(opts: {
  uid: string;
  type: string;
  eventKey: string;
  titleParams?: Record<string, string>;
  bodyParams?: Record<string, string>;
  data?: Record<string, string>;
  channelId?: string;
}) {
  const userSnap = await db.doc(`users/${opts.uid}`).get();
  const user = userSnap.exists ? (userSnap.data() as any) : {};
  const lang = (user.lang ?? user.locale ?? "vi").toString().toLowerCase();

  const installationGroups = groupInstallationsByToken(
    await listInstallationsByUid(opts.uid)
  );
  if (!installationGroups.length) return;
  const tokens = installationGroups.map((group) => group.token);

  const normalizedEventKey = normalizeEventKey(opts.eventKey);

  const titleKey = `${normalizedEventKey}.title`;
  const bodyKey = `${normalizedEventKey}.body`;

  const title = t(lang, titleKey, opts.titleParams);
  let body = t(lang, bodyKey, opts.bodyParams);
  let safeTitle = title;
  const isTrackingEvent = normalizedEventKey.startsWith("tracking.");

  const rawFallbackMessage = (opts.data?.message ?? "").toString().trim();
  const fallbackMessage = looksLikeLocalizedKey(rawFallbackMessage)
    ? ""
    : rawFallbackMessage;
  const fallbackTitle = lang.startsWith("en")
    ? (isTrackingEvent ? "Tracking notification" : "Notification")
    : (isTrackingEvent ? "Thông báo định vị" : "Thông báo");
  const fallbackBody = lang.startsWith("en")
    ? (isTrackingEvent ? "Tracking status has changed." : "You have a new notification.")
    : (isTrackingEvent ? "Trạng thái định vị đã thay đổi." : "Bạn có thông báo mới.");

  if (safeTitle === titleKey || looksLikeLocalizedKey(safeTitle)) {
    safeTitle = fallbackMessage || fallbackTitle;
  }
  if (body === bodyKey || looksLikeLocalizedKey(body)) {
    body = fallbackMessage || fallbackBody;
  }

  const payload = {
    tokens,
    notification: {
      title: safeTitle,
      body,
    },
    data: {
      ...(opts.data ?? {}),
      type: opts.type,
      eventKey: normalizedEventKey,
      lang,
      title: safeTitle,
      body,
      toUid: opts.uid,
    },
    android: {
      priority: "high" as const,
      notification: {
        channelId: opts.channelId ?? "general_alerts",
      },
    },
    apns: {
      payload: {
        aps: {
          alert: { title: safeTitle, body },
          sound: "default",
        },
      },
      headers: { "apns-priority": "10" },
    },
  };

  console.log("[sendLocalizedNotification] payload", {
    uid: opts.uid,
    type: opts.type,
    eventKey: normalizedEventKey,
    titleKey,
    bodyKey,
    safeTitle,
    safeBody: body,
    rawDataTitle: opts.data?.title,
    rawDataBody: opts.data?.body,
    rawMessage: opts.data?.message,
    tokenCount: tokens.length,
    payloadData: payload.data,
  });

  const resp = await admin.messaging().sendEachForMulticast(payload);

  const invalidInstallationIds: string[] = [];

  resp.responses.forEach((r, idx) => {
    if (r.success) return;

    const code = (r.error as any)?.code?.toString() ?? "";
    const shouldDelete =
      code.includes("messaging/registration-token-not-registered") ||
      code.includes("messaging/invalid-registration-token");

    if (shouldDelete) {
      const group = installationGroups[idx];
      if (!group) return;
      invalidInstallationIds.push(
        ...group.records.map((installation) => installation.installationId)
      );
    }
  });

  await deleteInstallationsByIds(invalidInstallationIds);
}
