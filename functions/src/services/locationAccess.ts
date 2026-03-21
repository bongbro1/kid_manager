import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../bootstrap";
import { requireFamilyMember } from "./user";

type UserDoc = Record<string, unknown>;

export interface LocationAccessContext {
  viewerUid: string;
  viewerRole: string;
  viewerFamilyId: string;
  targetUid: string;
  targetRole: string;
  targetFamilyId: string;
  targetAllowTracking: boolean;
}

export interface TrackableLocationMember {
  uid: string;
  role: string;
  familyId: string;
  allowTracking: boolean;
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

export function isTrackableLocationTargetDoc(data: UserDoc): boolean {
  const role = typeof data.role === "string" ? data.role.trim() : "";
  if (role === "child") {
    return true;
  }
  return role === "guardian" && data.allowTracking === true;
}

export async function requireLocationViewerAccess(
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

  if (viewerFamilyId !== targetFamilyId) {
    throw new HttpsError("permission-denied", "Not in the same family");
  }

  await requireFamilyMember(viewerFamilyId, viewerUid);

  const targetAllowTracking = target.allowTracking === true;
  const targetTrackable = isTrackableLocationTargetDoc(target);

  if (viewerUid === targetUid) {
    if (!targetTrackable) {
      throw new HttpsError("permission-denied", "Location tracking is disabled");
    }
    return {
      viewerUid,
      viewerRole,
      viewerFamilyId,
      targetUid,
      targetRole,
      targetFamilyId,
      targetAllowTracking,
    };
  }

  if (viewerRole !== "parent" && viewerRole !== "guardian") {
    throw new HttpsError("permission-denied", "Only parent or guardian can view location");
  }

  if (!targetTrackable) {
    throw new HttpsError("permission-denied", "Target is not available for location tracking");
  }

  return {
    viewerUid,
    viewerRole,
    viewerFamilyId,
    targetUid,
    targetRole,
    targetFamilyId,
    targetAllowTracking,
  };
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

  const snap = await db.collection("users").where("familyId", "==", familyId).get();
  const members = snap.docs
    .map((doc) => {
      const data = (doc.data() ?? {}) as UserDoc;
      return {
        uid: doc.id,
        role: typeof data.role === "string" ? data.role.trim() : "",
        familyId,
        allowTracking: data.allowTracking === true,
      } as TrackableLocationMember;
    })
    .filter((member) => member.uid !== viewerUid)
    .filter((member) => member.role === "child" || (member.role === "guardian" && member.allowTracking))
    .sort((a, b) => {
      const roleScoreA = a.role === "child" ? 0 : 1;
      const roleScoreB = b.role === "child" ? 0 : 1;
      return roleScoreA - roleScoreB;
    });

  return { familyId, members };
}
