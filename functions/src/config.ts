import { defineSecret, defineString } from "firebase-functions/params";

export const TZ = "Asia/Ho_Chi_Minh";
export const REGION = "asia-southeast1";

export const SOS_DAILY_LIMIT = 20;
export const SOS_MIN_INTERVAL_SEC = 10;
export const RATE_DOC_TTL_DAYS = 14;

export const TASK_LOCATION = "asia-southeast1";
export const RTDB_TRIGGER_REGION = "us-central1";
export const TASK_QUEUE = "sos-reminder-queue";
export const REMIND_INTERVAL_SEC = 10;
export const REMIND_MAX_SECONDS = 30 * 60;

export const SOS_REMINDER_WORKER_URL = defineString("SOS_REMINDER_WORKER_URL");

// thêm để send email
export const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
export const MAIL_FROM = defineString("MAIL_FROM");



// RESEND_API_KEY=re_aNk2vcpx_Lst9HFZTPH7hK2m2Npj43XYa
// MAIL_FROM=Kid Manager <no-reply@homiesmart.io.vn>