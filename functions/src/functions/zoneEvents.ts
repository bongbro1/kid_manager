import { onValueCreated } from "firebase-functions/v2/database";
import { admin, db } from "../bootstrap";
import { randomUUID } from "crypto";

const RTDB_REGION = "us-central1";

function dayInVN(ms: number) {
  // YYYY-MM-DD theo giờ VN (Asia/Ho_Chi_Minh)
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
  senderId: string; // "system" hoặc childUid
  type: string; // "ZONE"
  eventKey: string; // zone.enter.danger.parent / child
  body: string; // zoneName hoặc zoneName + duration
  data: Record<string, any>;
  createdAtMs: number; // để tính day
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

async function sendToUserTokens(opts: {
  uid: string;
  eventKey: string;
  zoneName: string;
  payload: Record<string, string>;
}) {
  // lấy lang của user (để app dịch đúng cả background)
  const userSnap = await db.doc(`users/${opts.uid}`).get();
  const user = userSnap.exists ? (userSnap.data() as any) : {};
  const lang = (user.lang ?? user.locale ?? "vi").toString().toLowerCase();

  const tokensSnap = await db.collection(`users/${opts.uid}/fcmTokens`).get();
  if (tokensSnap.empty) return;

  const tokens: string[] = [];
  const tokenDocIds: string[] = [];

  tokensSnap.forEach((doc) => {
    const t = (doc.data() as any)?.token?.toString();
    if (t && t.length >= 20) {
      tokens.push(t);
      tokenDocIds.push(doc.id);
    }
  });

  if (tokens.length === 0) return;
  const title = opts.eventKey; // hoặc bạn tự build title tiếng việt, nhưng bạn đang dùng eventKey để app dịch
  const body = opts.zoneName;  // hoặc bodyText nếu muốn có phút
  const resp = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title,        // tối thiểu để hệ thống hiện notification khi app background
      body,
    },
    data: {
      type: "ZONE",
      eventKey: opts.eventKey,
      zoneName: opts.zoneName,
      lang,
      ...opts.payload,
    },
    android: { priority: "high" },
    apns: {
      payload: {
        aps: {
          alert: { title, body },   // ✅ iOS hiện được
          sound: "default",
        },
      },
      headers: { "apns-priority": "10" },
    },
  });

  // dọn token chết
  const batch = db.batch();
  resp.responses.forEach((r, idx) => {
    if (r.success) return;

    const code = (r.error as any)?.code?.toString() ?? "";
    const shouldDelete =
      code.includes("messaging/registration-token-not-registered") ||
      code.includes("messaging/invalid-registration-token");

    if (shouldDelete) {
      batch.delete(db.doc(`users/${opts.uid}/fcmTokens/${tokenDocIds[idx]}`));
    }
  });

  await batch.commit();
}

