import { onSchedule } from "firebase-functions/v2/scheduler";

import { admin, db } from "../bootstrap";
import { REGION, TZ } from "../config";
import { BATTERY_EVENT_CATEGORY } from "../services/batteryNotifications";
import { TRACKING_LOCATION_EVENT_CATEGORY } from "../services/trackingLocationNotifications";

const DELETE_PAGE_SIZE = 200;
const EXPIRING_NOTIFICATION_CATEGORIES = [
  TRACKING_LOCATION_EVENT_CATEGORY,
  BATTERY_EVENT_CATEGORY,
] as const;

function buildExpiredLocationStatusNotificationsQuery(
  eventCategory: string,
  cutoff: FirebaseFirestore.Timestamp,
) {
  return db
    .collection("notifications")
    .where("eventCategory", "==", eventCategory)
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

    let totalDeletedCount = 0;
    let totalScannedCount = 0;

    for (const eventCategory of EXPIRING_NOTIFICATION_CATEGORIES) {
      let deletedCount = 0;
      let scannedCount = 0;

      while (true) {
        const snapshot = await buildExpiredLocationStatusNotificationsQuery(
          eventCategory,
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

      totalDeletedCount += deletedCount;
      totalScannedCount += scannedCount;

      console.log(
        `[NOTIFICATION_CLEANUP] category=${eventCategory}` +
          ` cutoff=${cutoff.toISOString()}` +
          ` scanned=${scannedCount}` +
          ` deleted=${deletedCount}` +
          ` durationMs=${Date.now() - startedAtMs}`,
      );
    }

    console.log(
      `[NOTIFICATION_CLEANUP] categories=${EXPIRING_NOTIFICATION_CATEGORIES.join(",")}` +
        ` cutoff=${cutoff.toISOString()}` +
        ` scanned=${totalScannedCount}` +
        ` deleted=${totalDeletedCount}` +
        ` durationMs=${Date.now() - startedAtMs}`,
    );
  },
);
