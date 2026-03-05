import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { REGION, RESEND_API_KEY } from "../config";
import { admin } from "../bootstrap";
import { Resend } from "resend";

export const onMailQueueCreated = onDocumentCreated(
  {
    document: "mail_queue/{mailId}",
    region: REGION,
    retry: true,
    secrets: [RESEND_API_KEY],
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const mailId = event.params.mailId;
    const data = snap.data() as any;

    const to: string | undefined = data.to;
    const code: string | undefined = data.code;

    if (!to || !code) {
      console.log("[MAIL] Missing to/code -> skip");
      return;
    }

    console.log(`[MAIL] Triggered id=${mailId} to=${to}`);

    try {
      const resend = new Resend(RESEND_API_KEY.value());

      const { error } = await resend.emails.send({
        from: "Kid Manager <no-reply@homiesmart.io.vn>",
        to: [to], // ⚠️ Resend chuẩn là array
        subject: "Mã OTP xác thực tài khoản",
        html: `
          <div style="font-family:Arial,sans-serif">
            <h2>Xác thực tài khoản</h2>
            <p>Mã OTP của bạn:</p>
            <h1 style="letter-spacing:4px">${code}</h1>
            <p>Mã có hiệu lực trong 5 phút.</p>
          </div>
        `,
      });

      if (error) {
        throw error;
      }

      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`[MAIL] Sent successfully to ${to}`);
    } catch (error: any) {
      console.error("[MAIL] Send failed:", error?.message);

      await snap.ref.update({
        status: "error",
        error: error?.message ?? "unknown_error",
      });
    }
  }
);

// firebase functions:secrets:set RESEND_API_KEY
// re_aNk2vcpx_Lst9HFZTPH7hK2m2Npj43XYa

