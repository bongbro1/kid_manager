import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { convertDataToString } from "../helpers";

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

    console.log(
      `[NOTI] Triggered id=${notificationId} toUid=${toUid}`
    );

    const tokenSnap = await db
      .collection(`users/${toUid}/fcmTokens`)
      .get();

    if (tokenSnap.empty) {
      console.log("[NOTI] No tokens -> skip");
      return;
    }

    const tokens: string[] = [];

    tokenSnap.forEach((doc) => {
      const t = (doc.data() as any)?.token;
      if (t) tokens.push(t);
    });

    if (!tokens.length) {
      console.log("[NOTI] No usable tokens");
      return;
    }

    await admin.messaging().sendEachForMulticast({
      tokens,
      data: {
        title: String(data.title ?? "Thông báo"),
        body: String(data.body ?? "Bạn có thông báo mới"),
        type: String(data.type ?? "GENERIC"),
        notificationId,
        ...convertDataToString(data.data),
      },
      android: {
        priority: "high",
      },
    });

    console.log(
      `[NOTI] Sent to ${tokens.length} devices`
    );

    // Optional: update status
    await snap.ref.update({ status: "sent" });
  }
);