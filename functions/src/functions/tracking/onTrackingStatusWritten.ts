import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin } from "../../bootstrap";
import { REGION } from "../../config";
import { createGlobalNotificationRecord } from "../../services/globalNotifications";
import {
  buildTrackingLocationNotificationRecord,
  isTrackingLocationStatus,
  listManagedAdultRecipientUids,
  resolveUserLanguage,
  toMillis,
} from "../../services/trackingLocationNotifications";
import {
  buildTrackingWatchStatusUpdate,
  TRACKING_WATCH_COLLECTION,
} from "../../services/trackingWatch";

const FLAP_STATUSES = new Set(["location_stale", "ok"]);
const FLAP_COOLDOWN_MS = 5 * 60 * 1000;

export const onTrackingStatusWritten = onDocumentWritten(
  {
    region: REGION,
    document: "families/{familyId}/trackingStatus/{childUid}",
  },
  async (event) => {
    const after = event.data?.after;
    const before = event.data?.before;

    if (!after?.exists) return;

    const afterData = after.data();
    if (!afterData) return;

    const beforeData = before?.exists ? before.data() : null;

    const familyId = String(event.params.familyId);
    const childUid = String(event.params.childUid);

    const newStatus = String(afterData.status || "");
    if (!isTrackingLocationStatus(newStatus)) {
      return;
    }
    const statusUpdatedAtMs =
      toMillis(afterData.updatedAt) ??
      toMillis(afterData.updatedAtMs) ??
      Date.now();
    await admin
      .firestore()
      .collection(TRACKING_WATCH_COLLECTION)
      .doc(childUid)
      .set(
        buildTrackingWatchStatusUpdate({
          familyId,
          childUid,
          status: newStatus,
          updatedAtMs: statusUpdatedAtMs,
        }),
        { merge: true },
      );

    const oldStatus = beforeData ? String(beforeData.status || "") : "";

    if (!newStatus || newStatus === oldStatus) return;

    const childName = String(afterData.childName || "Con");

    const nowMs = Date.now();
    const lastNotifiedAtMs = toMillis(afterData.lastNotifiedAt ?? afterData.lastNotifiedAtMs);

    if (
      FLAP_STATUSES.has(newStatus) &&
      lastNotifiedAtMs != null &&
      nowMs - lastNotifiedAtMs < FLAP_COOLDOWN_MS
    ) {
      console.log(
        `[TRACKING] Skip cooldown status=${newStatus} childUid=${childUid}`
      );
      return;
    }

    const parentUids = await listManagedAdultRecipientUids({ familyId, childUid });

    for (const parentUid of parentUids) {
      const locale = await resolveUserLanguage(parentUid);
      const notification = buildTrackingLocationNotificationRecord({
        locale,
        childUid,
        childName,
        familyId,
        status: newStatus,
        nowMs,
      });

      await createGlobalNotificationRecord({
        receiverId: parentUid,
        senderId: "system",
        type: "TRACKING",
        title: notification.title,
        body: notification.body,
        eventKey: notification.eventKey,
        eventCategory: notification.eventCategory,
        expiresAt: notification.expiresAt,
        data: notification.data,
        familyId,
      });
    }

    await after.ref.set(
      {
        lastNotifiedStatus: newStatus,
        lastNotifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastNotifiedAtMs: nowMs,
      },
      { merge: true }
    );
  }
);
