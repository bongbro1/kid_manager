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

export function getProjectId(): string {
  return (
    process.env.GCLOUD_PROJECT ||
    process.env.GCP_PROJECT ||
    process.env.PROJECT_ID ||
    ""
  );
}