import { setGlobalOptions } from "firebase-functions/v2";
import { REGION } from "";

setGlobalOptions({ region: REGION });

export * from "./functions/mirror";
export * from "./functions/tokens";
export * from "./functions/sos";
export * from "./functions/locations";
export * from "./functions/notifications";