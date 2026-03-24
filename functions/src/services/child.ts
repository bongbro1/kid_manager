import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";

type UserDoc = Record<string, unknown>;

export interface ChildAccessContext {
  child: UserDoc;
  childUid: string;
  ownerParentUid: string;
  requesterRole: string;
}

function readRequiredString(
  data: UserDoc,
  field: string,
  errorMessage: string
): string {
  const raw = data[field];
  if (typeof raw !== "string" || !raw.trim()) {
    throw new HttpsError("failed-precondition", errorMessage);
  }
  return raw.trim();
}

async function resolveChildAccess(
  requesterUid: string,
  childUid: string
): Promise<ChildAccessContext> {
  const [requesterSnap, childSnap] = await Promise.all([
    db.doc(`users/${requesterUid}`).get(),
    db.doc(`users/${childUid}`).get(),
  ]);

  if (!requesterSnap.exists) {
    throw new HttpsError("not-found", "Requester not found");
  }
  if (!childSnap.exists) {
    throw new HttpsError("not-found", "Child not found");
  }

  const requester = (requesterSnap.data() ?? {}) as UserDoc;
  const child = (childSnap.data() ?? {}) as UserDoc;

  const requesterRole = readRequiredString(
    requester,
    "role",
    "Missing role on requester profile"
  );
  const ownerParentUid = readRequiredString(
    child,
    "parentUid",
    "Missing parentUid on child profile"
  );

  if (requesterUid === childUid) {
    return {
      child,
      childUid,
      ownerParentUid,
      requesterRole,
    };
  }

  if (requesterUid === ownerParentUid) {
    return {
      child,
      childUid,
      ownerParentUid,
      requesterRole,
    };
  }

  if (requesterRole === "guardian") {
    const guardianParentUid =
      typeof requester.parentUid === "string" ? requester.parentUid.trim() : "";
    const requesterFamilyId =
      typeof requester.familyId === "string" ? requester.familyId.trim() : "";
    const childFamilyId =
      typeof child.familyId === "string" ? child.familyId.trim() : "";

    if (
      guardianParentUid === ownerParentUid &&
      requesterFamilyId.length > 0 &&
      requesterFamilyId === childFamilyId
    ) {
      return {
        child,
        childUid,
        ownerParentUid,
        requesterRole,
      };
    }
  }

  throw new HttpsError(
    "permission-denied",
    "You are not allowed to access this child"
  );
}

export async function requireAdultManagerOfChild(
  requesterUid: string,
  childUid: string
): Promise<ChildAccessContext> {
  const access = await resolveChildAccess(requesterUid, childUid);
  if (access.requesterRole !== "parent" && access.requesterRole !== "guardian") {
    throw new HttpsError(
      "permission-denied",
      "Not your child"
    );
  }
  return access;
}

export async function requireParentOfChild(requesterUid: string, childUid: string) {
  return (await requireAdultManagerOfChild(requesterUid, childUid)).child;
}

export async function requireParentOrChildSelf(
  requesterUid: string,
  childUid: string
) {
  return (await resolveChildAccess(requesterUid, childUid)).child;
}

export async function requireParentGuardianOrChildSelf(
  requesterUid: string,
  childUid: string
): Promise<ChildAccessContext> {
  return resolveChildAccess(requesterUid, childUid);
}
