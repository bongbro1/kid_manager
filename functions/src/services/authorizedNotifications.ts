import { HttpsError } from "firebase-functions/v2/https";

export const CLIENT_NOTIFICATION_TITLE_MAX_LENGTH = 160;
export const CLIENT_NOTIFICATION_BODY_MAX_LENGTH = 1000;
export const CLIENT_ENQUEUABLE_NOTIFICATION_TYPES = new Set([
  "schedule",
  "memoryDay",
  "importExcel",
  "blockedApp",
]);

const LOCALIZATION_KEY_PATTERN = /^[a-z0-9_.-]+\.(title|body)$/i;

export function looksLikeNotificationLocalizationKey(value: unknown): boolean {
  if (typeof value !== "string") {
    return false;
  }

  return LOCALIZATION_KEY_PATTERN.test(value.trim());
}

function readTrimmedString(
  value: unknown,
  fieldName: string,
  maxLength: number,
): string {
  if (typeof value !== "string") {
    throw new HttpsError("invalid-argument", `${fieldName} must be a string`);
  }

  const normalized = value.trim();
  if (!normalized) {
    throw new HttpsError("invalid-argument", `${fieldName} is required`);
  }

  if (normalized.length > maxLength) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} must be <= ${maxLength} characters`,
    );
  }

  if (looksLikeNotificationLocalizationKey(normalized)) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} must be human-readable text`,
    );
  }

  return normalized;
}

export function normalizeClientNotificationCreateInput(params: {
  type: unknown;
  title: unknown;
  body: unknown;
  familyId?: unknown;
  receiverId: unknown;
  data?: unknown;
}) {
  const type =
    typeof params.type === "string" ? params.type.trim() : "";
  if (!CLIENT_ENQUEUABLE_NOTIFICATION_TYPES.has(type)) {
    throw new HttpsError(
      "permission-denied",
      "Notification type is not allowed from client",
    );
  }

  const receiverId = readTrimmedString(params.receiverId, "receiverId", 128);
  const title = readTrimmedString(
    params.title,
    "title",
    CLIENT_NOTIFICATION_TITLE_MAX_LENGTH,
  );
  const body = readTrimmedString(
    params.body,
    "body",
    CLIENT_NOTIFICATION_BODY_MAX_LENGTH,
  );
  const familyId =
    typeof params.familyId === "string" && params.familyId.trim()
      ? params.familyId.trim()
      : null;

  let data: Record<string, unknown> = {};
  if (params.data != null) {
    if (typeof params.data !== "object" || Array.isArray(params.data)) {
      throw new HttpsError("invalid-argument", "data must be an object");
    }
    data = {...(params.data as Record<string, unknown>)};
  }

  return {
    type,
    title,
    body,
    receiverId,
    familyId,
    data,
  };
}
