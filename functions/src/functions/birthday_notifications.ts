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

function parseBirthYear(rawDob: unknown, rawDobIso: unknown): number | null {
  const candidates = [rawDobIso, rawDob];

  for (const candidate of candidates) {
    if (!candidate) continue;

    if (candidate instanceof admin.firestore.Timestamp) {
      return candidate.toDate().getUTCFullYear();
    }

    if (candidate instanceof Date) {
      return candidate.getFullYear();
    }

    if (typeof candidate === "number" && Number.isFinite(candidate)) {
      const parsed = new Date(candidate);
      if (!Number.isNaN(parsed.getTime())) {
        return parsed.getUTCFullYear();
      }
    }

    if (typeof candidate === "string") {
      const trimmed = candidate.trim();
      if (!trimmed) continue;

      const ddmmyyyy = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(trimmed);
      if (ddmmyyyy) {
        return Number(ddmmyyyy[3]);
      }

      const dateOnlyIso = /^(\d{4})-(\d{2})-(\d{2})$/.exec(trimmed);
      if (dateOnlyIso) {
        return Number(dateOnlyIso[1]);
      }

      const isoLike = /^(\d{4})-(\d{2})-(\d{2})T/.exec(trimmed);
      if (isoLike) {
        return Number(isoLike[1]);
      }

      const parsed = new Date(trimmed);
      if (!Number.isNaN(parsed.getTime())) {
        return parsed.getUTCFullYear();
      }
    }
  }

  return null;
}

function buildBirthdayText(opts: {
  locale: string;
  birthdayName: string;
  ageTurning: number | null;
  isSelf: boolean;
  daysUntil: number;
}) {
  const isEn = opts.locale.toLowerCase().startsWith("en");

  if (opts.daysUntil > 0) {
    if (opts.isSelf) {
      if (isEn) {
        return {
          title: "Birthday countdown🎂",
          body:
            opts.daysUntil === 1
              ? "Tomorrow is your birthday 🎂"
              : `Your birthday is in ${opts.daysUntil} days`,
        };
      }

      return {
        title: "Đếm ngược sinh nhật🎂",
        body:
          opts.daysUntil === 1
            ? "Ngày mai là sinh nhật của bạn 🎂"
            : `Sinh nhật của bạn còn ${opts.daysUntil} ngày nữa`,
      };
    }

    if (isEn) {
      return {
        title: "Upcoming birthday 🎂",
        body:
          opts.daysUntil === 1
            ? `Tomorrow is ${opts.birthdayName}'s birthday 🎂`
            : `${opts.birthdayName}'s birthday is in ${opts.daysUntil} days.`,
      };
    }

    return {
      title: "Sinh nhật sắp tới 🎂",
      body:
        opts.daysUntil === 1
          ? `Ngày mai là sinh nhật của ${opts.birthdayName} 🎂`
          : `Sắp tới sinh nhật của ${opts.birthdayName}! Còn ${opts.daysUntil} ngày nữa`,
    };
  }

  if (opts.isSelf) {
    if (isEn) {
      return {
        title: "Happy birthday 🎂",
        body:
          opts.ageTurning != null && opts.ageTurning > 0
            ? `Today you turn ${opts.ageTurning} 🎂`
            : "Today is your birthday.",
      };
    }

    return {
      title: "Chúc mừng sinh nhật 🎂",
      body:
        opts.ageTurning != null && opts.ageTurning > 0
          ? `Hôm nay bạn tròn ${opts.ageTurning} tuổi 🎂`
          : "Hôm nay là sinh nhật của bạn.",
    };
  }

  if (isEn) {
    return {
      title: "Birthday today 🎂",
      body:
        opts.ageTurning != null && opts.ageTurning > 0
          ? `Today is ${opts.birthdayName}'s birthday, turning ${opts.ageTurning} 🎂`
          : `Today is ${opts.birthdayName}'s birthday.`,
    };
  }

  return {
    title: "Sinh nhật hôm nay 🎂",
    body:
      opts.ageTurning != null && opts.ageTurning > 0
        ? `Hôm nay là sinh nhật của ${opts.birthdayName}, tròn ${opts.ageTurning} tuổi 🎂`
        : `Hôm nay là sinh nhật của ${opts.birthdayName}.`,
  };
}

type BirthdayNotificationDeps = {
  db: FirestoreLike;
  logger: SchedulerLoggerLike;
  now: () => Date;
  serverTimestamp: () => unknown;
  timeZone: string;
};

type BirthdaySearchTarget = {
  daysUntil: number;
  birthMonth: number;
  birthDay: number;
};

type BirthdayMatch = {
  familyId: string;
  doc: FirestoreQueryDocumentSnapshotLike;
  daysUntil: number;
};

function buildBirthdaySearchTargets(today: Date) {
  const targets: BirthdaySearchTarget[] = [];
  const seen = new Set<string>();

  function pushTarget(daysUntil: number, birthMonth: number, birthDay: number) {
    const key = `${daysUntil}:${birthMonth}:${birthDay}`;
    if (seen.has(key)) return;

    seen.add(key);
    targets.push({ daysUntil, birthMonth, birthDay });
  }

  for (let daysUntil = 0; daysUntil <= 7; daysUntil++) {
    const targetDate = addDays(today, daysUntil);
    const birthMonth = targetDate.getUTCMonth() + 1;
    const birthDay = targetDate.getUTCDate();

    pushTarget(daysUntil, birthMonth, birthDay);

    if (birthMonth === 2 && birthDay === 28 && !isLeapYear(targetDate.getUTCFullYear())) {
      pushTarget(daysUntil, 2, 29);
    }
  }

  return targets;
}

