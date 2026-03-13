import { onValueCreated } from "firebase-functions/v2/database";
import { admin, db } from "../bootstrap";
import { randomUUID } from "crypto";
import { sendLocalizedNotification } from "../functions/notifications/sendLocalizedNotification";

const RTDB_REGION = "us-central1";
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

  return id;
}

export const onZoneEventCreated = onValueCreated(
  { ref: "zoneEventsByChild/{childUid}/{eventId}", region: RTDB_REGION },
  async (event) => {
    const { childUid, eventId } = event.params as any;
    const ev = event.data?.val();
    if (!ev) return;

    const childSnap = await db.doc(`users/${childUid}`).get();
    if (!childSnap.exists) return;

    const child = childSnap.data() as any;
    const parentUid: string | undefined = child.parentUid;
    if (!parentUid) {
      console.log(`[ZONE_EVENT] child has no parentUid childUid=${childUid}`);
      return;
    }

    const childName = String(child.displayName ?? child.name ?? "Bé");

    const zoneId = String(ev.zoneId ?? "");
    if (!zoneId) {
      console.log(`[ZONE_EVENT] Missing zoneId childUid=${childUid} eventId=${eventId}`);
      return;
    }

    const zoneType = String(ev.zoneType ?? ev.type ?? "").toLowerCase();
    const action = String(ev.action ?? ev.eventType ?? "").toLowerCase();
    const zoneName = String(ev.zoneName ?? "Vùng");

    const isDanger = zoneType === "danger";
    const isEnter = action === "enter";
    const isExit = action === "exit";

    if (!isEnter && !isExit) {
      console.log(
        `[ZONE_EVENT] Skip unknown action childUid=${childUid} eventId=${eventId} action=${action}`
      );
      return;
    }

    const parentKey = isDanger
      ? isEnter
        ? "zone.enter.danger.parent"
        : "zone.exit.danger.parent"
      : isEnter
      ? "zone.enter.safe.parent"
      : "zone.exit.safe.parent";

    const childKey = isDanger
      ? isEnter
        ? "zone.enter.danger.child"
        : "zone.exit.danger.child"
      : isEnter
      ? "zone.enter.safe.child"
      : "zone.exit.safe.child";

    const nowMs = Date.now();
    const eventTs = Number(ev.timestamp ?? nowMs);

    const presenceRef = admin.database().ref(`zonePresenceByChild/${childUid}/${zoneId}`);

    let durationSec = 0;
    let durationMin = 0;
    let enterAt: number | null = null;

    if (isEnter) {
      await presenceRef.set({
        inside: true,
        zoneType,
        zoneName,
        enterAt: eventTs,
        updatedAt: eventTs,
      });
    }

    if (isExit) {
      const snap = await presenceRef.get();
      const pres = snap.exists() ? snap.val() : null;

      enterAt = pres?.enterAt ? Number(pres.enterAt) : null;
      durationSec = enterAt ? Math.max(0, Math.floor((eventTs - enterAt) / 1000)) : 0;
      durationMin = durationSec > 0 ? Math.max(1, Math.round(durationSec / 60)) : 0;

      await presenceRef.remove();
    }

    if (isExit && durationSec > 0) {
      const day = dayInVN(eventTs);
      const zoneStatRef = db.doc(`zoneStatsByChild/${childUid}/days/${day}/zones/${zoneId}`);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(zoneStatRef);
        const cur = snap.exists ? (snap.data() as any) : {};

        const prevTotal = Number(cur.totalSec ?? 0);
        const prevSessions = Number(cur.sessions ?? 0);

        tx.set(
          zoneStatRef,
          {
            zoneId,
            zoneName,
            zoneType,
            totalSec: prevTotal + durationSec,
            sessions: prevSessions + 1,
            lastEnterAt: cur.lastEnterAt ?? (enterAt ?? eventTs),
            lastExitAt: eventTs,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });
    }

    const inboxBody = isExit && durationMin > 0 ? `${zoneName} • ${durationMin} phút` : zoneName;

    const payloadForHistory = {
      childUid: String(childUid),
      childName,
      zoneId,
      zoneType,
      action,
      zoneName,
      eventId: String(eventId),
      timestamp: String(eventTs),
      lat: String(ev.lat ?? ""),
      lng: String(ev.lng ?? ""),
      durationSec: String(durationSec),
      durationMin: String(durationMin),
    };

    const parentNotificationId = await writeInbox({
      toUid: parentUid,
      senderId: "system",
      type: "ZONE",
      eventKey: parentKey,
      body: inboxBody,
      data: payloadForHistory,
      createdAtMs: nowMs,
    });

    const childNotificationId = await writeInbox({
      toUid: childUid,
      senderId: "system",
      type: "ZONE",
      eventKey: childKey,
      body: inboxBody,
      data: payloadForHistory,
      createdAtMs: nowMs,
    });

    const durationSuffix = durationMin > 0 ? ` • ${durationMin} phút` : "";

    await sendLocalizedNotification({
      uid: parentUid,
      type: "zone",
      eventKey: parentKey,
      titleParams: {
        childName,
        zoneName,
        durationSuffix,
      },
      bodyParams: {
        childName,
        zoneName,
        durationSuffix,
      },
      data: {
        childUid: String(childUid),
        childName,
        zoneId,
        zoneType,
        action,
        zoneName,
        eventId: String(eventId),
        notificationId: parentNotificationId,
        timestamp: String(eventTs),
        durationSec: String(durationSec),
        durationMin: String(durationMin),
      },
      channelId: "zone_alerts",
    });

    await sendLocalizedNotification({
      uid: childUid,
      type: "zone",
      eventKey: childKey,
      titleParams: {
        childName,
        zoneName,
        durationSuffix,
      },
      bodyParams: {
        childName,
        zoneName,
        durationSuffix,
      },
      data: {
        childUid: String(childUid),
        childName,
        zoneId,
        zoneType,
        action,
        zoneName,
        eventId: String(eventId),
        notificationId: childNotificationId,
        timestamp: String(eventTs),
        durationSec: String(durationSec),
        durationMin: String(durationMin),
      },
      channelId: "zone_alerts",
    });
  }
);
