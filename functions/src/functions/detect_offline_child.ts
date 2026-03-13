import { onSchedule } from "firebase-functions/scheduler";
import { REGION } from "../config";
import { admin, db } from "../bootstrap";

export const detectKidAppRemoved = onSchedule(
{
  schedule: "every 10 minutes",
  region: REGION,
},
async () => {
  const now = Date.now()

  const timeoutMs = 30 * 60 * 1000

  const threshold = admin.firestore.Timestamp.fromMillis(now - timeoutMs)

  const snap = await db
      .collectionGroup("apps")
      .where("packageName", "==", "com.example.kid_manager")
      .where("kidLastSeen", "<", threshold)
      .get()


  for (const doc of snap.docs) {

    // ✅ lấy childId đúng từ path
    const childId = doc.ref.parent.parent?.id
    const data = doc.data()
    if (!childId) {
      console.log("skip: childId not found in path")
      continue
    }

    if (data.kidAppRemovedAlertSent) {
      console.log("skip: alert already sent")
      continue
    }

    /// 1️⃣ query child user
    const childSnap = await db.collection("users").doc(childId).get()

    if (!childSnap.exists) {
      console.log("skip: child user not found")
      continue
    }

    const childData = childSnap.data()
    const parentId = childData?.parentUid
    const childName = childData?.displayName ?? "Child"

    if (!parentId) {
      console.log("skip: parentId missing")
      continue
    }

    // console.log(`[KID APP OFFLINE] child=${childId}`)

    /// 2️⃣ create notification
    const notiRef = await db.collection("notifications").add({

      receiverId: parentId,
      senderId: "system",
      type: "appRemoved",

      title: "Ứng dụng quản lý không hoạt động",

      body: `${childName} có thể đã gỡ hoặc tắt ứng dụng quản lý`,

      isRead: false,
      status: "pending",

      createdAt: admin.firestore.Timestamp.now(),

      data: {
        childId,
        lastSeen: data.kidLastSeen
      }

    })

    console.log("[KID APP OFFLINE] notification created id =", notiRef.id)

    /// 3️⃣ mark alert sent
    await doc.ref.update({
      kidAppRemovedAlertSent: true
    })

    // console.log("[KID APP OFFLINE] kidAppRemovedAlertSent updated")

  }

  // console.log("========== detectKidAppRemoved END ==========");

});