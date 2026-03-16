import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

const DAY_KEY_RE = /^\d{4}-\d{2}-\d{2}$/;
const DEFAULT_HISTORY_CHUNK_LIMIT = 250;
const MAX_HISTORY_CHUNK_LIMIT = 500;

async function requireParentOwnsChild(parentUid: string, childUid: string) {
  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) {
    throw new HttpsError("not-found", "Child not found");
  }

  const child = childSnap.data() as any;
  if (child.parentUid !== parentUid) {
    throw new HttpsError("permission-denied", "Not your child");
  }

  return child;
}

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

export const getChildLocationCurrent = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  await requireParentOwnsChild(parentUid, childUid);

  const curSnap = await admin.database().ref(`locations/${childUid}/current`).get();
  return { ok: true, childUid, current: curSnap.exists() ? curSnap.val() : null };
});

export const getChildHistoryByDay = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const dayKey = requireDayKey(req.data?.dayKey);

  await requireParentOwnsChild(parentUid, childUid);

  const histSnap = await admin.database().ref(`locations/${childUid}/historyByDay/${dayKey}`).get();
  return { ok: true, childUid, dayKey, history: histSnap.exists() ? histSnap.val() : null };
});

export const getChildHistoryChunk = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const dayKey = requireDayKey(req.data?.dayKey);
  const cursorAfterTs = parseOptionalTimestamp(req.data?.cursorAfterTs, "cursorAfterTs");
  const fromTs = parseOptionalTimestamp(req.data?.fromTs, "fromTs");
  const toTs = parseOptionalTimestamp(req.data?.toTs, "toTs");
  const limit = parseChunkLimit(req.data?.limit);

  if (fromTs != null && toTs != null && fromTs > toTs) {
    throw new HttpsError("invalid-argument", "fromTs must be <= toTs");
  }

  await requireParentOwnsChild(parentUid, childUid);

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

  const { familyId, role } = await getUserFamilyAndRole(uid);
  await requireFamilyMember(familyId, uid);

  if (role !== "parent") throw new HttpsError("permission-denied", "Only parent can read children current");

  const membersSnap = await db.collection(`families/${familyId}/members`).get();

  const childUids: string[] = [];
  membersSnap.forEach((doc) => {
    const d = doc.data() as any;
    if (d?.role === "child") childUids.push(doc.id);
  });

  if (!childUids.length) return { ok: true, familyId, children: [] };

  const reads = await Promise.all(
    childUids.map(async (childUid) => {
      const snap = await admin.database().ref(`locations/${childUid}/current`).get();
      return { childUid, current: snap.exists() ? snap.val() : null };
    })
  );

  const children = reads.filter((x) => x.current != null);
  return { ok: true, familyId, children };
});
