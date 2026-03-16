import { onSchedule } from "firebase-functions/v2/scheduler";
import { admin, db } from "../bootstrap";
import { REGION, TZ } from "../config";

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

function isLeapYear(year: number) {
  if (year % 400 === 0) return true;
  if (year % 100 === 0) return false;
  return year % 4 === 0;
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
}) {
  const isEn = opts.locale.toLowerCase().startsWith("en");

  if (opts.isSelf) {
    if (isEn) {
      return {
        title: "Happy birthday",
        body:
          opts.ageTurning != null && opts.ageTurning > 0
            ? `Today you turn ${opts.ageTurning}.`
            : "Today is your birthday.",
      };
    }

    return {
      title: "Chúc mừng sinh nhật",
      body:
        opts.ageTurning != null && opts.ageTurning > 0
          ? `Hôm nay bạn tròn ${opts.ageTurning} tuổi.`
          : "Hôm nay là sinh nhật của bạn.",
    };
  }

  if (isEn) {
    return {
      title: "Birthday today",
      body:
        opts.ageTurning != null && opts.ageTurning > 0
          ? `Today is ${opts.birthdayName}'s birthday, turning ${opts.ageTurning}.`
          : `Today is ${opts.birthdayName}'s birthday.`,
    };
  }

  return {
    title: "Sinh nhật hôm nay",
    body:
      opts.ageTurning != null && opts.ageTurning > 0
        ? `Hôm nay là sinh nhật của ${opts.birthdayName}, tròn ${opts.ageTurning} tuổi.`
        : `Hôm nay là sinh nhật của ${opts.birthdayName}.`,
  };
}

export const sendBirthdayNotifications = onSchedule(
  {
    schedule: "every 60 minutes",
    timeZone: TZ,
    region: REGION,
  },
  async () => {
    const now = new Date();
    const { year, month, day, hour } = getZonedDateParts(now, TZ);
    const dayKey = formatDayKey(year, month, day);

    if (hour < 7) {
      console.log(`[BIRTHDAY_NOTI] skip before 07:00 local time hour=${hour}`);
      return;
    }

    console.log(`[BIRTHDAY_NOTI] start dayKey=${dayKey}`);

    const shouldIncludeLeapBirthdays =
      month === 2 && day === 28 && !isLeapYear(year);
    const familiesSnap = await db.collection("families").get();
    const birthdayDocs: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[] = [];

    for (const familyDoc of familiesSnap.docs) {
      const membersSnap = await db
        .collection(`families/${familyDoc.id}/members`)
        .where("birthMonth", "==", month)
        .get();

      for (const memberDoc of membersSnap.docs) {
        const birthDay = Number(memberDoc.data().birthDay ?? 0);
        if (birthDay === day || (shouldIncludeLeapBirthdays && birthDay === 29)) {
          birthdayDocs.push(memberDoc);
        }
      }
    }

    console.log(
      `[BIRTHDAY_NOTI] families=${familiesSnap.size} matchedBirthdays=${birthdayDocs.length}`
    );

    if (birthdayDocs.length === 0) {
      console.log(`[BIRTHDAY_NOTI] no birthdays for dayKey=${dayKey}`);
      return;
    }

    const familyMembersCache = new Map<string, string[]>();
    const localeCache = new Map<string, string>();
    let createdCount = 0;
    let skippedCount = 0;

    for (const birthdayDoc of birthdayDocs) {
      const familyId = birthdayDoc.ref.parent.parent?.id ?? "";
      if (!familyId) continue;

      const birthdayUid = birthdayDoc.id;
      const birthdayData = birthdayDoc.data();
      const birthdayName =
        String(birthdayData.displayName ?? birthdayData.email ?? birthdayUid).trim() ||
        "Thành viên";

      let receiverIds = familyMembersCache.get(familyId);
      if (!receiverIds) {
        const membersSnap = await db.collection(`families/${familyId}/members`).get();
        receiverIds = membersSnap.docs.map((doc) => doc.id);
        familyMembersCache.set(familyId, receiverIds);
      }

      const birthYear = parseBirthYear(birthdayData.dob, birthdayData.dobIso);
      const ageTurning =
        birthYear != null && birthYear <= year ? year - birthYear : null;

      for (const receiverId of receiverIds) {
        const notificationId = `birthday_${dayKey}_${birthdayUid}_${receiverId}`;
        const notificationRef = db.collection("notifications").doc(notificationId);
        const existing = await notificationRef.get();
        if (existing.exists) {
          skippedCount++;
          continue;
        }

        let locale = localeCache.get(receiverId);
        if (!locale) {
          const userSnap = await db.doc(`users/${receiverId}`).get();
          locale = String(userSnap.data()?.locale ?? "vi");
          localeCache.set(receiverId, locale);
        }

        const text = buildBirthdayText({
          locale,
          birthdayName,
          ageTurning,
          isSelf: receiverId === birthdayUid,
        });

        await notificationRef.set({
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
            isSelf: receiverId === birthdayUid ? "true" : "false",
          },
          isRead: false,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        createdCount++;
      }
    }

    console.log(
      `[BIRTHDAY_NOTI] done dayKey=${dayKey} created=${createdCount} skipped=${skippedCount}`
    );
  }
);
