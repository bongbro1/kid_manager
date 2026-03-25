# Phase 5 Audit Report

## Phase 5 - Notifications, Chat, Email và Communication Flows

### 1. Đăng xuất không unregister FCM token, thiết bị da logout v?n có thể nh?n push cua tài khoản cu

- File: `lib/viewmodels/auth_vm.dart:201-204`
- File: `lib/services/notifications/fcm_push_receiver_service.dart:36-38`
- File: `functions/src/functions/tokens.ts:64-92`
- Loại lỗi: `Security`, `Privacy`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Luong logout hiện tại goi `_authRepo.logout()` roi ch? set `_currentUid = null`.
- Backend da co callable `unregisterFcmToken`, nh?ng client không bao gio goi no khi Đăng xuất.
- He qua la installation hiện tại v?n gan voi uid cu trong `fcmInstallations`, nen OS có thể tiếp tục nh?n push cua tài khoản tr??c ngay c? khi app da logout.

Đoạn code lỗi:

```dart
Future<void> logout() async {
 ...
 await _authRepo.logout();
 await FcmPushReceiverService.onSignedOut();
 await _storage.clearAuthData();
}
```

```dart
static Future<void> onSignedOut() async {
 _currentUid = null;
}
```

Đoạn code đề xuất sửa lỗi:

```dart
static Future<void> unregisterCurrentDevice() async {
 final uid = _currentUid?.trim();
 if (uid == null || uid.isEmpty) return;

 final installationId = await FcmInstallationService.getInstallationId();
 await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
   .httpsCallable('unregisterFcmToken')
   .call({'installationId': installationId});

 _currentUid = null;
}

Future<void> logout() async {
 _loading = true;
 _error = null;
 notifyListeners();

 try {
  await FcmPushReceiverService.unregisterCurrentDevice();
  await _authRepo.logout();
  await _storage.clearAuthData();
  _user = null;
 } ...
}
```

---

### 2. `onNotificationCreated` de `retry: true` nh?ng không có idempotency claim, de duplicate push và sai tr?ng thời delivery

- File: `functions/src/functions/notifications.ts:26-31`
- File: `functions/src/functions/notifications.ts:100-155`
- Loại lỗi: `Bug`, `Reliability`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Trigger push notification đang bat `retry: true`.
- Function gui FCM truoc, sau do moi `update({ status: "sent" })`.
- Neu send thanh cong nh?ng function crash tr??c khi update status, Cloud Functions se retry và gui lai toan bo push.
- Ngoai ra code luon set `status: "sent"` du m?t so token co loi tam thoi, lam mat kh? n?ng retry co kiem soat.

Đoạn code lỗi:

```ts
export const onNotificationCreated = onDocumentCreated(
 {
  document: "notifications/{notificationId}",
  region: REGION,
  retry: true,
 },
 async (event) => {
  ...
  const resp = await admin.messaging().sendEachForMulticast({...});
  ...
  await snap.ref.update({ status: "sent" });
 }
);
```

Đoạn code đề xuất sửa lỗi:

