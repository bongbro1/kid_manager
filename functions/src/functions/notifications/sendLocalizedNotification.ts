import { admin, db } from "../../bootstrap";
import { t } from "../../i18n";

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

  const tokensSnap = await db.collection(`users/${opts.uid}/fcmTokens`).get();
  if (tokensSnap.empty) return;

  const tokens: string[] = [];
  const tokenDocIds: string[] = [];

  tokensSnap.forEach((doc) => {
    const token = (doc.data() as any)?.token?.toString();
    if (token && token.length >= 20) {
      tokens.push(token);
      tokenDocIds.push(doc.id);
    }
  });

  if (tokens.length === 0) return;

  const title = t(lang, `${opts.eventKey}.title`, opts.titleParams);
  let body = t(lang, `${opts.eventKey}.body`, opts.bodyParams);
  let safeTitle = title;
  const titleKey = `${opts.eventKey}.title`;
  const bodyKey = `${opts.eventKey}.body`;
  const isTrackingEvent = opts.eventKey.startsWith("tracking.");

  const fallbackMessage = (opts.data?.message ?? "").toString().trim();
  const fallbackTitle = lang.startsWith("en")
    ? (isTrackingEvent ? "Tracking notification" : "Notification")
    : (isTrackingEvent ? "Thong bao dinh vi" : "Thong bao");
  const fallbackBody = lang.startsWith("en")
    ? (isTrackingEvent ? "Tracking status has changed." : "You have a new notification.")
    : (isTrackingEvent ? "Trang thai dinh vi da thay doi." : "Ban co thong bao moi.");

  if (safeTitle === titleKey) {
    safeTitle = fallbackMessage || fallbackTitle;
  }
  if (body === bodyKey) {
    body = fallbackMessage || fallbackBody;
  }

  const resp = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title: safeTitle,
      body,
    },
    data: {
      type: opts.type,
      eventKey: opts.eventKey,
      lang,
      title: safeTitle,
      body,
      ...(opts.data ?? {}),
      toUid: opts.uid,
    },
    android: {
      priority: "high",
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
  });

  const batch = db.batch();

  resp.responses.forEach((r, idx) => {
    if (r.success) return;

    const code = (r.error as any)?.code?.toString() ?? "";
    const shouldDelete =
      code.includes("messaging/registration-token-not-registered") ||
      code.includes("messaging/invalid-registration-token");

    if (shouldDelete) {
      batch.delete(db.doc(`users/${opts.uid}/fcmTokens/${tokenDocIds[idx]}`));
    }
  });

  await batch.commit();
}
