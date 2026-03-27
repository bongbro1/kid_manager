import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { admin, db } from "../bootstrap";
import { REGION } from "../config";
import { getUserFamilyAndRole, requireFamilyMember } from "../services/user";

function parseDateFromDdMmYyyy(value: string): Date | null {
  const parts = value.split("/");
  if (parts.length !== 3) return null;

  const day = Number(parts[0]);
  const month = Number(parts[1]);
  const year = Number(parts[2]);
  if (!Number.isInteger(day) || !Number.isInteger(month) || !Number.isInteger(year)) {
    return null;
  }

  const parsed = new Date(year, month - 1, day);
  if (
    parsed.getFullYear() !== year ||
    parsed.getMonth() !== month - 1 ||
    parsed.getDate() !== day
  ) {
    return null;
  }

  return parsed;
}

function parseDateOnlyIso(value: string): Date | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return null;

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) {
    return null;
  }

  const parsed = new Date(year, month - 1, day);
  if (
    parsed.getFullYear() !== year ||
    parsed.getMonth() !== month - 1 ||
    parsed.getDate() !== day
  ) {
    return null;
  }

  return parsed;
}

function parseIsoLikeLocalDate(value: string): Date | null {
  const match = /^(\d{4})-(\d{2})-(\d{2})T/.exec(value);
  if (!match) return null;
  return parseDateOnlyIso(`${match[1]}-${match[2]}-${match[3]}`);
}

function parseFlexibleBirthDate(rawDob: unknown, rawDobIso: unknown): Date | null {
  const candidates = [rawDobIso, rawDob];

  for (const candidate of candidates) {
    if (!candidate) continue;

    if (candidate instanceof admin.firestore.Timestamp) {
      const value = candidate.toDate();
      return new Date(value.getFullYear(), value.getMonth(), value.getDate());
    }

    if (candidate instanceof Date) {
      return new Date(candidate.getFullYear(), candidate.getMonth(), candidate.getDate());
    }

    if (typeof candidate === "number" && Number.isFinite(candidate)) {
      const value = new Date(candidate);
      if (!Number.isNaN(value.getTime())) {
        return new Date(value.getFullYear(), value.getMonth(), value.getDate());
      }
    }

    if (typeof candidate === "string") {
      const trimmed = candidate.trim();
      if (!trimmed) continue;

      const fromText = parseDateFromDdMmYyyy(trimmed);
      if (fromText) return fromText;

      const fromDateOnlyIso = parseDateOnlyIso(trimmed);
      if (fromDateOnlyIso) return fromDateOnlyIso;

      const fromIsoLikeLocal = parseIsoLikeLocalDate(trimmed);
      if (fromIsoLikeLocal) return fromIsoLikeLocal;

      const fromIso = new Date(trimmed);
      if (!Number.isNaN(fromIso.getTime())) {
        return new Date(fromIso.getFullYear(), fromIso.getMonth(), fromIso.getDate());
      }
    }
  }

  return null;
}

function buildBirthdayStorageFields(birthDate: Date | null): Record<string, unknown> {
  if (!birthDate) return {};

  const normalized = new Date(
    birthDate.getFullYear(),
    birthDate.getMonth(),
    birthDate.getDate()
  );
  const utcNoon = new Date(
    Date.UTC(
      normalized.getFullYear(),
      normalized.getMonth(),
      normalized.getDate(),
      12
    )
  );
  const dobIso = [
    normalized.getFullYear().toString().padStart(4, "0"),
    (normalized.getMonth() + 1).toString().padStart(2, "0"),
    normalized.getDate().toString().padStart(2, "0"),
  ].join("-");

  return {
    dob: admin.firestore.Timestamp.fromDate(utcNoon),
    dobIso,
    birthMonth: normalized.getMonth() + 1,
    birthDay: normalized.getDate(),
  };
}

function readTrimmedStringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }

  return raw
    .map((item) => String(item ?? "").trim())
    .filter((item) => item.length > 0)
    .filter((item, index, list) => list.indexOf(item) === index);
}

