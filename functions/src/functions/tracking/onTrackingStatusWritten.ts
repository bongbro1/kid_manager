import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin, db } from "../../bootstrap";
import { REGION } from "../../config";
import { randomUUID } from "crypto";
import { sendLocalizedNotification } from "../notifications/sendLocalizedNotification";

const FLAP_STATUSES = new Set(["location_stale", "ok"]);
const FLAP_COOLDOWN_MS = 5 * 60 * 1000;

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

function toMillis(value: unknown): number | null {
  if (value instanceof admin.firestore.Timestamp) {
    return value.toMillis();
  }

  if (typeof value === "number" && Number.isFinite(value) && value > 0) {
    return Math.trunc(value);
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed) && parsed > 0) {
      return Math.trunc(parsed);
    }
  }

  if (typeof value === "object" && value !== null) {
    const maybe = value as { seconds?: unknown; _seconds?: unknown };
    const seconds =
      (typeof maybe.seconds === "number" ? maybe.seconds : null) ??
      (typeof maybe._seconds === "number" ? maybe._seconds : null);
    if (seconds != null && Number.isFinite(seconds) && seconds > 0) {
      return Math.trunc(seconds * 1000);
    }
  }

  return null;
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

    const parentEventKey = `tracking.${newStatus}.parent`;

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
      const payloadForParent = {
        ...payloadForHistory,
        toUid: parentUid,
      };

      await writeInbox({
        toUid: parentUid,
        senderId: "system",
        type: "TRACKING",
        eventKey: parentEventKey,
        body: message,
        data: payloadForParent,
        createdAtMs: nowMs,
      });

      await sendLocalizedNotification({
        uid: parentUid,
        type: "TRACKING",
        eventKey: parentEventKey,
        titleParams: { childName },
        bodyParams: { childName },
        data: payloadForParent,
        channelId: "tracking_alerts",
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
