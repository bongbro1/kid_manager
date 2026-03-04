import { randomUUID } from "crypto";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { admin } from "../bootstrap";
import { REGION } from "../config";
import { mustString, mustNumber, validateLatLng } from "../helpers";
import { requireParentOfChild } from "../services/child";
import { db } from "../bootstrap";

// upsertChildZone
export const upsertChildZone = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  await requireParentOfChild(parentUid, childUid);

  const zoneIdRaw = req.data?.zoneId;
  const zoneId =
    typeof zoneIdRaw === "string" && zoneIdRaw.trim() ? zoneIdRaw.trim() : randomUUID();

  const name = mustString(req.data?.name, "name").slice(0, 60);
  const type = mustString(req.data?.type, "type"); // safe|danger
  if (type !== "safe" && type !== "danger") {
    throw new HttpsError("invalid-argument", "type must be 'safe' or 'danger'");
  }

  const lat = mustNumber(req.data?.lat, "lat");
  const lng = mustNumber(req.data?.lng, "lng");
  validateLatLng(lat, lng);

  const radiusM = mustNumber(req.data?.radiusM, "radiusM");
  if (radiusM < 20 || radiusM > 5000) {
    throw new HttpsError("invalid-argument", "radiusM out of range (20..5000)");
  }

  const enabled = req.data?.enabled == null ? true : Boolean(req.data.enabled);
  const nowMs = Date.now();

  const zone = {
    name,
    type,
    lat,
    lng,
    radiusM,
    enabled,
    createdBy: parentUid,
    createdAt: req.data?.createdAt ?? nowMs,
    updatedAt: nowMs,
  };

  await admin.database().ref(`zonesByChild/${childUid}/${zoneId}`).update(zone);
  return { ok: true, childUid, zoneId };
});

// deleteChildZone
export const deleteChildZone = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const parentUid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");
  const zoneId = mustString(req.data?.zoneId, "zoneId");
  await requireParentOfChild(parentUid, childUid);

  await admin.database().ref(`zonesByChild/${childUid}/${zoneId}`).remove();
  return { ok: true };
});

// getChildZones
export const getChildZones = onCall({ region: REGION }, async (req) => {
  if (!req.auth?.uid) throw new HttpsError("unauthenticated", "Login required");
  const uid = req.auth.uid;

  const childUid = mustString(req.data?.childUid, "childUid");

  const childSnap = await db.doc(`users/${childUid}`).get();
  if (!childSnap.exists) throw new HttpsError("not-found", "Child not found");
  const child = childSnap.data() as any;

  if (uid !== childUid && uid !== child.parentUid) {
    throw new HttpsError("permission-denied", "Not allowed");
  }

  const snap = await admin.database().ref(`zonesByChild/${childUid}`).get();
  const zones = snap.exists() ? snap.val() : null;

  return { ok: true, childUid, zones };
});