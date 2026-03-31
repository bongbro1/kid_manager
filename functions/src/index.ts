import { setGlobalOptions } from "firebase-functions/v2";
import { REGION } from "./config";

setGlobalOptions({ region: REGION });
// firebase deploy --only functions
//MAIL_FROM=Kid Manager <no-reply@homiesmart.io.vn>
// $env:FUNCTIONS_DISCOVERY_TIMEOUT=30
export * from "./functions/mirror";
export * from "./functions/family_members";
export * from "./functions/birthday_notifications";
export * from "./functions/memory_day_reminders";
export * from "./functions/tokens";
export * from "./functions/sos";
export * from "./functions/locations";
export * from "./functions/notifications";
export * from "./functions/notification_cleanup";
export * from "./functions/mapbox";
export * from "./functions/zones";
export * from "./functions/zoneEvents";
export * from "./functions/send_email";
export * from "./functions/subscription_triggers";
export * from "./functions/detect_offline_child";
export * from "./functions/schedule_cleanup";
export {
  requestEmailOtp,
  verifyEmailOtp,
  requestPasswordReset,
  verifyPasswordResetOtp,
  resetUserPassword,
} from "./functions/user_auth";
export { sendFamilyMessage, onFamilyChatMessageCreated } from "./functions/family_chat";
export { markFamilyChatRead } from "./functions/family_chat_read";
export { reportTrackingStatus } from "./functions/tracking/reportTrackingStatus";
export { onTrackingStatusWritten } from "./functions/tracking/onTrackingStatusWritten";
export { checkTrackingHeartbeat } from "./functions/tracking/checkTrackingHeartbeat";
export * from "./triggers/safeRoute";
