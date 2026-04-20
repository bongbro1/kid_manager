import { admin, db } from "../bootstrap";
import { chunk, isInvalidTokenErrorCode } from "../helpers";
import {
  deleteInstallationsByIds,
  groupInstallationsByToken,
  listInstallationsByFamilyId,
} from "./fcmInstallations";

const LEGACY_ANDROID_CHANNEL_ID = "sos_channel_v2";

type SosRecipientRecord = {
  installationId: string;
  uid: string;
  platform?: string;
};

type SosTokenGroup = {
  token: string;
  records: SosRecipientRecord[];
};

export type SosPushTargetPlatform = "android" | "ios" | "unknown";

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

export function normalizeSosPushPlatform(
  rawPlatform: string | undefined,
): SosPushTargetPlatform {
  switch ((rawPlatform ?? "").trim().toLowerCase()) {
    case "android":
      return "android";
    case "ios":
      return "ios";
    default:
      return "unknown";
  }
}

export function resolveSosTokenGroupPlatform(
  records: Array<{ platform?: string }>,
): SosPushTargetPlatform {
  const normalized = new Set(
    records.map((record) => normalizeSosPushPlatform(record.platform)),
  );

  normalized.delete("unknown");
  if (normalized.size !== 1) {
    return "unknown";
  }

  return Array.from(normalized)[0] as SosPushTargetPlatform;
}

function buildSosTitle(attempt: number) {
  return attempt > 0 ? "🚨 NHẮC LẠI SOS KHẨN CẤP" : "🚨 SOS KHẨN CẤP";
}

function buildSosBody(attempt: number, createdByName?: string | null) {
  const actorName = createdByName || "Một thành viên";
  return attempt > 0
    ? `${actorName} vẫn chưa được xác nhận an toàn. Chạm để xem vị trí.`
    : `${actorName} đang cầu cứu. Chạm để xem vị trí.`;
}

function buildSosData(params: {
  familyId: string;
  sosId: string;
  createdByUid: string;
  lat?: number | null;
  lng?: number | null;
  createdByName?: string | null;
  attempt: number;
  title: string;
  body: string;
}): Record<string, string> {
  const {
    familyId,
    sosId,
    createdByUid,
    lat,
    lng,
    createdByName,
    attempt,
    title,
    body,
  } = params;

  return {
    type: "SOS",
    familyId: String(familyId),
    sosId: String(sosId),
    createdByUid: String(createdByUid),
    childUid: String(createdByUid),
    lat: lat != null ? String(lat) : "",
    lng: lng != null ? String(lng) : "",
    createdByName: createdByName ? String(createdByName) : "",
    attempt: String(attempt),
    title,
    body,
  };
}

export function buildSosMulticastMessage(params: {
  targetPlatform: SosPushTargetPlatform;
  tokens: string[];
  familyId: string;
  sosId: string;
  createdByUid: string;
  lat?: number | null;
  lng?: number | null;
  createdByName?: string | null;
  attempt: number;
}): admin.messaging.MulticastMessage {
  const {
    targetPlatform,
    tokens,
    familyId,
    sosId,
    createdByUid,
    lat,
    lng,
    createdByName,
    attempt,
  } = params;

  const title = buildSosTitle(attempt);
  const body = buildSosBody(attempt, createdByName);
  const data = buildSosData({
    familyId,
    sosId,
    createdByUid,
    lat,
    lng,
    createdByName,
    attempt,
    title,
    body,
  });

  const apns = {
    headers: {
      "apns-priority": "10",
      "apns-collapse-id": `sos_${sosId}`,
    },
    payload: {
      aps: {
        alert: { title, body },
        sound: "sos.caf",
      },
    },
  } satisfies admin.messaging.ApnsConfig;

  if (targetPlatform === "android") {
    data.androidAlertMode = "local_escalation";

    return {
      tokens,
      data,
      android: {
        priority: "high",
        collapseKey: `sos_${sosId}`,
      },
    };
  }

  if (targetPlatform === "ios") {
    return {
      tokens,
      notification: {
        title,
        body,
      },
      data,
      apns,
    };
  }

  return {
    tokens,
    notification: {
      title,
      body,
    },
    data,
    android: {
      priority: "high",
      collapseKey: `sos_${sosId}`,
      notification: {
        channelId: LEGACY_ANDROID_CHANNEL_ID,
        sound: "sos",
        defaultVibrateTimings: true,
        visibility: "public",
        tag: `sos_${sosId}`,
      },
    },
    apns,
  };
}

function partitionTokenGroupsByPlatform(tokenGroups: SosTokenGroup[]) {
  const partitions: Record<SosPushTargetPlatform, SosTokenGroup[]> = {
    android: [],
    ios: [],
    unknown: [],
  };

  for (const tokenGroup of tokenGroups) {
    partitions[resolveSosTokenGroupPlatform(tokenGroup.records)].push(
      tokenGroup,
    );
  }

  return partitions;
}

async function sendMessageChunk(params: {
  tokenGroups: SosTokenGroup[];
  targetPlatform: SosPushTargetPlatform;
  familyId: string;
  sosId: string;
  createdByUid: string;
  lat?: number | null;
  lng?: number | null;
  createdByName?: string | null;
  attempt: number;
}) {
  const {
    tokenGroups,
    targetPlatform,
    familyId,
    sosId,
    createdByUid,
    lat,
    lng,
    createdByName,
    attempt,
  } = params;

  let success = 0;
  let invalidRemoved = 0;
  let totalAttempt = 0;

  for (const tokenGroupChunk of chunk(tokenGroups, 500)) {
    totalAttempt += tokenGroupChunk.length;

    const resp = await admin.messaging().sendEachForMulticast(
      buildSosMulticastMessage({
        targetPlatform,
        tokens: tokenGroupChunk.map((group) => group.token),
        familyId,
        sosId,
        createdByUid,
        lat,
        lng,
        createdByName,
        attempt,
      }),
    );

    success += resp.successCount;

    const invalidInstallationIds: string[] = [];

    resp.responses.forEach((response, index) => {
      if (response.success) return;

      const code: string | undefined = (response.error as any)?.code;
      if (isInvalidTokenErrorCode(code)) {
        const meta = tokenGroupChunk[index];
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

  const partitions = partitionTokenGroupsByPlatform(tokenGroups);
  let attemptedRecipients = 0;
  let success = 0;
  let invalidTokensRemoved = 0;

  for (const targetPlatform of Object.keys(
    partitions,
  ) as SosPushTargetPlatform[]) {
    const platformTokenGroups = partitions[targetPlatform];
    if (!platformTokenGroups.length) {
      continue;
    }

    const result = await sendMessageChunk({
      tokenGroups: platformTokenGroups,
      targetPlatform,
      familyId,
      sosId,
      createdByUid,
      lat,
      lng,
      createdByName,
      attempt,
    });

    attemptedRecipients += result.attemptedRecipients;
    success += result.success;
    invalidTokensRemoved += result.invalidTokensRemoved;
  }

  return {
    attemptedRecipients,
    success,
    invalidTokensRemoved,
  };
}
