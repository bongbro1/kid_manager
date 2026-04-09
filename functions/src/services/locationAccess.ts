import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";
import { requireFamilyMember } from "./user";

type UserDoc = Record<string, unknown>;

export interface LocationAccessContext {
  viewerUid: string;
  viewerRole: string;
  viewerParentUid: string | null;
  viewerFamilyId: string;
  viewerManagedChildIds: string[];
  targetUid: string;
  targetRole: string;
  targetParentUid: string | null;
  targetFamilyId: string;
  targetAllowTracking: boolean;
}

export interface TrackableLocationMember {
  uid: string;
  role: string;
  familyId: string;
  allowTracking: boolean;
}

export interface LocationAccessPolicyContext {
  requesterUid: string;
  requesterRole: string;
  requesterParentUid: string | null;
  requesterFamilyId: string | null;
  requesterManagedChildIds: string[];
  targetUid: string;
  targetRole: string;
  targetParentUid: string | null;
  targetFamilyId: string | null;
  targetAllowTracking: boolean;
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

function optionalTrimmedString(value: unknown): string | null {
  if (typeof value !== "string") {
    return null;
  }

  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
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

export function isTrackableLocationTargetDoc(data: UserDoc): boolean {
  const role = typeof data.role === "string" ? data.role.trim() : "";
  if (role === "child") {
    return true;
  }
  return (
    (role === "guardian" || role === "parent") &&
    data.allowTracking === true
  );
}

export function canViewLocationForTarget(
  context: LocationAccessPolicyContext
): boolean {
  if (context.requesterUid === context.targetUid) {
    return true;
  }

  if (
    context.requesterFamilyId == null ||
    context.targetFamilyId == null ||
    context.requesterFamilyId !== context.targetFamilyId
  ) {
    return false;
  }

  switch (context.targetRole) {
    case "child":
      if (!context.targetAllowTracking) {
        return false;
      }

      if (context.requesterRole === "parent") {
        return context.requesterUid === context.targetParentUid;
      }

      return (
        context.requesterRole === "guardian" &&
        context.requesterParentUid != null &&
        context.requesterParentUid === context.targetParentUid &&
        context.requesterManagedChildIds.includes(context.targetUid)
      );
    case "guardian":
      if (!context.targetAllowTracking) {
        return false;
      }

      if (context.requesterRole === "parent") {
        return context.requesterUid === context.targetParentUid;
      }

      return false;
    default:
      return false;
  }
}

export function canViewCurrentLocationForTarget(
  context: LocationAccessPolicyContext
): boolean {
  if (context.targetRole === "parent") {
    if (context.requesterUid === context.targetUid) {
      return true;
    }

    if (
      context.requesterFamilyId == null ||
      context.targetFamilyId == null ||
      context.requesterFamilyId !== context.targetFamilyId ||
      !context.targetAllowTracking
    ) {
      return false;
    }

    return (
      context.requesterRole === "guardian" &&
      context.requesterParentUid != null &&
      context.requesterParentUid === context.targetUid
    );
  }

  return canViewLocationForTarget(context);
}

export function canListTrackableLocationMemberForViewer(params: {
  viewerUid: string;
  viewerRole: string;
  viewerParentUid: string | null;
  viewerFamilyId: string | null;
  viewerManagedChildIds: string[];
  memberUid: string;
  memberRole: string;
  memberParentUid: string | null;
  memberFamilyId: string | null;
  memberAllowTracking: boolean;
}): boolean {
  if (params.memberUid === params.viewerUid) {
    return false;
  }

  return canViewCurrentLocationForTarget({
    requesterUid: params.viewerUid,
    requesterRole: params.viewerRole,
    requesterParentUid: params.viewerParentUid,
    requesterFamilyId: params.viewerFamilyId,
    requesterManagedChildIds: params.viewerManagedChildIds,
    targetUid: params.memberUid,
    targetRole: params.memberRole,
    targetParentUid: params.memberParentUid,
    targetFamilyId: params.memberFamilyId,
    targetAllowTracking: params.memberAllowTracking,
  });
}

function buildLocationAccessContext(
  viewerUid: string,
  viewer: UserDoc,
  targetUid: string,
  target: UserDoc
): LocationAccessContext {
  const viewerRole = readRequiredString(
    viewer,
    "role",
    "Missing role on viewer profile"
  );
  const viewerFamilyId = readRequiredString(
    viewer,
    "familyId",
    "Missing familyId on viewer profile"
  );
  const targetRole = readRequiredString(
    target,
    "role",
    "Missing role on target profile"
  );
  const targetFamilyId = readRequiredString(
    target,
    "familyId",
    "Missing familyId on target profile"
  );

  return {
    viewerUid,
    viewerRole,
    viewerParentUid: optionalTrimmedString(viewer.parentUid),
    viewerFamilyId,
    viewerManagedChildIds: readStringList(viewer, "managedChildIds"),
    targetUid,
    targetRole,
    targetParentUid: optionalTrimmedString(target.parentUid),
    targetFamilyId,
    targetAllowTracking: target.allowTracking === true,
  };
}

function toPolicyContext(
  context: LocationAccessContext
): LocationAccessPolicyContext {
  return {
    requesterUid: context.viewerUid,
    requesterRole: context.viewerRole,
    requesterParentUid: context.viewerParentUid,
    requesterFamilyId: context.viewerFamilyId,
    requesterManagedChildIds: context.viewerManagedChildIds,
    targetUid: context.targetUid,
    targetRole: context.targetRole,
    targetParentUid: context.targetParentUid,
    targetFamilyId: context.targetFamilyId,
    targetAllowTracking: context.targetAllowTracking,
  };
}

async function loadLocationAccessContext(
  viewerUid: string,
  targetUid: string
): Promise<LocationAccessContext> {
  const [viewerSnap, targetSnap] = await Promise.all([
    db.doc(`users/${viewerUid}`).get(),
    db.doc(`users/${targetUid}`).get(),
  ]);

  if (!viewerSnap.exists) {
    throw new HttpsError("not-found", "Viewer not found");
  }
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "Target not found");
  }

