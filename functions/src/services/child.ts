import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";

type UserDoc = Record<string, unknown>;

export interface ChildAccessContext {
  child: UserDoc;
  childUid: string;
  ownerParentUid: string;
  requesterRole: string;
  requesterUid: string;
  requesterParentUid: string | null;
  requesterFamilyId: string | null;
  requesterManagedChildIds: string[];
  childFamilyId: string | null;
}

export interface ChildAccessPolicyContext {
  requesterUid: string;
  requesterRole: string;
  requesterParentUid: string | null;
  requesterFamilyId: string | null;
  requesterManagedChildIds: string[];
  childUid: string;
  ownerParentUid: string;
  childFamilyId: string | null;
}

function optionalTrimmedString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
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

function readStringList(data: UserDoc, field: string): string[] {
  const raw = data[field];
  if (!Array.isArray(raw)) {
    return [];
  }

  return raw
    .map((value) => optionalTrimmedString(value))
    .filter((value): value is string => value != null);
}

export function canAccessChildForSafeRoute(
  context: ChildAccessPolicyContext
): boolean {
  if (context.requesterUid === context.childUid) {
    return true;
  }

  if (
    context.requesterRole === "parent" &&
    context.requesterUid === context.ownerParentUid
  ) {
    return true;
  }

  return (
    context.requesterRole === "guardian" &&
    context.requesterParentUid === context.ownerParentUid &&
    context.requesterFamilyId != null &&
    context.requesterFamilyId === context.childFamilyId &&
    context.requesterManagedChildIds.includes(context.childUid)
  );
}

export function canManageChildForSafeRoute(
  context: ChildAccessPolicyContext
): boolean {
  if (
    context.requesterRole === "parent" &&
    context.requesterUid === context.ownerParentUid
  ) {
    return true;
  }

  return (
    context.requesterRole === "guardian" &&
    context.requesterParentUid === context.ownerParentUid &&
    context.requesterFamilyId != null &&
    context.requesterFamilyId === context.childFamilyId &&
    context.requesterManagedChildIds.includes(context.childUid)
  );
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
  const policyContext: ChildAccessPolicyContext = {
    requesterUid,
    requesterRole,
    requesterParentUid: optionalTrimmedString(requester.parentUid),
    requesterFamilyId: optionalTrimmedString(requester.familyId),
    requesterManagedChildIds: readStringList(requester, "managedChildIds"),
    childUid,
    ownerParentUid,
    childFamilyId: optionalTrimmedString(child.familyId),
  };

  if (canAccessChildForSafeRoute(policyContext)) {
    return {
      child,
      childUid,
      ownerParentUid,
      requesterRole,
      requesterUid,
      requesterParentUid: policyContext.requesterParentUid,
      requesterFamilyId: policyContext.requesterFamilyId,
      requesterManagedChildIds: policyContext.requesterManagedChildIds,
      childFamilyId: policyContext.childFamilyId,
    };
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
  if (!canManageChildForSafeRoute(access)) {
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
