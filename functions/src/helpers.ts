import { createHash } from "crypto";
import { HttpsError } from "firebase-functions/v2/https";

export type Platform = "android" | "ios";

export function sha256Hex(input: string): string {
  return createHash("sha256").update(input).digest("hex");
}

export function mustString(v: unknown, name: string): string {
  if (typeof v !== "string" || !v.trim()) {
    throw new HttpsError("invalid-argument", `${name} is required`);
  }
  return v.trim();
}

export function mustNumber(v: unknown, name: string): number {
  if (typeof v !== "number" || !Number.isFinite(v)) {
    throw new HttpsError("invalid-argument", `${name} must be a finite number`);
  }
  return v;
}

export function mustPlatform(v: unknown): Platform {
  if (v !== "android" && v !== "ios") {
    throw new HttpsError("invalid-argument", "platform must be 'android' or 'ios'");
  }
  return v;
}

export function validateLatLng(lat: number, lng: number) {
  if (lat < -90 || lat > 90) throw new HttpsError("invalid-argument", "lat out of range");
  if (lng < -180 || lng > 180) throw new HttpsError("invalid-argument", "lng out of range");
}

export function dayKeyInTZ(d: Date, timeZone: string): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(d);
}

export function isValidTimeZone(value: unknown): value is string {
  if (typeof value !== "string" || !value.trim()) {
    return false;
  }

  try {
    new Intl.DateTimeFormat("en-US", {
      timeZone: value.trim(),
      year: "numeric",
    }).format(new Date(0));
    return true;
  } catch {
    return false;
  }
}

export function normalizeTimeZone(
  value: unknown,
  fallbackTimeZone: string,
): string {
  if (isValidTimeZone(value)) {
    return value.trim();
  }
  return fallbackTimeZone;
}

export function zonedDateParts(ms: number, timeZone: string) {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    weekday: "short",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).formatToParts(new Date(ms));

  const weekdayToken =
    parts.find((part) => part.type === "weekday")?.value ?? "Mon";
  const year = Number(parts.find((part) => part.type === "year")?.value ?? 1970);
  const month = Number(parts.find((part) => part.type === "month")?.value ?? 1);
  const day = Number(parts.find((part) => part.type === "day")?.value ?? 1);
  const hour = Number(parts.find((part) => part.type === "hour")?.value ?? 0);
  const minute = Number(
    parts.find((part) => part.type === "minute")?.value ?? 0
  );

  const weekday = (() => {
    switch (weekdayToken.slice(0, 3).toLowerCase()) {
      case "mon":
        return 1;
      case "tue":
        return 2;
      case "wed":
        return 3;
      case "thu":
        return 4;
      case "fri":
        return 5;
      case "sat":
        return 6;
      case "sun":
      default:
        return 7;
    }
  })();

  return {
    weekday,
    dayKey: `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(
      2,
      "0"
    )}`,
    minutesOfDay: hour * 60 + minute,
  };
}

export function chunk<T>(arr: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

export function isInvalidTokenErrorCode(code?: string): boolean {
  return (
    code === "messaging/registration-token-not-registered" ||
    code === "messaging/invalid-registration-token"
  );
}

export function convertDataToString(data: any = {}) {
  const result: Record<string, string> = {};
  Object.keys(data).forEach((k) => {
    result[k] = String(data[k]);
  });
  return result;
}

export function getProjectId(): string {
  return (
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    process.env.PROJECT_ID ||
    ""
  );
}
