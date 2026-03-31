import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin } from "../bootstrap";
import { REGION } from "../config";

function readTrimmedStringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  return raw
    .map((item) => (typeof item === "string" ? item.trim() : ""))
    .filter((item) => item.length > 0)
    .filter((item, index, list) => list.indexOf(item) === index);
}

function buildManagedChildIdsMap(managedChildIds: string[]): Record<string, true> {
  return Object.fromEntries(managedChildIds.map((childUid) => [childUid, true]));
}

export function buildRtdbUserMirror(
  data: Record<string, unknown>
): Record<string, unknown> {
  const parentUid =
    typeof data.parentUid === "string" && data.parentUid.trim()
      ? data.parentUid.trim()
      : null;
  const familyId =
    typeof data.familyId === "string" && data.familyId.trim()
      ? data.familyId.trim()
      : null;
  const role =
    typeof data.role === "string" && data.role.trim()
      ? data.role.trim()
      : null;
  const allowTracking = data.allowTracking === true;
  const managedChildIds = readTrimmedStringList(
    data.managedChildIds ?? data.assignedChildIds ?? data.childIds
  );

  return {
    parentUid,
    familyId,
    role,
    allowTracking,
    managedChildIdsMap: buildManagedChildIdsMap(managedChildIds),
    mirroredAt: admin.database.ServerValue.TIMESTAMP,
  };
}

export const mirrorUserToRtdb = onDocumentWritten(
  { document: "users/{uid}", region: REGION },
  async (event) => {
    const uid = event.params.uid;
    const after = event.data?.after;
    const targetRef = admin.database().ref(`users/${uid}`);

    if (!after?.exists) {
      await targetRef.remove();
      console.log(`[mirrorUserToRtdb] removed RTDB mirror for uid=${uid}`);
      return;
    }

    const data = after.data() as Record<string, unknown>;
    const mirror = buildRtdbUserMirror(data);

    await targetRef.set(mirror);

    console.log(
      `[mirrorUserToRtdb] mirrored uid=${uid} parentUid=${String(mirror.parentUid ?? "")} familyId=${String(mirror.familyId ?? "")} role=${String(mirror.role ?? "")} allowTracking=${mirror.allowTracking === true}`
    );
  }
);
