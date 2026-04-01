import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../bootstrap";
import { REGION, TZ } from "../config";
import { mustString, normalizeTimeZone, zonedDateParts } from "../helpers";
import { parseLiveLocationRecord } from "../services/safeRouteMonitoringService";
import {
  listTrackableLocationMembersForViewer,
  requireLocationViewerAccess,
} from "../services/locationAccess";

const DAY_KEY_RE = /^\d{4}-\d{2}-\d{2}$/;
const DEFAULT_HISTORY_CHUNK_LIMIT = 250;
const MAX_HISTORY_CHUNK_LIMIT = 500;
const CURRENT_HISTORY_PARTITION_VERSION = 2;

function requireDayKey(value: unknown): string {
  const dayKey = mustString(value, "dayKey");
  if (!DAY_KEY_RE.test(dayKey)) {
    throw new HttpsError("invalid-argument", "dayKey must be YYYY-MM-DD");
  }
  return dayKey;
}

function parseOptionalTimestamp(value: unknown, fieldName: string): number | null {
  if (value == null) return null;

  const parsed =
    typeof value === "number" ? value : Number.parseInt(String(value), 10);
  if (!Number.isFinite(parsed) || parsed < 0) {
    throw new HttpsError("invalid-argument", `${fieldName} must be a positive integer`);
  }
  return Math.trunc(parsed);
}

function parseChunkLimit(value: unknown): number {
  if (value == null) return DEFAULT_HISTORY_CHUNK_LIMIT;

  const parsed =
    typeof value === "number" ? value : Number.parseInt(String(value), 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new HttpsError("invalid-argument", "limit must be a positive integer");
  }

  return Math.min(Math.trunc(parsed), MAX_HISTORY_CHUNK_LIMIT);
}

