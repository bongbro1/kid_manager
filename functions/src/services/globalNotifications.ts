import { randomUUID } from "crypto";
import { admin, db } from "../bootstrap";

export async function createGlobalNotificationRecord(params: {
  notificationId?: string;
  receiverId: string;
  senderId: string;
  type: string;
  title: string;
  body: string;
  eventKey?: string;
  familyId?: string;
  eventCategory?: string;
  expiresAt?: FirebaseFirestore.Timestamp | null;
  data?: Record<string, any>;
}) {
  const notificationId = params.notificationId ?? randomUUID();

  await db.doc(`notifications/${notificationId}`).set({
    senderId: params.senderId,
    receiverId: params.receiverId,
    type: params.type,
    title: params.title,
    body: params.body,
    eventKey: params.eventKey ?? "",
    familyId: params.familyId ?? null,
    eventCategory: params.eventCategory ?? null,
    expiresAt: params.expiresAt ?? null,
    data: params.data ?? {},
    isRead: false,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return notificationId;
}
