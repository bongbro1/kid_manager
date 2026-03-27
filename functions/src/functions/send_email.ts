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
    const ref = snap.ref;

    const claimedData = await admin.firestore().runTransaction(async (tx) => {
      const freshSnap = await tx.get(ref);
      if (!freshSnap.exists) return null;

      const data = freshSnap.data() as any;
      const to: string | undefined = data.to;
      const type: string | undefined = data.type;

      if (!to || !type) {
        tx.update(ref, {
          status: "error",
          error: "missing_to_or_type",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return null;
      }

      if (data.status && data.status !== "pending") {
        console.log(
          `[MAIL] already processed id=${mailId} status=${data.status}`,
        );
        return null;
      }

      tx.update(ref, {
        status: "processing",
        processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return data;
    });

    if (!claimedData) return;

    const to: string = claimedData.to;
    const type: string = claimedData.type;

    const template = MAIL_TEMPLATES[type];
    if (!template) {
      await ref.update({
        status: "error",
        error: `unknown_template:${type}`,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.error(`[MAIL] Unknown template type=${type}`);
      return;
    }

    console.log(`[MAIL] Claimed id=${mailId} to=${to} type=${type}`);

    try {
      const resend = new Resend(RESEND_API_KEY.value());
      const html = template.render(claimedData);

      const result = await resend.emails.send({
        from: "Kid Manager <no-reply@homiesmart.io.vn>",
        to: [to],
        subject: template.subject,
        html,
      });

      if (result.error) {
        throw result.error;
      }

      await ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        provider: "resend",
        providerMessageId: result.data?.id ?? null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`[MAIL] Sent successfully id=${mailId} to=${to}`);
    } catch (error: any) {
      console.error("[MAIL] Send failed:", error?.message);

      await ref.update({
        status: "pending",
        lastError: error?.message ?? "unknown_error",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      throw error;
    }
  },
);

export type MailTemplate = {
  subject: string;
  render: (data: any) => string;
};

export const MAIL_TEMPLATES: Record<string, MailTemplate> = {
  verify_email: {
    subject: "Mã OTP xác thực tài khoản",
    render: ({ code }) => `
      <div style="font-family:Arial,sans-serif">
        <h2>Xác thực tài khoản</h2>
        <p>Mã OTP của bạn:</p>
        <h1 style="letter-spacing:4px">${code}</h1>
        <p>Mã có hiệu lực trong 5 phút.</p>
      </div>
    `,
  },

  reset_password: {
    subject: "Mã OTP đặt lại mật khẩu",
    render: ({ code }) => `
      <div style="font-family:Arial,sans-serif">
        <h2>Đặt lại mật khẩu</h2>
        <p>Mã OTP:</p>
        <h1>${code}</h1>
      </div>
    `,
  },
};
// firebase functions:secrets:set RESEND_API_KEY
// re_aNk2vcpx_Lst9HFZTPH7hK2m2Npj43XYa