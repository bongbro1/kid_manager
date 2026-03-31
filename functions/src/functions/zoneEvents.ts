import {
  onValueCreated,
  onValueWritten,
} from "firebase-functions/v2/database";
import { admin, db } from "../bootstrap";
import { createGlobalNotificationRecord } from "../services/globalNotifications";
import {
  computeCanonicalZoneEvents,
  isCanonicalZoneEventRecord,
  parseTrustedZones,
  parseZoneObservation,
  parseZonePresenceRecord,
  type CanonicalZoneEventRecord,
} from "../services/zoneEventEvaluator";
import { assessTrustedLiveLocation } from "../services/trustedLocationService";
import { parseLiveLocationRecord } from "../services/safeRouteMonitoringService";

const RTDB_REGION = "us-central1";

function formatZoneDurationForInbox(durationSec: number): string {
  const normalizedSeconds = durationSec <= 0 ? 0 : durationSec;
  const totalMinutes =
    normalizedSeconds <= 0 ? 0 : Math.floor((normalizedSeconds + 59) / 60);
  const days = Math.floor(totalMinutes / (24 * 60));
  const hours = Math.floor((totalMinutes % (24 * 60)) / 60);
  const minutes = totalMinutes % 60;

  if (days <= 0 && hours <= 0) {
    return `${minutes} phút`;
  }
  if (days <= 0) {
    return `${hours} giờ ${minutes} phút`;
  }

  const parts = [`${days} ngày`];
  if (hours > 0) {
    parts.push(`${hours} giờ`);
  }
  if (minutes > 0) {
    parts.push(`${minutes} phút`);
  }
  return parts.join(" ");
}

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

