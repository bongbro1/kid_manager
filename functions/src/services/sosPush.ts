import { admin } from "../bootstrap";
import { chunk, isInvalidTokenErrorCode } from "../helpers";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByFamilyId,
} from "./fcmInstallations";

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

  const tokenGroups = groupInstallationsByToken(
    (await listInstallationsByFamilyId(familyId)).filter(
      (installation) => installation.uid !== childUid
    )
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
    attempt > 0 ? "ðŸš¨ NHáº®C Láº I SOS KHáº¨N Cáº¤P" : "ðŸš¨ SOS KHáº¨N Cáº¤P";

  const body =
    attempt > 0
      ? `${createdByName || "Má»™t thÃ nh viÃªn"} váº«n chÆ°a Ä‘Æ°á»£c xÃ¡c nháº­n an toÃ n. Cháº¡m Ä‘á»ƒ xem vá»‹ trÃ­.`
      : `${createdByName || "Má»™t thÃ nh viÃªn"} Ä‘ang cáº§u cá»©u. Cháº¡m Ä‘á»ƒ xem vá»‹ trÃ­.`;

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
          ...meta.records.map((record) => record.installationId)
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
