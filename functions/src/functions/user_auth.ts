import { HttpsError, onCall } from "firebase-functions/https";
import { REGION } from "../config";
import { admin } from "../bootstrap";
export const resetUserPassword = onCall(
  { region: REGION },
  async (request) => {

    const { uid, newPassword } = request.data;

    console.log("RESET PASSWORD REQUEST");
    console.log("UID:", uid);

    if (!uid || !newPassword) {
      throw new HttpsError(
        "invalid-argument",
        "Missing uid or newPassword"
      );
    }

    try {

      await admin.auth().updateUser(uid, {
        password: newPassword,
      });

      // revoke session cũ
      await admin.auth().revokeRefreshTokens(uid);

      return { success: true };

    } catch (error) {

      console.error("RESET PASSWORD ERROR:", error);

      throw new HttpsError(
        "internal",
        "Password reset failed"
      );
    }
  }
);