async function writeZoneExitStats(
  childUid: string,
  eventRecord: CanonicalZoneEventRecord,
) {
  if (eventRecord.action !== "exit" || eventRecord.durationSec <= 0) {
    return;
  }

  const day = dayInVN(eventRecord.timestamp);
  const zoneStatRef = db.doc(
    `zoneStatsByChild/${childUid}/days/${day}/zones/${eventRecord.zoneId}`,
  );

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(zoneStatRef);
    const current = snap.exists ? (snap.data() as Record<string, unknown>) : {};

    const previousTotal = Number(current.totalSec ?? 0);
    const previousSessions = Number(current.sessions ?? 0);

    tx.set(
      zoneStatRef,
      {
        zoneId: eventRecord.zoneId,
        zoneName: eventRecord.zoneName,
        zoneType: eventRecord.zoneType,
        totalSec: previousTotal + eventRecord.durationSec,
        sessions: previousSessions + 1,
        lastEnterAt:
          current.lastEnterAt ?? (eventRecord.enterAt ?? eventRecord.timestamp),
        lastExitAt: eventRecord.timestamp,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function persistCanonicalZoneEvent(
  childUid: string,
  eventRecord: CanonicalZoneEventRecord,
) {
  const presenceRef = admin
    .database()
    .ref(`zonePresenceByChild/${childUid}/${eventRecord.zoneId}`);

  if (eventRecord.action === "enter") {
    const txResult = await presenceRef.transaction((current) => {
      const presence = parseZonePresenceRecord(current);
      if (presence?.inside === true) {
        return;
      }

      return {
        inside: true,
        zoneType: eventRecord.zoneType,
        zoneName: eventRecord.zoneName,
        enterAt: eventRecord.timestamp,
        updatedAt: eventRecord.timestamp,
        source: eventRecord.source,
      };
    });

    if (!txResult.committed) {
      return false;
    }
  } else {
    const currentPresenceSnap = await presenceRef.get();
    const currentPresence = currentPresenceSnap.exists()
      ? parseZonePresenceRecord(currentPresenceSnap.val())
      : null;
    if (currentPresence == null) {
      return false;
    }

    const expectedEnterAt = currentPresence.enterAt;
    const txResult = await presenceRef.transaction((current) => {
      const presence = parseZonePresenceRecord(current);
      if (presence == null || !presence.inside) {
        return;
      }
      if (presence.enterAt !== expectedEnterAt) {
        return;
      }

      return null;
    });

    if (!txResult.committed) {
      return false;
    }

    await writeZoneExitStats(childUid, {
      ...eventRecord,
      enterAt: expectedEnterAt,
      durationSec: Math.max(
        0,
        Math.floor((eventRecord.timestamp - expectedEnterAt) / 1000),
      ),
      durationMin:
        eventRecord.timestamp > expectedEnterAt
          ? Math.max(
              1,
              Math.round((eventRecord.timestamp - expectedEnterAt) / 60000),
            )
          : 0,
    });
  }

  await admin
    .database()
    .ref(`zoneEventsByChild/${childUid}`)
    .push()
    .set({
      ...eventRecord,
      createdAt: Date.now(),
    });
  return true;
}

export const evaluateZoneEventsFromCurrentLocation = onValueWritten(
  { ref: "locations/{childUid}/current", region: RTDB_REGION },
  async (event) => {
    const childUid = String(event.params.childUid ?? "").trim();
    const current = event.data.after.val();
    if (!childUid || !current) {
      return;
    }

    const rawLocation = parseLiveLocationRecord(childUid, current);
    const previousTrustedSnap = await admin
      .database()
      .ref(`live_locations/${childUid}`)
      .get();
    const previousTrusted =
      previousTrustedSnap.exists() && previousTrustedSnap.val()
        ? parseLiveLocationRecord(childUid, previousTrustedSnap.val())
        : null;
    const trust = assessTrustedLiveLocation({
      current: rawLocation,
      previousTrusted,
    });
    if (!trust.safetyEligible) {
      console.log(
        `[ZONE_EVENT_EVALUATOR] ignore untrusted current location childUid=${childUid} reason=${trust.reason}`,
      );
      return;
    }

    const observation = parseZoneObservation(childUid, current);
    if (observation == null) {
      console.log(
        `[ZONE_EVENT_EVALUATOR] ignore invalid current location childUid=${childUid}`,
      );
      return;
    }

    const [zonesSnap, presenceSnap] = await Promise.all([
      admin.database().ref(`zonesByChild/${childUid}`).get(),
      admin.database().ref(`zonePresenceByChild/${childUid}`).get(),
    ]);

    const zones = parseTrustedZones(zonesSnap.exists() ? zonesSnap.val() : null);
    if (!zones.length) {
      return;
    }

    const canonicalEvents = computeCanonicalZoneEvents({
      childUid,
      observation,
      zones,
      presenceByZone:
        presenceSnap.exists() && typeof presenceSnap.val() === "object"
          ? (presenceSnap.val() as Record<string, unknown>)
          : {},
    });

    for (const canonicalEvent of canonicalEvents) {
      try {
        await persistCanonicalZoneEvent(childUid, canonicalEvent);
      } catch (error) {
        console.error(
          `[ZONE_EVENT_EVALUATOR] persist failed childUid=${childUid} zoneId=${canonicalEvent.zoneId} action=${canonicalEvent.action}`,
          error,
        );
      }
    }
  },
);

export const onZoneEventCreated = onValueCreated(
  { ref: "zoneEventsByChild/{childUid}/{eventId}", region: RTDB_REGION },
  async (event) => {
    const { childUid, eventId } = event.params as {
      childUid: string;
      eventId: string;
    };
    const rawEvent = event.data?.val();
    if (!isCanonicalZoneEventRecord(rawEvent)) {
      console.log(
        `[ZONE_EVENT] ignore non-canonical event childUid=${childUid} eventId=${eventId}`,
      );
      return;
    }

    const eventRecord = rawEvent as CanonicalZoneEventRecord;
    const childSnap = await db.doc(`users/${childUid}`).get();
    if (!childSnap.exists) {
      return;
    }

    const child = childSnap.data() as Record<string, unknown>;
    const parentUid =
      typeof child.parentUid === "string" ? child.parentUid.trim() : "";
    if (!parentUid) {
      console.log(`[ZONE_EVENT] child has no parentUid childUid=${childUid}`);
      return;
    }

    const childName = String(child.displayName ?? child.name ?? "Bé");
    const isDanger = eventRecord.zoneType === "danger";
    const isEnter = eventRecord.action === "enter";

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

    const inboxBody =
      !isEnter && eventRecord.durationSec > 0
        ? `${eventRecord.zoneName} • ${formatZoneDurationForInbox(
            eventRecord.durationSec,
          )}`
        : eventRecord.zoneName;

    const payloadForHistory = {
      childUid,
      childName,
      zoneId: eventRecord.zoneId,
      zoneType: eventRecord.zoneType,
      action: eventRecord.action,
      zoneName: eventRecord.zoneName,
      eventId: String(eventId),
      timestamp: String(eventRecord.timestamp),
      lat: String(eventRecord.lat),
      lng: String(eventRecord.lng),
      durationSec: String(eventRecord.durationSec),
      durationMin: String(eventRecord.durationMin),
      canonical: "true",
      source: eventRecord.source,
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
  },
);
