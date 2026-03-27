import { onSchedule } from "firebase-functions/v2/scheduler";

import { admin, db } from "../bootstrap";
import { REGION, TZ } from "../config";
import {
  createDocumentIfMissing,
  type FirestoreLike,
  loadExistingDocumentPaths,
  loadUserLocales,
  type FirestoreQueryDocumentSnapshotLike,
  type SchedulerLoggerLike,
} from "./scheduler_utils";

type ReminderMeta = {
  memoryDayId: string;
  ownerParentUid: string;
  familyId: string;
  title: string;
  note: string;
  year: number;
  month: number;
  day: number;
  repeatYearly: boolean;
  reminderOffsets: number[];
};

function getZonedDateParts(date: Date, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    hour12: false,
  }).formatToParts(date);

  return {
    year: Number(parts.find((p) => p.type === "year")?.value ?? "1970"),
    month: Number(parts.find((p) => p.type === "month")?.value ?? "01"),
    day: Number(parts.find((p) => p.type === "day")?.value ?? "01"),
    hour: Number(parts.find((p) => p.type === "hour")?.value ?? "00"),
  };
}

function formatDayKey(year: number, month: number, day: number) {
  return [
    year.toString().padStart(4, "0"),
    month.toString().padStart(2, "0"),
    day.toString().padStart(2, "0"),
  ].join("-");
}

function utcNoonDate(year: number, month: number, day: number) {
  return new Date(Date.UTC(year, month - 1, day, 12, 0, 0, 0));
}

function isLeapYear(year: number) {
  if (year % 400 === 0) return true;
  if (year % 100 === 0) return false;
  return year % 4 === 0;
}

function addDays(base: Date, days: number) {
  return new Date(base.getTime() + days * 24 * 60 * 60 * 1000);
}

function normalizeReminderOffsets(raw: unknown): number[] {
  if (!Array.isArray(raw)) return [];

  return Array.from(
    new Set(
      raw
        .map((value) => {
          if (typeof value === "number") return Math.trunc(value);
          return Number.parseInt(String(value), 10);
        })
        .filter((value) => value === 1 || value === 3 || value === 7),
    ),
  ).sort((a, b) => a - b);
}

function mapReminderMeta(
  doc: FirestoreQueryDocumentSnapshotLike,
): ReminderMeta | null {
  const data = doc.data() ?? {};
  const familyId = String(data.familyId ?? "").trim();
  const ownerParentUid = String(data.ownerParentUid ?? "").trim();
  const memoryDayId = String(data.memoryDayId ?? doc.id).trim();
  const title = String(data.title ?? "").trim();
  const month = Number(data.month ?? 0);
  const day = Number(data.day ?? 0);
  const year = Number(data.year ?? 0);
  const reminderOffsets = normalizeReminderOffsets(data.reminderOffsets);

  if (!familyId || !ownerParentUid || !memoryDayId) return null;
  if (month <= 0 || day <= 0) return null;
  if (!reminderOffsets.length) return null;

  return {
    memoryDayId,
    ownerParentUid,
    familyId,
    title,
    note: String(data.note ?? "").trim(),
    year,
    month,
    day,
    repeatYearly: data.repeatYearly === true,
    reminderOffsets,
  };
}

function formatDisplayDate(date: Date) {
  const day = `${date.getUTCDate()}`.padStart(2, "0");
  const month = `${date.getUTCMonth() + 1}`.padStart(2, "0");
  const year = `${date.getUTCFullYear()}`;
  return `${day}/${month}/${year}`;
}

function buildReminderText(params: {
  locale: string;
  memoryDayTitle: string;
  dateText: string;
  daysUntil: number;
}) {
  const title = params.memoryDayTitle || "Memory Day";
  const isEn = params.locale.toLowerCase().startsWith("en");

  if (isEn) {
    return {
      title: "Upcoming memory day",
      body:
        params.daysUntil === 1
          ? `Tomorrow is "${title}" (${params.dateText}).`
          : `"${title}" is in ${params.daysUntil} days (${params.dateText}).`,
    };
  }

  return {
    title: "Sắp đến ngày đáng nhớ",
    body:
      params.daysUntil === 1
        ? `Ngày mai là "${title}" (${params.dateText}).`
        : `Còn ${params.daysUntil} ngày đến "${title}" (${params.dateText}).`,
  };
}

type MemoryDayReminderDeps = {
  db: FirestoreLike;
  logger: SchedulerLoggerLike;
  now: () => Date;
  serverTimestamp: () => unknown;
  timeZone: string;
};

type ReminderJob = {
  meta: ReminderMeta;
  occurrence: Date;
  daysUntil: number;
  receiverIds: string[];
};

type MemoryDaySearchTarget = {
  daysUntil: number;
  targetDate: Date;
  repeatYearly: boolean;
  year?: number;
  month: number;
  day: number;
};

function buildMemoryDaySearchTargets(today: Date) {
  const targets: MemoryDaySearchTarget[] = [];
  const seen = new Set<string>();

  function pushTarget(target: MemoryDaySearchTarget) {
    const key = [
      target.daysUntil,
      target.repeatYearly ? "yearly" : "dated",
      target.year ?? "",
      target.month,
      target.day,
    ].join(":");
    if (seen.has(key)) return;

    seen.add(key);
    targets.push(target);
  }

  for (const daysUntil of [1, 3, 7]) {
    const targetDate = addDays(today, daysUntil);
    const month = targetDate.getUTCMonth() + 1;
    const day = targetDate.getUTCDate();
    const year = targetDate.getUTCFullYear();

    pushTarget({
      daysUntil,
      targetDate,
      repeatYearly: false,
      year,
      month,
      day,
    });
    pushTarget({
      daysUntil,
      targetDate,
      repeatYearly: true,
      month,
      day,
    });

    if (month === 2 && day === 28 && !isLeapYear(year)) {
      pushTarget({
        daysUntil,
        targetDate,
        repeatYearly: true,
        month: 2,
        day: 29,
      });
    }
  }

  return targets;
}

