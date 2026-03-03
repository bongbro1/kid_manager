import { defineString } from "firebase-functions/params";

export const TZ = "Asia/Ho_Chi_Minh";

export const SOS_DAILY_LIMIT = 20;
export const SOS_MIN_INTERVAL_SEC = 10;
export const RATE_DOC_TTL_DAYS = 14;

export const TASK_LOCATION = "asia-southeast1";
export const TASK_QUEUE = "sos-reminder-queue";
export const REMIND_INTERVAL_SEC = 10;
export const REMIND_MAX_SECONDS = 30 * 60;

export const SOS_REMINDER_WORKER_URL = defineString("SOS_REMINDER_WORKER_URL");