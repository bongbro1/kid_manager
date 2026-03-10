import { admin, db } from "../bootstrap";
import { chunk, isInvalidTokenErrorCode } from "../helpers";

export async function sendSosPush(params: {
  familyId: string;
  sosId: string;
  childUid: string;
  lat?: number | null;
  lng?: number | null;
  createdByName?: string | null;
  attempt?: number;
}) {
  const {
    familyId,
    sosId,
    childUid,
    lat,
    lng,
    createdByName,
    attempt = 0,
  } = params;

  const tokenSnap = await db.collection(`families/${familyId}/fcmTokens`).get();

  const tokens: Array<{
    token: string;
    tokenHash: string;
    uid: string;
    platform?: string;
  }> = [];

  tokenSnap.forEach((doc) => {
    const data = doc.data() as any;
    const token: string | undefined = data.token;
    const uid: string | undefined = data.uid;
    if (!token || !uid) return;

    // Không gửi lại cho chính người tạo SOS
    if (uid === childUid) return;

    tokens.push({
      token,
      tokenHash: doc.id,
      uid,
      platform: data.platform,
    });
  });

  if (!tokens.length) {
    return {
      attemptedRecipients: 0,
      success: 0,
      invalidTokensRemoved: 0,
    };
  }

  const title =
    attempt > 0 ? "🚨 NHẮC LẠI SOS KHẨN CẤP" : "🚨 SOS KHẨN CẤP";

  const body =
    attempt > 0
      ? `${createdByName || "Một thành viên"} vẫn chưa được xác nhận an toàn. Chạm để xem vị trí.`
      : `${createdByName || "Một thành viên"} đang cầu cứu. Chạm để xem vị trí.`;

  const baseMessage: Omit<admin.messaging.MulticastMessage, "tokens"> = {
    notification: {
      title,
      body,
    },
    data: {
      type: "SOS",
      familyId: String(familyId),
      sosId: String(sosId),
      childUid: String(childUid),
      lat: lat != null ? String(lat) : "",
      lng: lng != null ? String(lng) : "",
      createdByName: createdByName ? String(createdByName) : "",
      attempt: String(attempt),
    },
    android: {
      priority: "high",
      collapseKey: `sos_${sosId}`,
      notification: {
        channelId: "sos_channel_v2",
        sound: "sos",
        defaultVibrateTimings: true,
        visibility: "public",
        tag: `sos_${sosId}`,
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
        "apns-collapse-id": `sos_${sosId}`,
      },
      payload: {
        aps: {
          sound: "sos.caf",
        },
      },
    },
  };

  const tokenChunks = chunk(tokens, 500);
  let success = 0;
  let invalidRemoved = 0;
  let totalAttempt = 0;

  for (const c of tokenChunks) {
    totalAttempt += c.length;

    const resp = await admin.messaging().sendEachForMulticast({
      ...baseMessage,
      tokens: c.map((x) => x.token),
    });

    success += resp.successCount;

    const batch = db.batch();
    let hasDeletes = false;

    resp.responses.forEach((r, i) => {
      if (r.success) return;

      const code: string | undefined = (r.error as any)?.code;
      if (isInvalidTokenErrorCode(code)) {
        const meta = c[i];
        invalidRemoved++;
        batch.delete(db.doc(`families/${familyId}/fcmTokens/${meta.tokenHash}`));
        batch.delete(db.doc(`users/${meta.uid}/fcmTokens/${meta.tokenHash}`));
        hasDeletes = true;
      }
    });

    if (hasDeletes) {
      await batch.commit();
    }
  }

  return {
    attemptedRecipients: totalAttempt,
    success,
    invalidTokensRemoved: invalidRemoved,
  };
}