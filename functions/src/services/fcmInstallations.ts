import { db } from "../bootstrap";
import { chunk } from "../helpers";

const INSTALLATIONS_COLLECTION = "fcmInstallations";
const TOKEN_MIN_LENGTH = 20;

export type FcmInstallationRecord = {
  installationId: string;
  token: string;
  uid: string;
  familyId: string | null;
  platform: string | null;
};

function optionalTrimmedString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function mapInstallationDoc(
  doc: FirebaseFirestore.QueryDocumentSnapshot
): FcmInstallationRecord | null {
  const data = doc.data() ?? {};
  const token = optionalTrimmedString(data.token);
  const uid = optionalTrimmedString(data.uid);

  if (!token || token.length < TOKEN_MIN_LENGTH || !uid) {
    return null;
  }

  return {
    installationId: doc.id,
    token,
    uid,
    familyId: optionalTrimmedString(data.familyId),
    platform: optionalTrimmedString(data.platform),
  };
}

export function getFcmInstallationRef(installationId: string) {
  return db.collection(INSTALLATIONS_COLLECTION).doc(installationId);
}

export async function listInstallationsByUid(uid: string) {
  const snap = await db
    .collection(INSTALLATIONS_COLLECTION)
    .where("uid", "==", uid)
    .get();

  return snap.docs
    .map((doc) => mapInstallationDoc(doc))
    .filter((record): record is FcmInstallationRecord => record !== null);
}

export async function listInstallationsByFamilyId(familyId: string) {
  const snap = await db
    .collection(INSTALLATIONS_COLLECTION)
    .where("familyId", "==", familyId)
    .get();

  return snap.docs
    .map((doc) => mapInstallationDoc(doc))
    .filter((record): record is FcmInstallationRecord => record !== null);
}

export function groupInstallationsByToken<T extends { token: string }>(
  records: T[]
) {
  const groups = new Map<string, T[]>();

  for (const record of records) {
    const current = groups.get(record.token);
    if (current) {
      current.push(record);
      continue;
    }
    groups.set(record.token, [record]);
  }

  return Array.from(groups.entries()).map(([token, groupedRecords]) => ({
    token,
    records: groupedRecords,
  }));
}

export function dedupeInstallationsByToken<T extends { token: string }>(
  records: T[]
) {
  return groupInstallationsByToken(records).map((group) => group.records[0]);
}

export async function deleteInstallationsByIds(installationIds: string[]) {
  const uniqueIds = Array.from(
    new Set(
      installationIds
        .map((installationId) => installationId.trim())
        .filter(Boolean)
    )
  );

  if (!uniqueIds.length) return 0;

  for (const idsChunk of chunk(uniqueIds, 500)) {
    const batch = db.batch();
    for (const installationId of idsChunk) {
      batch.delete(getFcmInstallationRef(installationId));
    }
    await batch.commit();
  }

  return uniqueIds.length;
}
