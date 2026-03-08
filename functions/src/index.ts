import { setGlobalOptions } from "firebase-functions/v2";
import { REGION } from "./config";

setGlobalOptions({ region: REGION });
// firebase deploy --only functions   
// $env:FUNCTIONS_DISCOVERY_TIMEOUT=30
export * from "./functions/mirror";
export * from "./functions/tokens";
export * from "./functions/sos";
export * from "./functions/locations";
export * from "./functions/notifications";
export * from "./functions/zones";
export * from "./functions/zoneEvents";
export * from "./functions/send_email";
export * from "./functions/user_auth";
export * from "./functions/subscriptionTriggers";