function parseOptionalMinuteOfDay(
  value: unknown,
  fieldName: string,
): number | null {
  if (value == null) return null;

  const parsed =
    typeof value === "number" ? value : Number.parseInt(String(value), 10);
  if (!Number.isFinite(parsed) || parsed < 0 || parsed >= 24 * 60) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} must be an integer between 0 and 1439`
    );
  }
  return Math.trunc(parsed);
}

function normalizeLiveLocationMap(raw: unknown): Record<string, any> {
  if (!raw || typeof raw !== "object") {
    return {};
  }
  return raw as Record<string, any>;
}

function shiftDayKey(dayKey: string, deltaDays: number): string {
  const [year, month, day] = dayKey.split("-").map((part) => Number(part));
  const date = new Date(Date.UTC(year, month - 1, day + deltaDays));
  return [
    date.getUTCFullYear().toString().padStart(4, "0"),
    String(date.getUTCMonth() + 1).padStart(2, "0"),
    String(date.getUTCDate()).padStart(2, "0"),
  ].join("-");
}

function parseHistoryPointTimestamp(key: string, rawPoint: unknown): number | null {
  if (rawPoint && typeof rawPoint === "object") {
    const timestamp = (rawPoint as Record<string, unknown>).timestamp;
    if (typeof timestamp === "number" && Number.isFinite(timestamp)) {
      return Math.trunc(timestamp);
    }
    if (typeof timestamp === "string") {
      const parsed = Number.parseInt(timestamp, 10);
      if (Number.isFinite(parsed)) {
        return parsed;
      }
    }
  }

  const fromKey = Number.parseInt(key, 10);
  return Number.isFinite(fromKey) ? fromKey : null;
}

type HistoryPartitionContext = {
  timeZone: string;
  partitionVersion: number;
  cutoverAt: number | null;
};

async function readHistoryPartitionContext(
  childUid: string,
): Promise<HistoryPartitionContext> {
  const [metaSnap, userSnap] = await Promise.all([
    admin.database().ref(`locations/${childUid}/meta`).get(),
    admin.firestore().collection("users").doc(childUid).get(),
  ]);

  const meta =
    metaSnap.exists() && metaSnap.val() && typeof metaSnap.val() === "object"
      ? (metaSnap.val() as Record<string, unknown>)
      : {};
  const userData = userSnap.data() ?? {};

  const cutoverRaw = meta.historyPartitionCutoverAt;
  const partitionVersionRaw = meta.historyPartitionVersion;
  const cutoverAt =
    typeof cutoverRaw === "number"
      ? Math.trunc(cutoverRaw)
      : Number.parseInt(String(cutoverRaw ?? ""), 10);
  const partitionVersion =
    typeof partitionVersionRaw === "number"
      ? Math.trunc(partitionVersionRaw)
      : Number.parseInt(String(partitionVersionRaw ?? ""), 10);

  return {
    timeZone: normalizeTimeZone(meta.historyTimeZone ?? userData.timezone, TZ),
    partitionVersion: Number.isFinite(partitionVersion)
      ? partitionVersion
      : 1,
    cutoverAt: Number.isFinite(cutoverAt) ? cutoverAt : null,
  };
}

async function readHistoryBucket(params: {
  childUid: string;
  dayKey: string;
  fromTs: number | null;
  toTs: number | null;
}) {
  const { childUid, dayKey, fromTs, toTs } = params;

  let query = admin
    .database()
    .ref(`locations/${childUid}/historyByDay/${dayKey}`)
    .orderByKey();

  if (fromTs != null) {
    query = query.startAt(String(fromTs));
  }
  if (toTs != null) {
    query = query.endAt(String(toTs));
  }

  const snap = await query.get();
  if (!snap.exists() || !snap.val() || typeof snap.val() !== "object") {
    return {} as Record<string, any>;
  }

  return snap.val() as Record<string, any>;
}

function shouldReadLegacyNeighborBuckets(params: {
  requestedDayKey: string;
  partitionContext: HistoryPartitionContext;
}) {
  const { requestedDayKey, partitionContext } = params;
  if (partitionContext.partitionVersion < CURRENT_HISTORY_PARTITION_VERSION) {
    return true;
  }

  if (partitionContext.cutoverAt == null) {
    return true;
  }

  const cutoverDayKey = zonedDateParts(
    partitionContext.cutoverAt,
    partitionContext.timeZone,
  ).dayKey;
  return requestedDayKey <= cutoverDayKey;
}

async function loadHistoryItemsForRequestedDay(params: {
  childUid: string;
  requestedDayKey: string;
  cursorAfterTs: number | null;
  fromTs: number | null;
  toTs: number | null;
  startMinuteOfDay: number | null;
  endMinuteOfDay: number | null;
}) {
  const {
    childUid,
    requestedDayKey,
    fromTs,
    toTs,
    startMinuteOfDay,
    endMinuteOfDay,
  } = params;
  const partitionContext = await readHistoryPartitionContext(childUid);
  const readLegacyNeighbors = shouldReadLegacyNeighborBuckets({
    requestedDayKey,
    partitionContext,
  });

  const bucketDayKeys = new Set<string>([requestedDayKey]);
  if (readLegacyNeighbors) {
    bucketDayKeys.add(shiftDayKey(requestedDayKey, -1));
    bucketDayKeys.add(shiftDayKey(requestedDayKey, 1));
  }

  const bucketEntries = await Promise.all(
    Array.from(bucketDayKeys).map(async (dayKey) => {
      const bucket = await readHistoryBucket({
        childUid,
        dayKey,
        fromTs,
        toTs,
      });
      return [dayKey, bucket] as const;
    }),
  );

  const dedupedItems = new Map<number, Record<string, any>>();
  for (const [, bucket] of bucketEntries) {
    const keys = Object.keys(bucket);
    for (const key of keys) {
      const rawPoint = bucket[key];
      if (!rawPoint || typeof rawPoint !== "object") {
        continue;
      }

      const timestamp = parseHistoryPointTimestamp(key, rawPoint);
      if (timestamp == null) {
        continue;
      }
      if (params.cursorAfterTs != null && timestamp <= params.cursorAfterTs) {
        continue;
      }
      if (fromTs != null && timestamp < fromTs) {
        continue;
      }
      if (toTs != null && timestamp > toTs) {
        continue;
      }

      const localParts = zonedDateParts(timestamp, partitionContext.timeZone);
      if (localParts.dayKey !== requestedDayKey) {
        continue;
      }
      if (
        startMinuteOfDay != null &&
        localParts.minutesOfDay < startMinuteOfDay
      ) {
        continue;
      }
      if (
        endMinuteOfDay != null &&
        localParts.minutesOfDay > endMinuteOfDay
      ) {
        continue;
      }

      const point = {
        ...rawPoint,
        timestamp,
      } as Record<string, any>;
      dedupedItems.set(timestamp, point);
    }
  }

  return Array.from(dedupedItems.values()).sort(
    (left, right) =>
      Number(left.timestamp ?? 0) - Number(right.timestamp ?? 0),
  );
}

async function readMissingFamilyLiveLocations(params: {
  familyId: string;
  missingMemberUids: string[];
}) {
  const { familyId, missingMemberUids } = params;
  if (missingMemberUids.length === 0) {
    return {};
  }

  const entries = await Promise.all(
    missingMemberUids.map(async (memberUid) => {
      const currentSnap = await admin
        .database()
        .ref(`locations/${memberUid}/current`)
        .get();
      if (!currentSnap.exists()) {
        return [memberUid, null] as const;
      }

      const liveLocation = parseLiveLocationRecord(memberUid, currentSnap.val());
      await admin
        .database()
        .ref(`live_locations_by_family/${familyId}/${memberUid}`)
        .set(liveLocation);
      return [memberUid, liveLocation] as const;
    })
  );

  return Object.fromEntries(entries.filter((entry) => entry[1] != null));
}

export const getChildLocationCurrent = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const viewerUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  await requireLocationViewerAccess(viewerUid, childUid);

  const curSnap = await admin.database().ref(`locations/${childUid}/current`).get();
  return { ok: true, childUid, current: curSnap.exists() ? curSnap.val() : null };
});

export const getChildHistoryByDay = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const viewerUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const dayKey = requireDayKey(req.data?.dayKey);
  const fromTs = parseOptionalTimestamp(req.data?.fromTs, "fromTs");
  const toTs = parseOptionalTimestamp(req.data?.toTs, "toTs");
  const startMinuteOfDay = parseOptionalMinuteOfDay(
    req.data?.startMinuteOfDay,
    "startMinuteOfDay",
  );
  const endMinuteOfDay = parseOptionalMinuteOfDay(
    req.data?.endMinuteOfDay,
    "endMinuteOfDay",
  );

  if (fromTs != null && toTs != null && fromTs > toTs) {
    throw new HttpsError("invalid-argument", "fromTs must be <= toTs");
  }
  if (
    startMinuteOfDay != null &&
    endMinuteOfDay != null &&
    startMinuteOfDay > endMinuteOfDay
  ) {
    throw new HttpsError(
      "invalid-argument",
      "startMinuteOfDay must be <= endMinuteOfDay",
    );
  }

  await requireLocationViewerAccess(viewerUid, childUid);

  const items = await loadHistoryItemsForRequestedDay({
    childUid,
    requestedDayKey: dayKey,
    cursorAfterTs: null,
    fromTs,
    toTs,
    startMinuteOfDay,
    endMinuteOfDay,
  });

  const history = Object.fromEntries(
    items.map((item) => [String(item.timestamp), item] as const)
  );
  return { ok: true, childUid, dayKey, history };
});

export const getChildHistoryChunk = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const viewerUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const dayKey = requireDayKey(req.data?.dayKey);
  const cursorAfterTs = parseOptionalTimestamp(req.data?.cursorAfterTs, "cursorAfterTs");
  const fromTs = parseOptionalTimestamp(req.data?.fromTs, "fromTs");
  const toTs = parseOptionalTimestamp(req.data?.toTs, "toTs");
  const startMinuteOfDay = parseOptionalMinuteOfDay(
    req.data?.startMinuteOfDay,
    "startMinuteOfDay",
  );
  const endMinuteOfDay = parseOptionalMinuteOfDay(
    req.data?.endMinuteOfDay,
    "endMinuteOfDay",
  );
  const limit = parseChunkLimit(req.data?.limit);

  if (fromTs != null && toTs != null && fromTs > toTs) {
    throw new HttpsError("invalid-argument", "fromTs must be <= toTs");
  }
  if (
    startMinuteOfDay != null &&
    endMinuteOfDay != null &&
    startMinuteOfDay > endMinuteOfDay
  ) {
    throw new HttpsError(
      "invalid-argument",
      "startMinuteOfDay must be <= endMinuteOfDay",
    );
  }

  await requireLocationViewerAccess(viewerUid, childUid);
  const filteredItems = await loadHistoryItemsForRequestedDay({
    childUid,
    requestedDayKey: dayKey,
    cursorAfterTs,
    fromTs,
    toTs,
    startMinuteOfDay,
    endMinuteOfDay,
  });
  const hasMore = filteredItems.length > limit;
  const pageItems = hasMore ? filteredItems.slice(0, limit) : filteredItems;
  const nextCursorTs =
    hasMore && pageItems.length > 0
      ? Number(pageItems[pageItems.length - 1].timestamp ?? 0)
      : null;

  return {
    ok: true,
    childUid,
    dayKey,
    items: pageItems,
    nextCursorTs,
    hasMore,
  };
});

export const getFamilyChildrenCurrent = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;

  const { familyId, members } = await listTrackableLocationMembersForViewer(uid);
  if (!members.length) return { ok: true, familyId, children: [] };

  const membersByUid = new Map(
    members.map((member) => [member.uid, member] as const)
  );
  const familyLiveSnap = await admin
    .database()
    .ref(`live_locations_by_family/${familyId}`)
    .get();
  const familyLiveSource = familyLiveSnap.exists()
    ? normalizeLiveLocationMap(familyLiveSnap.val())
    : {};
  const missingMemberUids = Array.from(membersByUid.keys()).filter(
    (memberUid) => familyLiveSource[memberUid] == null
  );
  const missingLiveSource = await readMissingFamilyLiveLocations({
    familyId,
    missingMemberUids,
  });
  const liveSource = {
    ...familyLiveSource,
    ...missingLiveSource,
  };

  const children = Array.from(membersByUid.entries())
    .map(([memberUid, member]) => {
      const current = liveSource[memberUid] ?? null;
      return {
        childUid: memberUid,
        role: member.role,
        allowTracking: member.allowTracking,
        current,
      };
    })
    .filter((item) => item.current != null);

  return { ok: true, familyId, children };
});
