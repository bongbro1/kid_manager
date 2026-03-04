import { onValueCreated } from "firebase-functions/v2/database";
import { admin, db } from "../bootstrap";
const RTDB_REGION = "us-central1"; 

export const onZoneEventCreated = onValueCreated(
  { ref: "zoneEventsByChild/{childUid}/{eventId}", region: RTDB_REGION },
  async (event) => {
    const { childUid, eventId } = event.params as any;
    const data = event.data?.val();
    if (!data) return;

    const childSnap = await db.doc(`users/${childUid}`).get();
    if (!childSnap.exists) return;

    const child = childSnap.data() as any;
    const parentUid: string | undefined = child.parentUid;
    if (!parentUid) return;

    const zoneType = (data.zoneType ?? data.type ?? "").toString(); // safe|danger
    const action = (data.action ?? data.eventType ?? data.type ?? "").toString(); // enter|exit
    const zoneName = (data.zoneName ?? "Vùng").toString();

    const isDanger = zoneType === "danger";
    const isEnter = action === "enter";

    const title = isDanger
      ? (isEnter ? "⚠️ Bé vào vùng nguy hiểm" : "✅ Bé rời vùng nguy hiểm")
      : (isEnter ? "✅ Bé vào vùng an toàn" : "ℹ️ Bé rời vùng an toàn");

    const body = `${zoneName}`;

    await db.collection("notifications").add({
      toUid: parentUid,
      type: "ZONE",
      title,
      body,
      data: {
        childUid,
        zoneId: String(data.zoneId ?? ""),
        zoneType: String(zoneType),
        action: String(action),
        zoneName: String(zoneName),
        lat: String(data.lat ?? ""),
        lng: String(data.lng ?? ""),
        timestamp: String(data.timestamp ?? Date.now()),
        eventId: String(eventId),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);