export const onZoneEventCreated = onValueCreated(
  { ref: "zoneEventsByChild/{childUid}/{eventId}", region: RTDB_REGION },
  async (event) => {
    const { childUid, eventId } = event.params as any;
    const ev = event.data?.val();
    if (!ev) return;

    // lấy parentUid
    const childSnap = await db.doc(`users/${childUid}`).get();
    if (!childSnap.exists) return;

    const child = childSnap.data() as any;
    const parentUid: string | undefined = child.parentUid;
    if (!parentUid) return;

    const zoneId = String(ev.zoneId ?? "");
    const zoneType = (ev.zoneType ?? ev.type ?? "").toString(); // safe|danger
    const action = (ev.action ?? ev.eventType ?? "").toString(); // enter|exit
    const zoneName = (ev.zoneName ?? "Vùng").toString();

    const isDanger = zoneType === "danger";
    const isEnter = action === "enter";

    // key cho PARENT / CHILD
    const parentKey =
      isDanger
        ? isEnter
          ? "zone.enter.danger.parent"
          : "zone.exit.danger.parent"
        : isEnter
          ? "zone.enter.safe.parent"
          : "zone.exit.safe.parent";

    const childKey =
      isDanger
        ? isEnter
          ? "zone.enter.danger.child"
          : "zone.exit.danger.child"
        : isEnter
          ? "zone.enter.safe.child"
          : "zone.exit.safe.child";

    const nowMs = Date.now();
    const eventTs = Number(ev.timestamp ?? nowMs);

    // ============================
    // Duration tracking (enter/exit)
    // ============================
    const presenceRef = admin.database().ref(`zonePresenceByChild/${childUid}/${zoneId}`);

    let durationSec = 0;
    let durationMin = 0;
    let enterAt:number | null = null;
    if (action === "enter") {
      await presenceRef.set({
        inside: true,
        zoneType,
        zoneName,
        enterAt: eventTs,
        updatedAt: eventTs,
      });
    }

    if (action === "exit") {
      const snap = await presenceRef.get();
      const pres = snap.exists() ? snap.val() : null;

      const enterAt = pres?.enterAt ? Number(pres.enterAt) : null;
      durationSec = enterAt ? Math.max(0, Math.floor((eventTs - enterAt) / 1000)) : 0;
      durationMin = Math.max(1, Math.round(durationSec / 60));

      await presenceRef.remove();
    }
    // ✅ update daily per-zone stats (chỉ khi exit và có duration)
    if (action === "exit" && durationSec > 0) {
      const day = dayInVN(eventTs); // dùng eventTs để đúng ngày VN
      const zoneStatRef = db.doc(`zoneStatsByChild/${childUid}/days/${day}/zones/${zoneId}`);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(zoneStatRef);
        const cur = snap.exists ? (snap.data() as any) : {};

        const prevTotal = Number(cur.totalSec ?? 0);
        const prevSessions = Number(cur.sessions ?? 0);

        tx.set(
          zoneStatRef,
          {
            zoneId: String(zoneId),
            zoneName: String(zoneName),
            zoneType: String(zoneType),

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

    // body hiển thị (tuỳ chọn): chỉ exit mới thêm phút
    const bodyText =
      action === "exit" && durationMin > 0 ? `${zoneName} • ${durationMin} phút` : zoneName;

    const payloadForHistory = {
      childUid: String(childUid),
      zoneId: String(zoneId),
      zoneType: String(zoneType),
      action: String(action),
      zoneName: String(zoneName),
      eventId: String(eventId),
      timestamp: String(eventTs),
      lat: String(ev.lat ?? ""),
      lng: String(ev.lng ?? ""),
      durationSec: String(durationSec),
      durationMin: String(durationMin),
    };

    // ✅ 1) Lưu inbox lịch sử cho CHA
    await writeInbox({
      toUid: parentUid,
      senderId: "system",
      type: "ZONE",
      eventKey: parentKey,
      body: bodyText,
      data: payloadForHistory,
      createdAtMs: nowMs,
    });

    // ✅ 2) Lưu inbox lịch sử cho CON
    await writeInbox({
      toUid: childUid,
      senderId: "system",
      type: "ZONE",
      eventKey: childKey,
      body: bodyText,
      data: payloadForHistory,
      createdAtMs: nowMs,
    });

    // ✅ 3) Gửi push cho CHA
    const payloadForPush = {
      childUid: String(childUid),
      zoneId: String(zoneId),
      zoneType: String(zoneType),
      action: String(action),
      eventId: String(eventId),
      timestamp: String(eventTs),
      durationSec: String(durationSec),
      durationMin: String(durationMin),
    };

    await sendToUserTokens({
      uid: parentUid,
      eventKey: parentKey,
      zoneName,
      payload: payloadForPush,
    });

    // ✅ 4) Gửi push cho CON
    await sendToUserTokens({
      uid: childUid,
      eventKey: childKey,
      zoneName,
      payload: payloadForPush,
    });

    // (Optional) Nếu bạn vẫn muốn lưu “global” để admin/analytics:
    // await db.collection("notifications").add({
    //   receiverId: parentUid,
    //   senderId: "system",
    //   type: "ZONE",
    //   eventKey: parentKey,
    //   body: bodyText,
    //   data: payloadForHistory,
    //   isRead: false,
    //   status: "sent",
    //   day: dayInVN(nowMs),
    //   createdAt: admin.firestore.FieldValue.serverTimestamp(),
    // });
  }
);