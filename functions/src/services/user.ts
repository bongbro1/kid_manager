import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";

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
  if (!memberSnap.exists) throw new HttpsError("permission-denied", "Not a family member");
  return memberSnap.data() ?? {};
}