function resolveFamilyIdFromBirthdayDoc(doc: FirestoreQueryDocumentSnapshotLike) {
  const data = doc.data() ?? {};
  const familyId = String(data.familyId ?? "").trim();
  if (familyId) return familyId;

  const path = String(doc.ref?.path ?? "").trim();
  const parts = path.split("/");
  if (parts.length >= 4 && parts[0] === "families" && parts[2] === "members") {
    return parts[1];
  }

  return "";
}

export async function runBirthdayNotifications(
  deps: BirthdayNotificationDeps,
) {
  const now = deps.now();
  const { year, month, day, hour } = getZonedDateParts(now, deps.timeZone);
  const dayKey = formatDayKey(year, month, day);
  const today = utcNoonDate(year, month, day);

  if (hour < 7) {
    deps.logger.log(`[BIRTHDAY_NOTI] skip before 07:00 local time hour=${hour}`);
    return;
  }

  deps.logger.log(`[BIRTHDAY_NOTI] start dayKey=${dayKey}`);

  const birthdayMatches = new Map<string, BirthdayMatch>();
  const searchTargets = buildBirthdaySearchTargets(today);

  for (const target of searchTargets) {
    const membersSnap = await deps.db
      .collectionGroup("members")
      .where("birthMonth", "==", target.birthMonth)
      .where("birthDay", "==", target.birthDay)
      .get();

    for (const memberDoc of membersSnap.docs) {
      const familyId = resolveFamilyIdFromBirthdayDoc(memberDoc);
      if (!familyId) continue;

      const dedupeKey = `${familyId}:${memberDoc.id}:${target.daysUntil}`;
      birthdayMatches.set(dedupeKey, {
        familyId,
        doc: memberDoc,
        daysUntil: target.daysUntil,
      });
    }
  }

  deps.logger.log(
    `[BIRTHDAY_NOTI] searchTargets=${searchTargets.length} matchedBirthdays=${birthdayMatches.size}`,
  );

  if (birthdayMatches.size === 0) {
    deps.logger.log(`[BIRTHDAY_NOTI] no birthdays for dayKey=${dayKey}`);
    return;
  }

  const familyMembersCache = new Map<string, string[]>();
  for (const familyId of new Set(Array.from(birthdayMatches.values()).map((item) => item.familyId))) {
    const membersSnap = await deps.db
      .collection(`families/${familyId}/members`)
      .get();
    familyMembersCache.set(
      familyId,
      membersSnap.docs.map((memberDoc) => memberDoc.id),
    );
  }

  const localeCache = await loadUserLocales(
    deps.db,
    Array.from(familyMembersCache.values()).flat(),
  );
  let createdCount = 0;
  let skippedCount = 0;

  for (const birthdayItem of birthdayMatches.values()) {
    const familyId = birthdayItem.familyId;
    if (!familyId) continue;

    const birthdayDoc = birthdayItem.doc;
    const birthdayUid = birthdayDoc.id;
    const birthdayData = birthdayDoc.data();
    const daysUntil = birthdayItem.daysUntil;
    const birthdayName =
      String(birthdayData.displayName ?? birthdayData.email ?? birthdayUid).trim() ||
      "ThÃ nh viÃªn";
    const receiverIds = familyMembersCache.get(familyId) ?? [];
    const notificationRefs = receiverIds.map((receiverId) => ({
      receiverId,
      notificationId: daysUntil === 0
        ? `birthday_${dayKey}_${birthdayUid}_${receiverId}`
        : `birthday_countdown_${dayKey}_${birthdayUid}_${receiverId}`,
    }));

    const birthYear = parseBirthYear(birthdayData.dob, birthdayData.dobIso);
    const ageTurning =
      birthYear != null && birthYear <= year ? year - birthYear : null;
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

      const text = buildBirthdayText({
        locale,
        birthdayName,
        ageTurning,
        isSelf: receiverId === birthdayUid,
        daysUntil,
      });

      const result = await createDocumentIfMissing(notificationRef, {
        senderId: "system",
        receiverId,
        familyId,
        type: "birthday",
        title: text.title,
        body: text.body,
        data: {
          familyId,
          birthdayUid,
          birthdayName,
          ageTurning: ageTurning?.toString() ?? "",
          birthMonth: String(birthdayData.birthMonth ?? ""),
          birthDay: String(birthdayData.birthDay ?? ""),
          dayKey,
          birthdayPhase: daysUntil === 0 ? "today" : "countdown",
          daysUntil: String(daysUntil),
          isSelf: receiverId === birthdayUid ? "true" : "false",
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
    `[BIRTHDAY_NOTI] done dayKey=${dayKey} created=${createdCount} skipped=${skippedCount}`,
  );
}

export function createBirthdayNotificationsHandler(
  deps: BirthdayNotificationDeps,
) {
  return async () => runBirthdayNotifications(deps);
}

export const sendBirthdayNotifications = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: TZ,
    region: REGION,
  },
  createBirthdayNotificationsHandler({
    db,
    logger: console,
    now: () => new Date(),
    serverTimestamp: () => admin.firestore.FieldValue.serverTimestamp(),
    timeZone: TZ,
  }),
);
