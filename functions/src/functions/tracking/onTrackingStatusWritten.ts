import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin, db } from "../../bootstrap";
import { REGION } from "../../config";
import { createGlobalNotificationRecord } from "../../services/globalNotifications";
import {
  buildTrackingLocationNotificationRecord,
  isTrackingLocationStatus,
  resolveUserLanguage,
  shouldReceiveTrackingLocationNotification,
  toMillis,
} from "../../services/trackingLocationNotifications";

const FLAP_STATUSES = new Set(["location_stale", "ok"]);
const FLAP_COOLDOWN_MS = 5 * 60 * 1000;

async function getParentUids(familyId: string, childUid: string): Promise<string[]> {
  const membersSnap = await db.collection(`families/${familyId}/members`).get();

  return membersSnap.docs
    .map((d) => ({
      uid: d.id,
      role: String(d.get("role") ?? ""),
      data: d.data() as Record<string, unknown>,
    }))
    .filter((member) =>
      shouldReceiveTrackingLocationNotification({
        memberUid: member.uid,
        memberRole: member.role,
        memberData: member.data,
        childUid,
      })
    )
    .map((x) => x.uid);
}

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

    const parentUids = await getParentUids(familyId, childUid);

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
