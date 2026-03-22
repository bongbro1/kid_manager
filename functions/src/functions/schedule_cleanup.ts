import {onSchedule} from "firebase-functions/v2/scheduler";

import {admin, db} from "../bootstrap";
import {REGION, TZ} from "../config";

const SCHEDULE_RETENTION_DAYS = 7;
const DELETE_PAGE_SIZE = 50;
const MAX_DELETE_RETRIES = 3;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Builds the cutoff timestamp for expired schedules.
 * @param {Date} now Current execution time.
 * @return {FirebaseFirestore.Timestamp} Expiration cutoff.
 */
function buildCutoffTimestamp(now: Date) {
  return admin.firestore.Timestamp.fromMillis(
    now.getTime() - SCHEDULE_RETENTION_DAYS * MS_PER_DAY,
  );
}

/**
 * Guards the cleanup to the expected parents/{uid}/schedules path.
 * @param {FirebaseFirestore.DocumentReference} scheduleRef Schedule doc ref.
 * @return {boolean} Whether the ref belongs to a parent schedule path.
 */
function isParentSchedulePath(
  scheduleRef: FirebaseFirestore.DocumentReference,
) {
  const parentDoc = scheduleRef.parent.parent;
  return parentDoc != null && parentDoc.parent.id === "parents";
}

/**
 * Builds the expired schedule query for a specific parent namespace.
 * @param {string} parentUid Parent namespace id.
 * @param {FirebaseFirestore.Timestamp} cutoff Expiration cutoff.
 * @return {FirebaseFirestore.Query<FirebaseFirestore.DocumentData>} Query page.
 */
function buildExpiredSchedulesByParentQuery(
  parentUid: string,
  cutoff: FirebaseFirestore.Timestamp,
) {
  return db
    .collection("parents")
    .doc(parentUid)
    .collection("schedules")
    .where("endAt", "<", cutoff)
    .orderBy("endAt")
    .limit(DELETE_PAGE_SIZE);
}

export const cleanupExpiredSchedules = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: TZ,
    region: REGION,
    timeoutSeconds: 540,
  },
  async () => {
    const startedAt = Date.now();
    const cutoff = buildCutoffTimestamp(new Date());

    console.log(
      `[SCHEDULE_CLEANUP] start cutoff=${cutoff.toDate().toISOString()}`,
    );

    const parentRefs = await db.collection("parents").listDocuments();

    let scannedSchedules = 0;
    let deletedSchedules = 0;
    let skippedSchedules = 0;
    let scannedParents = 0;

    for (const parentDoc of parentRefs) {
      scannedParents++;
      const parentUid = parentDoc.id;
      let hasMore = true;

      while (hasMore) {
        const snapshot = await buildExpiredSchedulesByParentQuery(
          parentUid,
          cutoff,
        ).get();

        hasMore = !snapshot.empty;
        if (!hasMore) break;

        const bulkWriter = db.bulkWriter();
        bulkWriter.onWriteError((error) => {
          console.error(
            `[SCHEDULE_CLEANUP] write error path=${error.documentRef.path}` +
              ` attempt=${error.failedAttempts} code=${error.code}`,
            error,
          );
          return error.failedAttempts < MAX_DELETE_RETRIES;
        });

        try {
          for (const scheduleDoc of snapshot.docs) {
            scannedSchedules++;

            if (!isParentSchedulePath(scheduleDoc.ref)) {
              skippedSchedules++;
              console.warn(
                "[SCHEDULE_CLEANUP] skip unexpected " +
                  `path=${scheduleDoc.ref.path}`,
              );
              continue;
            }

            console.log(
              `[SCHEDULE_CLEANUP] deleting parentUid=${parentUid}` +
                ` scheduleId=${scheduleDoc.id}` +
                ` path=${scheduleDoc.ref.path}`,
            );

            await db.recursiveDelete(scheduleDoc.ref, bulkWriter);
            deletedSchedules++;
          }
        } finally {
          await bulkWriter.close();
        }
      }
    }

    console.log(
      `[SCHEDULE_CLEANUP] done parents=${scannedParents}` +
        ` scanned=${scannedSchedules}` +
        ` deleted=${deletedSchedules}` +
        ` skipped=${skippedSchedules}` +
        ` durationMs=${Date.now() - startedAt}`,
    );
  },
);
