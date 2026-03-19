import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";

export async function requireParentOfChild(parentUid: string, childUid: string) {
  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) throw new HttpsError("not-found", "Child not found");

  const child = childSnap.data() as any;
  if (child.parentUid !== parentUid) {
    throw new HttpsError("permission-denied", "Not your child");
  }
  return child;
}

export async function requireParentOrChildSelf(
  requesterUid: string,
  childUid: string
) {
  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) throw new HttpsError("not-found", "Child not found");

  const child = childSnap.data() as any;
  if (requesterUid !== childUid && child.parentUid !== requesterUid) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to access this child"
    );
  }
  return child;
}
