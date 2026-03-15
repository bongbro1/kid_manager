import { HttpsError } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";

export async function getUserFamilyAndRole(uid: string): Promise<{ familyId: string; role: string }> {
  const snap = await db.doc(`users/${uid}`).get();
  const d = snap.data() ?? {};
  const familyId = d.familyId;
  const role = d.role;

  if (typeof familyId !== "string" || !familyId) {
    throw new HttpsError("failed-precondition", "Missing familyId on user profile");
  }
  if (typeof role !== "string" || !role) {
    throw new HttpsError("failed-precondition", "Missing role on user profile");
  }
  return { familyId, role };
}

export async function requireFamilyMember(familyId: string, uid: string) {
  const memberRef = db.doc(`families/${familyId}/members/${uid}`);
  const memberSnap = await memberRef.get();
  if (memberSnap.exists) return memberSnap.data() ?? {};

  const [familySnap, userSnap] = await Promise.all([
    db.doc(`families/${familyId}`).get(),
    db.doc(`users/${uid}`).get(),
  ]);

  if (!familySnap.exists) {
    throw new HttpsError("failed-precondition", "Family not found");
  }

  const userData = userSnap.data() ?? {};
  const userFamilyId = userData.familyId;
  const role = userData.role;

  if (userFamilyId !== familyId || typeof role !== "string" || !role.trim()) {
    throw new HttpsError("permission-denied", "Not a family member");
  }

  const healedMember = {
    uid,
    role: role.trim(),
    familyId,
    joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    healedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await memberRef.set(healedMember, { merge: true });
  console.log("[requireFamilyMember] healed missing member doc", {
    familyId,
    uid,
    role: healedMember.role,
  });

  return healedMember;
}
