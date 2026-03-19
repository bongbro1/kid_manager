import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin } from "../bootstrap";
import { REGION } from "../config";

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

    await targetRef.set({
      parentUid,
      familyId,
      role,
      mirroredAt: admin.database.ServerValue.TIMESTAMP,
    });

    console.log(
      `[mirrorUserToRtdb] mirrored uid=${uid} parentUid=${parentUid} familyId=${familyId} role=${role}`
    );
  }
);
