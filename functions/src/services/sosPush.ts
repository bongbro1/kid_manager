import { admin, db } from "../bootstrap";
import { chunk, isInvalidTokenErrorCode } from "../helpers";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByFamilyId,
} from "./fcmInstallations";

async function listAdultManagerRecipientUids(
  familyId: string,
): Promise<Set<string>> {
  const membersSnap = await db.collection(`families/${familyId}/members`).get();
  const recipientUids = new Set<string>();

  for (const doc of membersSnap.docs) {
    const data = doc.data() ?? {};
    const role = typeof data.role === "string" ? data.role.trim() : "";
    if (role !== "parent" && role !== "guardian") {
      continue;
    }

    const uid =
      typeof data.uid === "string" && data.uid.trim()
        ? data.uid.trim()
        : doc.id.trim();
    if (!uid) {
      continue;
    }

    recipientUids.add(uid);
  }

  return recipientUids;
}

export async function sendSosPush(params: {
  familyId: string;
  sosId: string;
  createdByUid: string;
  lat?: number | null;
  lng?: number | null;
  createdByName?: string | null;
  attempt?: number;
}) {
  const {
    familyId,
    sosId,
    createdByUid,
    lat,
    lng,
    createdByName,
    attempt = 0,
  } = params;

  const recipientUids = await listAdultManagerRecipientUids(familyId);

  const tokenGroups = groupInstallationsByToken(
    (await listInstallationsByFamilyId(familyId)).filter(
      (installation) =>
        installation.uid !== createdByUid &&
        recipientUids.has(installation.uid),
    ),
  ).map((group) => ({
    token: group.token,
    records: group.records.map((installation) => ({
      installationId: installation.installationId,
      uid: installation.uid,
      platform: installation.platform ?? undefined,
    })),
  }));

  if (!tokenGroups.length) {
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
      createdByUid: String(createdByUid),
      childUid: String(createdByUid),
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

  const tokenChunks = chunk(tokenGroups, 500);
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

    const invalidInstallationIds: string[] = [];

    resp.responses.forEach((r, i) => {
      if (r.success) return;

      const code: string | undefined = (r.error as any)?.code;
      if (isInvalidTokenErrorCode(code)) {
        const meta = c[i];
        if (!meta) return;
        invalidRemoved += meta.records.length;
        invalidInstallationIds.push(
          ...meta.records.map((record) => record.installationId),
        );
      }
    });

    await deleteInstallationsByIds(invalidInstallationIds);
  }

  return {
    attemptedRecipients: totalAttempt,
    success,
    invalidTokensRemoved: invalidRemoved,
  };
}