```ts
const claimed = await db.runTransaction(async (tx) => {
 const fresh = await tx.get(snap.ref);
 if (!fresh.exists) return false;

 const status = String(fresh.get("status") ?? "pending");
 if (status !== "pending") return false;

 tx.update(snap.ref, {
  status: "sending",
  sendingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
 });
 return true;
});

if (!claimed) return;

const resp = await admin.messaging().sendEachForMulticast({...});
const hasTransientFailure = resp.responses.some(
 (r) => !r.success && !shouldDeleteInvalidToken(r.error?.code ?? "")
);

await snap.ref.update({
 status: hasTransientFailure ? "partial_failure" : "sent",
 sentAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

---

### 3. `onMailQueueCreated` cung co retry race, có thể gui trung OTP/reset email

- File: `functions/src/functions/send_email.ts:5-10`
- File: `functions/src/functions/send_email.ts:27-31`
- File: `functions/src/functions/send_email.ts:42-68`
- Loại lỗi: `Bug`, `Security`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Trigger email đang de `retry: true` và ch? guard bang `if (data.status && data.status !== "pending")`.
- Email được gui truoc, sau do moi update Firestore sang `sent`.
- Neu nha cung cap da gui email nh?ng function crash tr??c khi `snap.ref.update`, invocation retry se gui them m?t email nua.
- Trong flow OTP/reset password, duplicate mail lam ng??i d?ng nham lan và mo rong attack surface cho spam/abuse.

Đoạn code lỗi:

```ts
export const onMailQueueCreated = onDocumentCreated(
 {
  document: "mail_queue/{mailId}",
  region: REGION,
  retry: true,
  secrets: [RESEND_API_KEY],
 },
 async (event) => {
  ...
  const { error } = await resend.emails.send({...});
  ...
  await snap.ref.update({
   status: "sent",
   sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
 }
);
```

Đoạn code đề xuất sửa lỗi:

```ts
const claimed = await admin.firestore().runTransaction(async (tx) => {
 const fresh = await tx.get(snap.ref);
 if (!fresh.exists) return false;

 const status = String(fresh.get("status") ?? "pending");
 if (status !== "pending") return false;

 tx.update(snap.ref, {
  status: "sending",
  sendingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
 });
 return true;
});

if (!claimed) return;

const result = await resend.emails.send({...});
await snap.ref.update({
 status: "sent",
 providerMessageId: result.data?.id ?? null,
 sentAt: admin.firestore.FieldValue.serverTimestamp(),
});
```
---

### 4. `NotificationDetailScreen` có thể treo loading vo han khi load detail that bai

- File: `lib/viewmodels/notification_vm.dart:241-254`
- File: `lib/views/notifications/notification_detail_screen.dart:273-294`
- Loại lỗi: `Bug`, `UX`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `loadNotificationDetailItem()` set `_error` và `notificationDetail = null` khi request loi.
- Tuy nhi?n `NotificationDetailScreen.build()` ch? check `if (detail == null) return LoadingOverlay();`.
- Ket qua la khi detail fetch fail, man hinh detail không bao loi m? mac ket o tr?ng thời loading vo han.

Đoạn code lỗi:

```dart
} catch (e) {
 debugPrint("Load notification detail error: $e");
 notificationDetail = null;
 _error = e.toString();
} finally {
 _loading = false;
 notifyListeners();
}
```

```dart
final detail = vm.notificationDetail;
...
if (detail == null) return LoadingOverlay();
```

Đoạn code đề xuất sửa lỗi:

```dart
Future<void> loadNotificationDetailItem(AppNotification n) async {
 try {
  _loading = true;
  _error = null;
  notificationDetail = null;
  notifyListeners();

  notificationDetail = await _repo.getNotificationDetailByItem(_uid, n);
 } catch (e) {
  notificationDetail = null;
  _error = e.toString();
 } finally {
  _loading = false;
  notifyListeners();
 }
}
```

```dart
if (detail == null) {
 return Scaffold(
  appBar: AppBar(title: Text(l10n.notificationDetailTitle)),
  body: Center(
   child: Text(vm.error ?? l10n.notificationsDefaultBody),
  ),
 );
}
```

---

### 5. Log notification/email/chat đang in PII và payload nhạy cảm qua muc can thiet

- File: `lib/services/notifications/notification_service.dart:101-103`
- File: `lib/services/notifications/notification_service.dart:663-666`
- File: `functions/src/functions/notifications/sendLocalizedNotification.ts:102-115`
- File: `functions/src/functions/send_email.ts:40-41`
- File: `functions/src/functions/send_email.ts:61-63`
- Loại lỗi: `Security`, `Privacy`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Client log toan bo `data`, title, body khi tap push và khi tao family chat notification.
- Backend log `payloadData`, `rawMessage`, `safeBody`, email dich danh `to=${to}`.
- Day la luong ch?a PII và noi dung giao tiep nhạy cảm. Trong production, nh?ng log nay ?? l? noi dung chat, ten trẻ em, email reset password và cac payload notification.

Đoạn code lỗi:

```dart
debugPrint(
 'handleTap type=$rawType normalizedType=$type notificationId=$notificationId familyId=$familyId messageId=$messageId eventId=$eventId route=$route',
);
...
debugPrint(
 '[NotificationService] creating notification '
 'receiverId=$uid title="$senderName" body="$messageText" data=$payload',
);
```

```ts
console.log("[sendLocalizedNotification] payload", {
 uid: opts.uid,
 ...
 rawMessage: opts.data?.message,
 payloadData: payload.data,
});
console.log(`[MAIL] Triggered id=${mailId} to=${to} type=${type}`);
```

Đoạn code đề xuất sửa lỗi:

```dart
if (kDebugMode) {
 debugPrint(
  'handleTap type=$type notificationId=$notificationId route=$route',
 );
}
```

```ts
console.log("[sendLocalizedNotification]", {
 uid: opts.uid,
 type: opts.type,
 eventKey: normalizedEventKey,
 tokenCount: tokens.length,
});

console.log(
 `[MAIL] Triggered id=${mailId} type=${type} domain=${to.split("@").pop()}`
);
```

---

### 6. Scheduler birthday/memory-day đang N+1 query rat nang, kho scale khi so family/member tang

- File: `functions/src/functions/birthday_notifications.ts:247-277`
- File: `functions/src/functions/birthday_notifications.ts:305-365`
- File: `functions/src/functions/memory_day_reminders.ts:188-248`
- File: `functions/src/functions/memory_day_reminders.ts:208-276`
- Loại lỗi: `Performance`, `Scalability`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `birthday_notifications` moi gio query tat ca `families`, roi moi family lai query `members`, roi moi receiver lai query `users/{receiverId}` và `notifications/{notificationId}`.
- `memory_day_reminders` cung lap lai pattern tuong tu: `collectionGroup(memoryReminderMeta)` -> per family load members -> per receiver load locale -> per receiver read existing notification.
- Day la nested read pattern rat dat và se cham ro ret khi dữ liệu tang.

Đoạn code lỗi:

```ts
const familiesSnap = await db.collection("families").get();
for (const familyDoc of familiesSnap.docs) {
 const membersSnap = await db.collection(`families/${familyDoc.id}/members`).get();
 ...
 const existing = await notificationRef.get();
 ...
 const userSnap = await db.doc(`users/${receiverId}`).get();
}
```

Đoạn code đề xuất sửa lỗi:

```ts
const localeByUid = await loadUserLocales(receiverIds); // chunked batch load

for (const receiverId of receiverIds) {
 const notificationRef = db.collection("notifications").doc(notificationId);
 const locale = localeByUid.get(receiverId) ?? "vi";

 await notificationRef.create({
  ...buildNotificationPayload(receiverId, locale),
  status: "pending",
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
 }).catch((error) => {
  if (!isAlreadyExistsError(error)) throw error;
 });
}
```

---

## Tóm tắt rủi ro Phase 5

Nhung ?u ti?n can xu ly tr??c khi sang phase tiep theo:

1. Unregister FCM installation tr??c khi logout de tranh lo push cua tài khoản cu.
2. B? sung lease/idempotency cho `onNotificationCreated` và `onMailQueueCreated`.
3. Sua `NotificationDetailScreen` de hi?n thi loi thay vi loading vo han.
4. Giam bot log PII trong notification/chat/email pipeline.
5. Toi uu scheduler birthday và memory ??y de tranh nested read hotspot.
