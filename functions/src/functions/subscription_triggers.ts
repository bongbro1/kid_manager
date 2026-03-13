import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../bootstrap";
import { onSchedule } from "firebase-functions/scheduler";


export const onUserSubscriptionChanged = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;

    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!after) return;

    const beforeSub = before?.subscription ?? null;
    const afterSub = after.subscription ?? null;

    if (!afterSub) return;

    // check status change
    const beforeStatus = beforeSub?.status;
    const afterStatus = afterSub?.status;

    if (beforeStatus === afterStatus) {
      return;
    }

    let title = "";
    let body = "";

    switch (afterStatus) {
      case "trial":
        title = "Trial started";
        body = "Your trial has started.";
        break;

      case "active":
        title = "Subscription activated";
        body = "Your subscription is now active.";
        break;

      case "expired":
        title = "Subscription expired";
        body = "Your subscription has expired.";
        break;

      case "canceled":
        title = "Subscription canceled";
        body = "Your subscription has been canceled.";
        break;

      case "payment_failed":
        title = "Payment failed";
        body = "Payment failed for your subscription.";
        break;

      default:
        return;
    }

    await db.collection("notifications").add({
      senderId: "system",
      receiverId: uid,
      type: "subscription",
      title,
      body,
      data: {
        plan: afterSub.plan ?? null,
        status: afterSub.status ?? null,
      },
      createdAt: FieldValue.serverTimestamp(),
      isRead: false,
    });
  }
);

export const expireSubscriptionsJob = onSchedule(
  "every 24 hours",
  async () => {
    const now = new Date();

    const snapshot = await db
      .collection("users")
      .where("subscription.status", "in", ["active", "trial"])
      .where("subscription.endAt", "<=", now)
      .get();

    const batch = db.batch();

    snapshot.docs.forEach((doc) => {
      batch.update(doc.ref, {
        "subscription.status": "expired",
        "subscription.updatedAt": FieldValue.serverTimestamp(),
      });
    });

    if (!snapshot.empty) {
      await batch.commit();
    }

    console.log("Expired subscriptions:", snapshot.size);
  }
);