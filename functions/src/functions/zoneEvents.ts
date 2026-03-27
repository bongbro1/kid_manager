import { onValueCreated } from "firebase-functions/v2/database";
import { admin, db } from "../bootstrap";
import { createGlobalNotificationRecord } from "../services/globalNotifications";

const RTDB_REGION = "us-central1";

function dayInVN(timestampMs: number): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Asia/Ho_Chi_Minh",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(new Date(timestampMs));

  const year = parts.find((part) => part.type === "year")?.value ?? "1970";
  const month = parts.find((part) => part.type === "month")?.value ?? "01";
  const day = parts.find((part) => part.type === "day")?.value ?? "01";

  return `${year}-${month}-${day}`;
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

    await createGlobalNotificationRecord({
      receiverId: parentUid,
      senderId: "system",
      type: "ZONE",
      title: parentKey,
      body: inboxBody,
      eventKey: parentKey,
      data: payloadForHistory,
    });

    await createGlobalNotificationRecord({
      receiverId: childUid,
      senderId: "system",
      type: "ZONE",
      title: childKey,
      body: inboxBody,
      eventKey: childKey,
      data: payloadForHistory,
    });
  }
);