  const viewer = (viewerSnap.data() ?? {}) as UserDoc;
  const target = (targetSnap.data() ?? {}) as UserDoc;
  const context = buildLocationAccessContext(viewerUid, viewer, targetUid, target);

  await requireFamilyMember(context.viewerFamilyId, viewerUid);
  return context;
}

export async function requireLocationViewerAccess(
  viewerUid: string,
  targetUid: string
): Promise<LocationAccessContext> {
  const context = await loadLocationAccessContext(viewerUid, targetUid);
  const policyContext = toPolicyContext(context);

  if (!canViewLocationForTarget(policyContext)) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to view this location"
    );
  }

  return context;
}

export async function requireCurrentLocationViewerAccess(
  viewerUid: string,
  targetUid: string
): Promise<LocationAccessContext> {
  const context = await loadLocationAccessContext(viewerUid, targetUid);
  const policyContext = toPolicyContext(context);

  if (!canViewCurrentLocationForTarget(policyContext)) {
    throw new HttpsError(
      "permission-denied",
      "You are not allowed to view this current location"
    );
  }

  return context;
}

export async function listTrackableLocationMembersForViewer(
  viewerUid: string
): Promise<{ familyId: string; members: TrackableLocationMember[] }> {
  const viewerSnap = await db.doc(`users/${viewerUid}`).get();
  if (!viewerSnap.exists) {
    throw new HttpsError("not-found", "Viewer not found");
  }

  const viewer = (viewerSnap.data() ?? {}) as UserDoc;
  const viewerRole = readRequiredString(
    viewer,
    "role",
    "Missing role on viewer profile"
  );
  const familyId = readRequiredString(
    viewer,
    "familyId",
    "Missing familyId on viewer profile"
  );

  if (viewerRole !== "parent" && viewerRole !== "guardian") {
    throw new HttpsError("permission-denied", "Only parent or guardian can view tracked members");
  }

  await requireFamilyMember(familyId, viewerUid);

  const viewerParentUid = optionalTrimmedString(viewer.parentUid);
  const viewerManagedChildIds = readStringList(viewer, "managedChildIds");

  const snap = await db
    .collection(`families/${familyId}/locationMembers`)
    .get();
  const members = snap.docs
    .map((doc) => {
      const data = (doc.data() ?? {}) as UserDoc;
      return {
        uid: doc.id,
        role: typeof data.role === "string" ? data.role.trim() : "",
        familyId:
          typeof data.familyId === "string" && data.familyId.trim()
            ? data.familyId.trim()
            : familyId,
        parentUid: optionalTrimmedString(data.parentUid),
        allowTracking: data.allowTracking === true,
      } as TrackableLocationMember & { parentUid: string | null };
    })
    .filter((member) =>
      canListTrackableLocationMemberForViewer({
        viewerUid,
        viewerRole,
        viewerParentUid,
        viewerFamilyId: familyId,
        viewerManagedChildIds,
        memberUid: member.uid,
        memberRole: member.role,
        memberParentUid: member.parentUid,
        memberFamilyId: member.familyId,
        memberAllowTracking: member.allowTracking,
      })
    )
    .sort((a, b) => {
      const roleScoreA = a.role === "child" ? 0 : 1;
      const roleScoreB = b.role === "child" ? 0 : 1;
      return roleScoreA - roleScoreB;
    })
    .map(({ parentUid: _parentUid, ...member }) => member);

  return { familyId, members };
}
