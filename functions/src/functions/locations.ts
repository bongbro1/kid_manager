import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import { parseLiveLocationRecord } from "../services/safeRouteMonitoringService";
import {
  listTrackableLocationMembersForViewer,
  requireLocationViewerAccess,
} from "../services/locationAccess";

const DAY_KEY_RE = /^\d{4}-\d{2}-\d{2}$/;
const DEFAULT_HISTORY_CHUNK_LIMIT = 250;
const MAX_HISTORY_CHUNK_LIMIT = 500;

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

function normalizeLiveLocationMap(raw: unknown): Record<string, any> {
  if (!raw || typeof raw !== "object") {
    return {};
  }
  return raw as Record<string, any>;
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

  await requireLocationViewerAccess(viewerUid, childUid);

  const histSnap = await admin.database().ref(`locations/${childUid}/historyByDay/${dayKey}`).get();
  return { ok: true, childUid, dayKey, history: histSnap.exists() ? histSnap.val() : null };
});

export const getChildHistoryChunk = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const viewerUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const dayKey = requireDayKey(req.data?.dayKey);
  const cursorAfterTs = parseOptionalTimestamp(req.data?.cursorAfterTs, "cursorAfterTs");
  const fromTs = parseOptionalTimestamp(req.data?.fromTs, "fromTs");
  const toTs = parseOptionalTimestamp(req.data?.toTs, "toTs");
  const limit = parseChunkLimit(req.data?.limit);

  if (fromTs != null && toTs != null && fromTs > toTs) {
    throw new HttpsError("invalid-argument", "fromTs must be <= toTs");
  }

  await requireLocationViewerAccess(viewerUid, childUid);

  let query = admin
    .database()
    .ref(`locations/${childUid}/historyByDay/${dayKey}`)
    .orderByKey();

  let startKeyTs: number | null = fromTs;
  if (cursorAfterTs != null) {
    const cursorStart = cursorAfterTs + 1;
    startKeyTs = startKeyTs == null ? cursorStart : Math.max(startKeyTs, cursorStart);
  }

  if (startKeyTs != null) {
    query = query.startAt(String(startKeyTs));
  }

  if (toTs != null) {
    query = query.endAt(String(toTs));
  }

  const snap = await query.limitToFirst(limit + 1).get();
  if (!snap.exists()) {
    return {
      ok: true,
      childUid,
      dayKey,
      items: [],
      nextCursorTs: null,
      hasMore: false,
    };
  }

  const raw = snap.val() as Record<string, any>;
  const keys = Object.keys(raw).sort();
  const hasMore = keys.length > limit;
  const pageKeys = hasMore ? keys.slice(0, limit) : keys;
  const items = pageKeys.map((key) => {
    const rawPoint = raw[key];
    const point = rawPoint && typeof rawPoint === "object" ? { ...rawPoint } : {};
    if (point.timestamp == null) {
      point.timestamp = Number.parseInt(key, 10);
    }
    return point;
  });

  const nextCursorKey = pageKeys.length ? pageKeys[pageKeys.length - 1] : null;
  const nextCursorTs = hasMore && nextCursorKey != null
    ? Number.parseInt(nextCursorKey, 10)
    : null;

  return {
    ok: true,
    childUid,
    dayKey,
    items,
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
