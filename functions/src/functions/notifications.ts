import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { convertDataToString } from "../helpers";

export const onNotificationCreated = onDocumentCreated(
{ document: "notifications/{notificationId}", region: REGION, retry: true },
async (event) => {
    const snap = event.data;
    if (!snap) return;

    const notificationId = event.params.notificationId;
    const data = snap.data() as any;

    const toUid: string | undefined = data.toUid;
    if (!toUid) return;

    const tokenSnap = await db.collection(`users/${toUid}/fcmTokens`).get();
    if (tokenSnap.empty) return;

    const tokens: string[] = [];
    tokenSnap.forEach((doc) => {
      const t = (doc.data() as any)?.token;
      if (t) tokens.push(t);
    });
    if (!tokens.length) return;

    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: data.title ?? "Thông báo",
        body: data.body ?? "Bạn có thông báo mới",
      },
      data: {
        type: String(data.type ?? "GENERIC"),
        notificationId,
        ...convertDataToString(data.data),
      },
      android: { priority: "high" },
    });
  }
);