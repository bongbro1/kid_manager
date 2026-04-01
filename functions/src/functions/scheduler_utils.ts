export type FirestoreDocumentSnapshotLike = {
  exists: boolean;
  data(): FirebaseFirestore.DocumentData | undefined;
};

export type FirestoreDocumentRefLike = {
  path: string;
  create(data: FirebaseFirestore.DocumentData): Promise<unknown>;
  get(): Promise<FirestoreDocumentSnapshotLike>;
  set(
    data: FirebaseFirestore.DocumentData,
    options?: FirebaseFirestore.SetOptions,
  ): Promise<unknown>;
};

export type FirestoreQueryDocumentSnapshotLike = {
  id: string;
  ref?: {
    path: string;
  };
  data(): FirebaseFirestore.DocumentData;
};

export type FirestoreQuerySnapshotLike = {
  docs: FirestoreQueryDocumentSnapshotLike[];
  size: number;
};

export type FirestoreWhereFilterOpLike = "==" | "array-contains";

export type FirestoreQueryLike = {
  where(
    fieldPath: string,
    opStr: FirestoreWhereFilterOpLike,
    value: unknown,
  ): FirestoreQueryLike;
  get(): Promise<FirestoreQuerySnapshotLike>;
};

export type FirestoreCollectionRefLike = FirestoreQueryLike & {
  doc(id: string): FirestoreDocumentRefLike;
};

export type FirestoreCollectionGroupRefLike = FirestoreQueryLike;

export type FirestoreLike = {
  collection(path: string): FirestoreCollectionRefLike;
  collectionGroup(collectionId: string): FirestoreCollectionGroupRefLike;
  doc(path: string): FirestoreDocumentRefLike;
  getAll(...documentRefs: unknown[]): Promise<FirestoreDocumentSnapshotLike[]>;
};

export type SchedulerLoggerLike = Pick<Console, "log" | "warn" | "error">;

const USER_LOCALE_BATCH_SIZE = 200;

function chunkArray<T>(values: T[], size: number): T[][] {
  if (values.length === 0) return [];

  const chunks: T[][] = [];
  for (let index = 0; index < values.length; index += size) {
    chunks.push(values.slice(index, index + size));
  }

  return chunks;
}

export function isAlreadyExistsError(error: unknown) {
  if (!error || typeof error !== "object") return false;

  const code = "code" in error ? error.code : undefined;
  if (code === 6 || code === "already-exists") {
    return true;
  }

  const message = "message" in error ? String(error.message ?? "") : "";
  return message.toLowerCase().includes("already exists");
}

export async function createDocumentIfMissing(
  docRef: FirestoreDocumentRefLike,
  data: FirebaseFirestore.DocumentData,
) {
  try {
    await docRef.create(data);
    return "created" as const;
  } catch (error) {
    if (isAlreadyExistsError(error)) {
      return "exists" as const;
    }

    throw error;
  }
}

export async function loadUserLocales(
  db: FirestoreLike,
  rawUserIds: string[],
) {
  const userIds = Array.from(
    new Set(
      rawUserIds
        .map((userId) => userId.trim())
        .filter((userId) => userId.length > 0),
    ),
  );

  const localeByUid = new Map<string, string>();
  for (const userId of userIds) {
    localeByUid.set(userId, "vi");
  }

  for (const batch of chunkArray(userIds, USER_LOCALE_BATCH_SIZE)) {
    const docRefs = batch.map((userId) => db.doc(`users/${userId}`));
    const snapshots = await db.getAll(...docRefs);

    snapshots.forEach((snapshot, index) => {
      if (!snapshot.exists) return;

      const userId = batch[index];
      const locale = String(snapshot.data()?.locale ?? "vi").trim() || "vi";
      localeByUid.set(userId, locale);
    });
  }

  return localeByUid;
}

export async function loadExistingDocumentPaths(
  db: FirestoreLike,
  rawDocumentRefs: FirestoreDocumentRefLike[],
) {
  const documentRefs = rawDocumentRefs.filter((docRef) => Boolean(docRef?.path));
  const existingPaths = new Set<string>();

  for (const batch of chunkArray(documentRefs, USER_LOCALE_BATCH_SIZE)) {
    const snapshots = await db.getAll(...batch);

    snapshots.forEach((snapshot, index) => {
      if (!snapshot.exists) return;

      existingPaths.add(batch[index].path);
    });
  }

  return existingPaths;
}