export async function runMemoryDayReminders(
  deps: MemoryDayReminderDeps,
) {
  const now = deps.now();
  const { year, month, day, hour } = getZonedDateParts(now, deps.timeZone);
  const dayKey = formatDayKey(year, month, day);
  const today = utcNoonDate(year, month, day);

  if (hour < 7) {
    deps.logger.log(`[MEMORY_DAY_REMINDER] skip before 07:00 hour=${hour}`);
    return;
  }

  const reminderJobs = new Map<string, ReminderJob>();
  const searchTargets = buildMemoryDaySearchTargets(today);

  for (const target of searchTargets) {
    let query = deps.db
      .collectionGroup("memoryReminderMeta")
      .where("repeatYearly", "==", target.repeatYearly)
      .where("month", "==", target.month)
      .where("day", "==", target.day)
      .where("reminderOffsets", "array-contains", target.daysUntil);

    if (!target.repeatYearly) {
      query = query.where("year", "==", target.year ?? 0);
    }

    const metaSnap = await query.get();

    for (const doc of metaSnap.docs) {
      const meta = mapReminderMeta(doc);
      if (!meta) continue;

      const dedupeKey = `${meta.memoryDayId}:${target.daysUntil}`;
      reminderJobs.set(dedupeKey, {
        meta,
        occurrence: target.targetDate,
        daysUntil: target.daysUntil,
        receiverIds: [],
      });
    }
  }

  deps.logger.log(
    `[MEMORY_DAY_REMINDER] start dayKey=${dayKey} searchTargets=${searchTargets.length} matchedReminders=${reminderJobs.size}`,
  );

  const familyMembersCache = new Map<string, string[]>();
  for (const job of reminderJobs.values()) {
    let receiverIds = familyMembersCache.get(job.meta.familyId);
    if (!receiverIds) {
      const membersSnap = await deps.db
        .collection(`families/${job.meta.familyId}/members`)
        .get();
      receiverIds = membersSnap.docs.map((memberDoc) => memberDoc.id);
      familyMembersCache.set(job.meta.familyId, receiverIds);
    }

    job.receiverIds = receiverIds;
  }

  const localeCache = await loadUserLocales(
    deps.db,
    Array.from(familyMembersCache.values()).flat(),
  );
  let createdCount = 0;
  let skippedCount = 0;

  for (const job of reminderJobs.values()) {
    const dateText = formatDisplayDate(job.occurrence);
    const memoryDayTitle = job.meta.title || "Memory Day";
    const notificationRefs = job.receiverIds.map((receiverId) => ({
      receiverId,
      notificationId: [
        "memory_day_reminder",
        dayKey,
        job.meta.memoryDayId,
        receiverId,
        `${job.daysUntil}`,
      ].join("_"),
    }));
    const existingNotificationPaths = await loadExistingDocumentPaths(
      deps.db,
      notificationRefs.map(({ notificationId }) =>
        deps.db.collection("notifications").doc(notificationId)
      ),
    );

    for (const { receiverId, notificationId } of notificationRefs) {
      const notificationRef = deps.db.collection("notifications").doc(notificationId);
      if (existingNotificationPaths.has(notificationRef.path)) {
        skippedCount++;
        continue;
      }

      const locale = localeCache.get(receiverId) ?? "vi";

      const text = buildReminderText({
        locale,
        memoryDayTitle,
        dateText,
        daysUntil: job.daysUntil,
      });

      const result = await createDocumentIfMissing(notificationRef, {
        senderId: "system",
        receiverId,
        familyId: job.meta.familyId,
        type: "memoryDay",
        title: text.title,
        body: text.body,
        data: {
          entity: "memory_day",
          action: "reminder",
          reminderPhase: "countdown",
          memoryDayId: job.meta.memoryDayId,
          memoryDayTitle,
          ownerParentUid: job.meta.ownerParentUid,
          familyId: job.meta.familyId,
          date: dateText,
          repeatYearly: job.meta.repeatYearly ? "true" : "false",
          note: job.meta.note,
          daysUntil: `${job.daysUntil}`,
          reminderOffset: `${job.daysUntil}`,
          dayKey,
        },
        isRead: false,
        status: "pending",
        createdAt: deps.serverTimestamp(),
      });

      if (result === "created") {
        createdCount++;
      } else {
        skippedCount++;
      }
    }
  }

  deps.logger.log(
    `[MEMORY_DAY_REMINDER] done dayKey=${dayKey} created=${createdCount} skipped=${skippedCount}`,
  );
}

export function createMemoryDayRemindersHandler(
  deps: MemoryDayReminderDeps,
) {
  return async () => runMemoryDayReminders(deps);
}

export const sendMemoryDayReminders = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: TZ,
    region: REGION,
  },
  createMemoryDayRemindersHandler({
    db,
    logger: console,
    now: () => new Date(),
    serverTimestamp: () => admin.firestore.FieldValue.serverTimestamp(),
    timeZone: TZ,
  }),
);
