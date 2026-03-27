import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";

type UserDoc = Record<string, unknown>;

export interface ZoneAccessContext {
  requesterUid: string;
  requesterRole: string;
  requesterParentUid: string | null;
  requesterFamilyId: string | null;
  requesterManagedChildIds: string[];
  childUid: string;
  childParentUid: string;
  childFamilyId: string | null;
}

function optionalTrimmedString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized ? normalized : null;
}

function readRequiredString(
  data: UserDoc,
  field: string,
  errorMessage: string,
): string {
  const raw = optionalTrimmedString(data[field]);
  if (raw == null) {
    throw new HttpsError("failed-precondition", errorMessage);
  }
  return raw;
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

export function canViewZonesForChild(context: ZoneAccessContext): boolean {
  if (context.requesterUid === context.childUid) {
    return true;
  }

  if (
    context.requesterRole === "parent" &&
    context.requesterUid === context.childParentUid
  ) {
    return true;
  }

  return (
    context.requesterRole === "guardian" &&
    context.requesterParentUid === context.childParentUid &&
    context.requesterFamilyId != null &&
    context.requesterFamilyId === context.childFamilyId &&
    context.requesterManagedChildIds.includes(context.childUid)
  );
}

export function canManageZonesForChild(context: ZoneAccessContext): boolean {
  if (
    context.requesterRole === "parent" &&
    context.requesterUid === context.childParentUid
  ) {
    return true;
  }

  return (
    context.requesterRole === "guardian" &&
    context.requesterParentUid === context.childParentUid &&
    context.requesterFamilyId != null &&
    context.requesterFamilyId === context.childFamilyId &&
    context.requesterManagedChildIds.includes(context.childUid)
  );
}

async function loadZoneAccessContext(
  requesterUid: string,
  childUid: string,
): Promise<ZoneAccessContext> {
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

  return {
    requesterUid,
    requesterRole: readRequiredString(
      requester,
      "role",
      "Missing role on requester profile",
    ),
    requesterParentUid: optionalTrimmedString(requester.parentUid),
    requesterFamilyId: optionalTrimmedString(requester.familyId),
    requesterManagedChildIds: readStringList(requester, "managedChildIds"),
    childUid,
    childParentUid: readRequiredString(
      child,
      "parentUid",
      "Missing parentUid on child profile",
    ),
    childFamilyId: optionalTrimmedString(child.familyId),
  };
}

export async function requireZoneViewerAccess(
  requesterUid: string,
  childUid: string,
): Promise<ZoneAccessContext> {
  const context = await loadZoneAccessContext(requesterUid, childUid);
  if (!canViewZonesForChild(context)) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to view zones for this child",
    );
  }
  return context;
}

export async function requireZoneManagerAccess(
  requesterUid: string,
  childUid: string,
): Promise<ZoneAccessContext> {
  const context = await loadZoneAccessContext(requesterUid, childUid);
  if (!canManageZonesForChild(context)) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to manage zones for this child",
    );
  }
  return context;
}
