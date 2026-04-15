import { admin } from "../bootstrap";
import { t } from "../i18n";

export const BATTERY_EVENT_CATEGORY = "battery_status";
export const BATTERY_NOTIFICATION_TTL_MS = 24 * 60 * 60 * 1000;
export const BATTERY_LOW_THRESHOLD = 20;
export const BATTERY_CRITICAL_THRESHOLD = 10;
export const BATTERY_RESET_THRESHOLD = 25;

export type BatterySeverity = "normal" | "low" | "critical" | "unavailable";
export type BatteryAlertSeverity = "low" | "critical";

function toFiniteNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value;
  }

  if (typeof value === "string" && value.trim()) {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) {
      return parsed;
    }
  }

  return null;
}

export function normalizeBatteryLevel(value: unknown): number | null {
  const numberValue = toFiniteNumber(value);
  if (numberValue == null) {
    return null;
  }

  return Math.max(0, Math.min(100, Math.round(numberValue)));
}

export function normalizeChargingState(value: unknown): boolean | null {
  if (typeof value === "boolean") {
    return value;
  }
  if (typeof value === "string" && value.trim()) {
    return value.trim().toLowerCase() == "true";
  }
  return null;
}

export function deriveBatterySeverity(params: {
  batteryLevel: number | null;
  isCharging: boolean | null;
}): BatterySeverity {
  if (params.batteryLevel == null) {
    return "unavailable";
  }
  if (params.isCharging === true) {
    return "normal";
  }
  if (params.batteryLevel <= BATTERY_CRITICAL_THRESHOLD) {
    return "critical";
  }
  if (params.batteryLevel <= BATTERY_LOW_THRESHOLD) {
    return "low";
  }
  return "normal";
}

export function shouldResetBatteryAlert(params: {
  batteryLevel: number | null;
  isCharging: boolean | null;
  severity: BatterySeverity;
}): boolean {
  if (params.isCharging === true) {
    return true;
  }
  if (
    params.batteryLevel != null &&
    params.batteryLevel > BATTERY_RESET_THRESHOLD
  ) {
    return true;
  }
  return params.severity === "normal" || params.severity === "unavailable";
}

export function eventKeyForBatterySeverity(
  severity: BatteryAlertSeverity,
): string {
  return `battery.${severity}.parent`;
}

export function buildBatteryNotificationRecord(params: {
  locale: string;
  childUid: string;
  childName: string;
  familyId: string;
  batteryLevel: number;
  isCharging: boolean;
  severity: BatteryAlertSeverity;
  nowMs: number;
}) {
  const eventKey = eventKeyForBatterySeverity(params.severity);
  const templateParams = {
    childName: params.childName,
    batteryLevel: String(params.batteryLevel),
  };

  const title = t(params.locale, `${eventKey}.title`, templateParams);
  const body = t(params.locale, `${eventKey}.body`, templateParams);

  return {
    title,
    body,
    eventKey,
    eventCategory: BATTERY_EVENT_CATEGORY,
    expiresAt: admin.firestore.Timestamp.fromMillis(
      params.nowMs + BATTERY_NOTIFICATION_TTL_MS,
    ),
    data: {
      actorUid: params.childUid,
      actorName: params.childName,
      actorRole: "child",
      childUid: params.childUid,
      childName: params.childName,
      familyId: params.familyId,
      batteryLevel: String(params.batteryLevel),
      isCharging: String(params.isCharging),
      severity: params.severity,
      timestamp: String(params.nowMs),
      eventKey,
      title,
      body,
      eventCategory: BATTERY_EVENT_CATEGORY,
    },
  };
}
