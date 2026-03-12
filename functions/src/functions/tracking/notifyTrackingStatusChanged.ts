import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { t } from "../i18n";

async function getParentUsers(familyId: string, childUid: string) {
  const membersSnap = await db.collection(`families/${familyId}/members`).get();

  const parentUids = membersSnap.docs
    .map((d) => ({ uid: d.id, role: d.get("role") }))
    .filter((x) => x.uid !== childUid && (x.role === "parent" || x.role === "guardian"))
    .map((x) => x.uid);

  const users = await Promise.all(
    parentUids.map(async (uid) => {
      const userSnap = await db.doc(`users/${uid}`).get();
      return {
        uid,
        locale: userSnap.exists ? String(userSnap.get("locale") || "vi") : "vi",
      };
    })
  );

  return users;
}

async function getUserTokens(uid: string): Promise<string[]> {
  const snap = await db.collection(`users/${uid}/fcmTokens`).get();
  return snap.docs
    .map((d) => String(d.get("token") || ""))
    .filter(Boolean);
}

async function cleanupInvalidTokens(uid: string, invalidTokens: string[]) {
  if (invalidTokens.length === 0) return;

  const snap = await db.collection(`users/${uid}/fcmTokens`).get();
  const batch = db.batch();

  for (const doc of snap.docs) {
    const token = String(doc.get("token") || "");
    if (invalidTokens.includes(token)) {
      batch.delete(doc.ref);
    }
  }

  await batch.commit();
}

export const notifyTrackingStatusChanged = onDocumentWritten(
  {
    region: REGION,
    document: "families/{familyId}/trackingStatus/{childUid}",
  },
  async (event) => {
    const after = event.data?.after;
    const before = event.data?.before;

    if (!after?.exists) return;

    const afterData = after.data();
    const beforeData = before?.exists ? before.data() : null;

    const familyId = String(event.params.familyId);
    const childUid = String(event.params.childUid);

    const newStatus = String(afterData.status || "");
    const oldStatus = beforeData ? String(beforeData.status || "") : "";

    if (!newStatus || newStatus === oldStatus) return;

    const childName = String(afterData.childName || "Con");

    const parents = await getParentUsers(familyId, childUid);
    if (parents.length === 0) return;

    for (const parent of parents) {
      const locale = parent.locale || "vi";
      const titleKey = `tracking.${newStatus}.parent.title`;
      const bodyKey = `tracking.${newStatus}.parent.body`;

      const title = t(locale, titleKey, { childName });
      const body = t(locale, bodyKey, { childName });

      const tokens = await getUserTokens(parent.uid);
      if (tokens.length === 0) continue;

      const payload: admin.messaging.MulticastMessage = {
        tokens,
        notification: {
          title,
          body,
        },
        data: {
          type: "tracking_status",
          familyId,
          childUid,
          status: newStatus,
          childName,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "tracking_alerts",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      };

      const res = await admin.messaging().sendEachForMulticast(payload);

      const invalidTokens: string[] = [];
      res.responses.forEach((r, i) => {
        if (!r.success) {
          const code = r.error?.code || "";
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(tokens[i]);
          }
        }
      });

      await cleanupInvalidTokens(parent.uid, invalidTokens);
    }
  }
);