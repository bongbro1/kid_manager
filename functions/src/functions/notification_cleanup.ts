import { onSchedule } from "firebase-functions/v2/scheduler";

import { admin, db } from "../bootstrap";
import { REGION, TZ } from "../config";
import { TRACKING_LOCATION_EVENT_CATEGORY } from "../services/trackingLocationNotifications";

const DELETE_PAGE_SIZE = 200;

function buildExpiredLocationStatusNotificationsQuery(
  cutoff: FirebaseFirestore.Timestamp,
) {
  return db
    .collection("notifications")
    .where("eventCategory", "==", TRACKING_LOCATION_EVENT_CATEGORY)
    .where("expiresAt", "<=", cutoff)
    .orderBy("expiresAt")
    .limit(DELETE_PAGE_SIZE);
}

export const cleanupExpiredTrackingLocationNotifications = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: TZ,
    region: REGION,
    timeoutSeconds: 540,
  },
  async () => {
    const startedAtMs = Date.now();
    const cutoff = new Date(startedAtMs);
    const cutoffTs = admin.firestore.Timestamp.fromDate(cutoff);

    let deletedCount = 0;
    let scannedCount = 0;

    while (true) {
      const snapshot = await buildExpiredLocationStatusNotificationsQuery(
        cutoffTs,
      ).get();
      if (snapshot.empty) {
        break;
      }

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        scannedCount++;
        batch.delete(doc.ref);
      }
      await batch.commit();
      deletedCount += snapshot.size;

      if (snapshot.size < DELETE_PAGE_SIZE) {
        break;
      }
    }

    console.log(
      `[NOTIFICATION_CLEANUP] category=${TRACKING_LOCATION_EVENT_CATEGORY}` +
        ` cutoff=${cutoff.toISOString()}` +
        ` scanned=${scannedCount}` +
        ` deleted=${deletedCount}` +
        ` durationMs=${Date.now() - startedAtMs}`,
    );
  },
);