function buildFamilyMemberPublicFields(
  uid: string,
  userData: FirebaseFirestore.DocumentData
): Record<string, unknown> {
  const familyId =
    typeof userData.familyId === "string" ? userData.familyId.trim() : "";
  const role = typeof userData.role === "string" && userData.role
    ? userData.role
    : "member";
  const displayName =
    typeof userData.displayName === "string" ? userData.displayName.trim() : "";
  const email =
    typeof userData.email === "string" ? userData.email.trim() : "";
  const avatarUrl =
    typeof userData.avatarUrl === "string" ? userData.avatarUrl : "";
  const parentUid =
    typeof userData.parentUid === "string" ? userData.parentUid.trim() : "";
  const isActive = userData.isActive === true;
  const allowTracking = role === "child" || userData.allowTracking === true;
  const managedChildIds = readTrimmedStringList(
    userData.managedChildIds ?? userData.assignedChildIds ?? userData.childIds
  );
  const birthDate = parseFlexibleBirthDate(userData.dob, userData.dobIso);
  const lastActiveAt =
    userData.lastActiveAt instanceof admin.firestore.Timestamp
      ? userData.lastActiveAt
      : userData.lastActiveAt instanceof Date
        ? admin.firestore.Timestamp.fromDate(userData.lastActiveAt)
        : null;

  return {
    uid,
    role,
    ...(familyId ? { familyId } : {}),
    ...(displayName ? { displayName } : {}),
    ...(email ? { email } : {}),
    avatarUrl,
    ...(parentUid ? { parentUid } : {}),
    isActive,
    allowTracking,
    ...(managedChildIds.length > 0 ? { managedChildIds } : {}),
    ...(lastActiveAt ? { lastActiveAt } : {}),
    ...buildBirthdayStorageFields(birthDate),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function syncUserToFamilyMember(
  uid: string,
  userData: FirebaseFirestore.DocumentData | undefined
) {
  if (!userData) return;

  const familyId =
    typeof userData.familyId === "string" ? userData.familyId.trim() : "";
  if (!familyId) return;

  await db
    .doc(`families/${familyId}/members/${uid}`)
    .set(buildFamilyMemberPublicFields(uid, userData), { merge: true });
}

export const mirrorUserToFamilyMembers = onDocumentWritten(
  { document: "users/{uid}", region: REGION },
  async (event) => {
    const uid = String(event.params.uid);
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    const beforeFamilyId =
      typeof before?.familyId === "string" ? before.familyId.trim() : "";
    const afterFamilyId =
      typeof after?.familyId === "string" ? after.familyId.trim() : "";

    if (!after) {
      if (beforeFamilyId) {
        await db.doc(`families/${beforeFamilyId}/members/${uid}`).delete().catch(() => {});
      }
      return;
    }

    if (beforeFamilyId && beforeFamilyId !== afterFamilyId) {
      await db.doc(`families/${beforeFamilyId}/members/${uid}`).delete().catch(() => {});
    }

    await syncUserToFamilyMember(uid, after);
  }
);

export const syncFamilyMemberPublicData = onCall(
  { region: REGION },
  async (req) => {
    if (!req.auth?.uid) {
      throw new HttpsError("unauthenticated", "Login required");
    }

    const uid = req.auth.uid;
    const { familyId } = await getUserFamilyAndRole(uid);
    await requireFamilyMember(familyId, uid);

    const requestedFamilyId =
      typeof req.data?.familyId === "string" ? req.data.familyId.trim() : "";
    if (requestedFamilyId && requestedFamilyId !== familyId) {
      throw new HttpsError("permission-denied", "Family mismatch");
    }

    const usersSnap = await db.collection("users").where("familyId", "==", familyId).get();
    if (usersSnap.empty) {
      return { ok: true, familyId, syncedCount: 0 };
    }

    const batch = db.batch();
    for (const userDoc of usersSnap.docs) {
      batch.set(
        db.doc(`families/${familyId}/members/${userDoc.id}`),
        buildFamilyMemberPublicFields(userDoc.id, userDoc.data()),
        { merge: true }
      );
    }
    await batch.commit();

    return { ok: true, familyId, syncedCount: usersSnap.size };
  }
);
