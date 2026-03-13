import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin, db } from "../../bootstrap";
import { REGION } from "../../config";
import { randomUUID } from "crypto";
import { sendLocalizedNotification } from "../notifications/sendLocalizedNotification";

function dayInVN(ms: number) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Ho_Chi_Minh",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(ms));

  const y = parts.find((p) => p.type === "year")?.value ?? "1970";
  const m = parts.find((p) => p.type === "month")?.value ?? "01";
  const d = parts.find((p) => p.type === "day")?.value ?? "01";
  return `${y}-${m}-${d}`;
}

async function writeInbox(opts: {
  toUid: string;
  senderId: string;
  type: string;
  eventKey: string;
  body: string;
  data: Record<string, any>;
  createdAtMs: number;
}) {
  const id = randomUUID();
  const day = dayInVN(opts.createdAtMs);

  await db.doc(`users/${opts.toUid}/notifications/${id}`).set({
    senderId: opts.senderId,
    receiverId: opts.toUid,
    title: opts.eventKey,
    type: opts.type,
    eventKey: opts.eventKey,
    body: opts.body,
    data: opts.data,
    childUid: String(opts.data.childUid ?? ""),
    isRead: false,
    status: "sent",
    day,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function getParentUids(familyId: string, childUid: string): Promise<string[]> {
  const membersSnap = await db.collection(`families/${familyId}/members`).get();

  return membersSnap.docs
    .map((d) => ({ uid: d.id, role: d.get("role") }))
    .filter((x) => x.uid !== childUid && (x.role === "parent" || x.role === "guardian"))
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
    const oldStatus = beforeData ? String(beforeData.status || "") : "";

    if (!newStatus || newStatus === oldStatus) return;

    const childName = String(afterData.childName || "Con");
    const message = String(afterData.message || "");

    const parentEventKey = `tracking.${newStatus}.parent`;
    const childEventKey = `tracking.${newStatus}.child`;

    const nowMs = Date.now();

    const payloadForHistory = {
      childUid,
      childName,
      familyId,
      status: newStatus,
      message,
      timestamp: String(nowMs),
    };

    const parentUids = await getParentUids(familyId, childUid);

    for (const parentUid of parentUids) {
      await writeInbox({
        toUid: parentUid,
        senderId: "system",
        type: "TRACKING",
        eventKey: parentEventKey,
        body: message,
        data: payloadForHistory,
        createdAtMs: nowMs,
      });

      await sendLocalizedNotification({
        uid: parentUid,
        type: "TRACKING",
        eventKey: parentEventKey,
        titleParams: { childName },
        bodyParams: { childName },
        data: {
          childUid,
          childName,
          familyId,
          status: newStatus,
          message,
          timestamp: String(nowMs),
        },
        channelId: "tracking_alerts",
      });
    }

    await writeInbox({
      toUid: childUid,
      senderId: "system",
      type: "TRACKING",
      eventKey: childEventKey,
      body: message,
      data: payloadForHistory,
      createdAtMs: nowMs,
    });

    await sendLocalizedNotification({
      uid: childUid,
      type: "TRACKING",
      eventKey: childEventKey,
      titleParams: { childName },
      bodyParams: { childName },
      data: {
        childUid,
        childName,
        familyId,
        status: newStatus,
        message,
        timestamp: String(nowMs),
      },
      channelId: "tracking_alerts",
    });
  }
);