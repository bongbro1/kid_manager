import * as admin from "firebase-admin";

admin.initializeApp();

export { admin };
export const db = admin.firestore();