import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { admin } from "../bootstrap";
import { REGION } from "../config";

export const mirrorUserToRtdb = onDocumentCreated(
{ document: "users/{uid}", region: REGION },
async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as any;
    const uid = event.params.uid;
    const parentUid = data.parentUid || null;

    await admin.database().ref(`users/${uid}`).set({ parentUid });
    console.log(`Mirrored user ${uid} → RTDB`);
  }
);