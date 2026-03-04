import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { mustString } from "../helpers";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

export const getChildLocationCurrent = onCall({ region: REGION }, async (req) => {
if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");

  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) throw new HttpsError("not-found", "Child not found");

  const child = childSnap.data() as any;
  if (child.parentUid !== parentUid) throw new HttpsError("permission-denied", "Not your child");

  const curSnap = await admin.database().ref(`locations/${childUid}/current`).get();
  return { ok: true, childUid, current: curSnap.exists() ? curSnap.val() : null };
});

export const getChildHistoryByDay = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const dayKey = mustString(req.data?.dayKey, "dayKey");

  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) throw new HttpsError("not-found", "Child not found");

  const child = childSnap.data() as any;
  if (child.parentUid !== parentUid) throw new HttpsError("permission-denied", "Not your child");

  const histSnap = await admin.database().ref(`locations/${childUid}/historyByDay/${dayKey}`).get();
  return { ok: true, childUid, dayKey, history: histSnap.exists() ? histSnap.val() : null };
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