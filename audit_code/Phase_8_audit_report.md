# Báo cáo Audit Phase 8

## Phase 8 - Cloud Functions backend, secrets, scheduler và operational resilience

### 1. Backend vẫn commit secret/config nhạy cảm trong comment và bỏ qua `MAIL_FROM` param, dễ lộ thông tin vận hành và gây config drift

- Tệp: `functions/src/config.ts:16-26`
- Tệp: `functions/src/index.ts:5-7`
- Tệp: `functions/src/functions/send_email.ts:42-50`
- Tệp: `functions/src/functions/send_email.ts:103-104`
- Loại lỗi: `Security`, `Operational`, `Code Smell`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- `functions/src/config.ts` và `functions/src/functions/send_email.ts` đang giữ comment mẫu secret thật sự, bao gồm cả dạng giá trị `RESEND_API_KEY`.
- `MAIL_FROM` đã được khai báo bằng `defineString()` nhưng backend email lại hardcode `Kid Manager <no-reply@homiesmart.io.vn>` trong code. Nghĩa là deploy config và code có thể lệch nhau, và bất kỳ thay đổi domain/gửi email nào đều phải sửa source.
- `index.ts` cũng để lại comment vận hành triển khai ngay trong entrypoint. Đây là pattern rất dễ dẫn đến lộ secret, config drift và thao tác deploy sai môi trường.

Đoạn code lỗi:

```ts
export const SOS_REMINDER_WORKER_URL = defineString("SOS_REMINDER_WORKER_URL");
export const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
export const MAIL_FROM = defineString("MAIL_FROM");

// RESEND_API_KEY=re_aNk2vcpx_Lst9HFZTPH7hK2m2Npj43XYa
// MAIL_FROM=Kid Manager <no-reply@homiesmart.io.vn>
```

```ts
const { error } = await resend.emails.send({
 from: "Kid Manager <no-reply@homiesmart.io.vn>",
 to: [to],
 subject: template.subject,
 html,
});
```

Đoạn code đề xuất sửa lỗi:

```ts
import { REGION, RESEND_API_KEY, MAIL_FROM } from "../config";

const from = MAIL_FROM.value().trim();
if (!from) {
 throw new Error("Missing MAIL_FROM");
}

const { error } = await resend.emails.send({
 from,
 to: [to],
 subject: template.subject,
 html,
});
```

```text
Xoa toan bo comment ch?a secret/gia tri config khoi source repo.
Chi luu huong dan set secret trong runbook/CI secret manager.
```

---

### 2. SOS reminder stack đang chia đôi config giữa `defineString()` và `process.env`, dễ gây outage khó debug khi deploy

- Tệp: `functions/src/config.ts:16-21`
- Tệp: `functions/src/services/tasks.ts:7-11`
- Tệp: `functions/src/services/tasks.ts:44-52`
- Tệp: `functions/src/functions/sos.ts:24-36`
- Tệp: `functions/src/functions/sos.ts:56-63`
- Loại lỗi: `Bug`, `Operational`, `Reliability`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `SOS_REMINDER_WORKER_URL` được khai báo bằng `defineString()` trong `config.ts`, nhưng `tasks.ts` và `sos.ts` lại đọc trực tiếp `process.env.SOS_REMINDER_WORKER_URL` và `process.env.SOS_TASK_CALLER_SA`.
- Hai cơ chế config này không đồng nhất. Khi deploy Gen 2, param và env có thể không được inject cùng cách, dẫn đến trường hợp queue worker hoạt động ở local/emulator nhưng fail ở production với lỗi `Missing SOS_REMINDER_WORKER_URL` hoặc `Worker auth misconfigured`.
- Vì các biến được resolve ở cấp module load, sai cấu hình sẽ biểu hiện thành runtime outage thay vì fail-fast có chủ ý trong deploy.

Đoạn code lỗi:

```ts
export const SOS_REMINDER_WORKER_URL = defineString("SOS_REMINDER_WORKER_URL");
```

```ts
const WORKER_URL = process.env.SOS_REMINDER_WORKER_URL || "";
const TASK_CALLER_SA = process.env.SOS_TASK_CALLER_SA || "";
```

```ts
const TASK_CALLER_SA = (process.env.SOS_TASK_CALLER_SA ?? "").trim();
const WORKER_AUDIENCE = (process.env.SOS_REMINDER_WORKER_URL ?? "").trim();
```

Đoạn code đề xuất sửa lỗi:

```ts
import { defineString } from "firebase-functions/params";

export const SOS_REMINDER_WORKER_URL = defineString("SOS_REMINDER_WORKER_URL");
export const SOS_TASK_CALLER_SA = defineString("SOS_TASK_CALLER_SA");
```

```ts
import { REGION, SOS_REMINDER_WORKER_URL, SOS_TASK_CALLER_SA } from "../config";

function getReminderWorkerConfig() {
 const workerUrl = SOS_REMINDER_WORKER_URL.value().trim();
 const callerSa = SOS_TASK_CALLER_SA.value().trim();
 if (!workerUrl || !callerSa) {
  throw new Error("Missing SOS reminder worker configuration");
 }
 return { workerUrl, callerSa };
}
```

---

### 3. `onMailQueueCreated` có `retry: true` nhưng không claim lease trước khi gửi, dễ duplicate email/OTP khi retry hoặc crash giữa chừng

- Tệp: `functions/src/functions/send_email.ts:5-10`
- Tệp: `functions/src/functions/send_email.ts:27-29`
- Tệp: `functions/src/functions/send_email.ts:40-68`
- Loại lỗi: `Bug`, `Operational`, `Security`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Trigger chỉ kiểm tra `status !== "pending"` trên snapshot đầu vào, sau đó gọi Resend ngay.
- Nếu function gửi email thành công nhưng crash/fail trước `snap.ref.update({ status: "sent" })`, Cloud Functions sẽ retry và gửi lại cùng một email/OTP.
- Không có transaction/lease/claim id để tránh hai invocation đồng thời cùng xử lý một mail doc. Ngoài ra log đang in thẳng địa chỉ email `to`, dễ lộ PII trong logging pipeline.

Đoạn code lỗi:

```ts
export const onMailQueueCreated = onDocumentCreated(
 {
  document: "mail_queue/{mailId}",
  region: REGION,
  retry: true,
  secrets: [RESEND_API_KEY],
 },
```

```ts
if (data.status && data.status !== "pending") {
 console.log(`[MAIL] already processed id=${mailId}`);
 return;
}

console.log(`[MAIL] Triggered id=${mailId} to=${to} type=${type}`);
...
await snap.ref.update({
 status: "sent",
 sentAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

Đoạn code đề xuất sửa lỗi:

```ts
const claimed = await admin.firestore().runTransaction(async (tx) => {
 const fresh = await tx.get(snap.ref);
 const freshData = fresh.data() as any;
 if (!fresh.exists || freshData?.status !== "pending") return false;

 tx.update(snap.ref, {
  status: "processing",
  processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
 });
 return true;
});

if (!claimed) return;

const { data: resendResp, error } = await resend.emails.send({
 from,
 to: [to],
 subject: template.subject,
 html,
});

await snap.ref.update({
 status: "sent",
 providerMessageId: resendResp?.id ?? null,
 sentAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

---

### 4. `onNotificationCreated` gửi push không có cơ chế idempotency/lease, retry sau khi đã gửi vẫn có thể bắn trùng notification

- Tệp: `functions/src/functions/notifications.ts:26-31`
- Tệp: `functions/src/functions/notifications.ts:45-54`
- Tệp: `functions/src/functions/notifications.ts:100-155`
- Loại lỗi: `Bug`, `Operational`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Trigger đang `retry: true`, nhưng không hề claim trạng thái `processing` trước khi gọi `sendEachForMulticast`.
- Nếu push đã gửi thành công nhưng function fail lúc delete invalid token hoặc `snap.ref.update({ status: "sent" })`, lần retry sau sẽ gửi lại toàn bộ payload.
- Code cũng không check `status === "pending"` ở đầu vào nên bất kỳ doc notification nào được create bởi hệ thống đều có nguy cơ bị gửi lặp khi worker bị retry.

Đoạn code lỗi:

```ts
export const onNotificationCreated = onDocumentCreated(
 {
  document: "notifications/{notificationId}",
  region: REGION,
  retry: true,
 },
```

```ts
const resp = await admin.messaging().sendEachForMulticast({
 tokens,
 notification: {
  title: safeTitle,
  body: safeBody,
 },
 data: {
  ...payloadData,
  receiverId: toUid,
  title: safeTitle,
  body: safeBody,
  type: String(data.type ?? "GENERIC"),
  notificationId,
  eventKey,
 },
});

await snap.ref.update({ status: "sent" });
```

Đoạn code đề xuất sửa lỗi:

```ts
const claimed = await db.runTransaction(async (tx) => {
 const fresh = await tx.get(snap.ref);
 const freshData = fresh.data() as any;
 if (!fresh.exists || (freshData?.status ?? "pending") !== "pending") return false;

 tx.update(snap.ref, {
  status: "processing",
  processingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
 });
 return true;
});

if (!claimed) return;

const resp = await admin.messaging().sendEachForMulticast(payload);

await snap.ref.update({
 status: "sent",
 sentAt: admin.firestore.FieldValue.serverTimestamp(),
 deliveryCount: resp.successCount,
});
```

---

### 5. `sendLocalizedNotification` đang log toàn bộ `payload.data`, dễ lộ message, event data và metadata người dùng vào log server

- Tệp: `functions/src/functions/notifications/sendLocalizedNotification.ts:70-115`
- Loại lỗi: `Security`, `Privacy`, `Observability`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Helper này log cả `safeTitle`, `safeBody`, `rawMessage` và `payloadData`.
- Các caller tracking/safe-route có thể truyền message mô tả trạng thái, child name, alert reason và id tham chiếu. Khi bị log đầy đủ, dữ liệu này sẽ nằm trong Cloud Logging, khó loại bỏ và không cần thiết cho observability cơ bản.
- Logging payload đầy đủ ở helper dùng chung cũng có nghĩa mọi domain sử dụng helper này đều kéo theo rủi ro PII.

Đoạn code lỗi:

```ts
console.log("[sendLocalizedNotification] payload", {
 uid: opts.uid,
 type: opts.type,
 eventKey: normalizedEventKey,
 titleKey,
 bodyKey,
 safeTitle,
 safeBody: body,
 rawDataTitle: opts.data?.title,
 rawDataBody: opts.data?.body,
 rawMessage: opts.data?.message,
 tokenCount: tokens.length,
 payloadData: payload.data,
});
```

Đoạn code đề xuất sửa lỗi:

```ts
console.log("[sendLocalizedNotification]", {
 uid: opts.uid,
 type: opts.type,
 eventKey: normalizedEventKey,
 tokenCount: tokens.length,
 hasCustomMessage: Boolean(opts.data?.message),
});
```

---

### 6. `getSuggestedSafeRoutes` gọi Mapbox không có timeout và persist luôn route suggestion vào Firestore trước khi người dùng chọn

- Tệp: `functions/src/services/safeRouteDirectionsService.ts:90-135`
- Tệp: `functions/src/services/safeRouteDirectionsService.ts:145-186`
- Tệp: `functions/src/triggers/safeRoute.ts:506-557`
- Loại lỗi: `Performance`, `Operational`, `Cost Control`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `fetchDirections()` dùng `fetch(url)` trực tiếp, không `AbortController`, không timeout, không retry policy/coalescing. Nếu Mapbox chậm hoặc treo, callable sẽ giữ instance lâu và tăng cold-start pressure.
- Sau khi nhận route, service lập tức `routeRef.set(fullRoute)` cho từng suggestion. Nghĩa là mỗi lần user bấm "gợi ý route" là backend đã ghi 1-3 document chính thức vào `routes`, kể cả khi user không bao giờ chọn route nào.
- Pattern này tạo write amplification, route rác (orphan documents), và mở đường cho cost abuse nếu caller spam lấy suggestion.

Đoạn code lỗi:

```ts
const response = await fetch(url);
if (!response.ok) {
 const body = await response.text().catch(() => "");
 ...
}
```

```ts
const routeRef = db.collection("routes").doc();
...
await routeRef.set(fullRoute, {merge: true});
builtRoutes.push(fullRoute);
```

Đoạn code đề xuất sửa lỗi:

```ts
const controller = new AbortController();
const timeout = setTimeout(() => controller.abort(), 8000);

try {
 const response = await fetch(url, { signal: controller.signal });
 ...
} finally {
 clearTimeout(timeout);
}
```

```ts
// Chi tra route suggestion ve client, ch?a persist vao `routes`
return routes
 .slice(0, routeLimit)
 .map((route, index) => buildEphemeralRouteSuggestion(route, index, params));

// Chi luu vao Firestore khi user xac nh?n route can dung.
```

---

### 7. `checkTrackingHeartbeat` đang quét toàn bộ family mỗi 2 phút và thực hiện N+1 reads theo từng child, dễ tạo hotspot chi phí và schedule pressure

- Tệp: `functions/src/functions/tracking/checkTrackingHeartbeat.ts:101-208`
- Loại lỗi: `Performance`, `Operational`, `Scalability`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Scheduler chạy `every 2 minutes`, đọc toàn bộ `families`, sau đó query `members` từng family, rồi lại read RTDB `locations/{child}/current` và Firestore `trackingStatus/{child}` cho từng trẻ.
- Độ phức tạp là `O(families + children)` mỗi 2 phút, không có shard, pagination hay index tập trung cho "children đang cần monitor".
- Khi hệ thống tăng quy mô, đây sẽ trở thành một trong những job đốt read cost lớn nhất backend và dễ chậm/chồng lên giữa các lần schedule.

Đoạn code lỗi:

```ts
const familiesSnap = await db.collection("families").get();

for (const familyDoc of familiesSnap.docs) {
 const childMembersSnap = await db
  .collection(`families/${familyId}/members`)
  .where("role", "==", "child")
  .get();

 for (const childDoc of childMembersSnap.docs) {
  const [heartbeatMs, statusSnap] = await Promise.all([
   readHeartbeatMillis(childUid),
   statusRef.get(),
  ]);
  ...
 }
}
```

Đoạn code đề xuất sửa lỗi:

```ts
// Duy tri m?t collection/index tap trung cho child dang active tracking
// vd: tracking_heartbeats/{childUid} = { familyId, lastLocationAt, statusUpdatedAt }

const staleSnap = await db
 .collection("tracking_heartbeats")
 .where("lastLocationAt", "<", nowMs - STALE_AFTER_MS)
 .limit(500)
 .get();

for (const doc of staleSnap.docs) {
 const heartbeat = doc.data();
 await updateTrackingStatusFromHeartbeat(heartbeat);
}
```

---

## Tóm tắt rủi ro Phase 8

Những điểm backend cần ưu tiên hardening sớm nhất sau Phase 8:

1. Secret/config vẫn bị để trong source comment và cấu hình SOS worker đang bị split-brain giữa param và env.
2. Email queue và notification trigger đều thiếu claim/idempotency, rất dễ gây duplicate side effects khi retry.
3. Logging backend đang lộ PII/payload ở email, notification và helper push dùng chung.
4. Safe-route backend có nguy cơ treo/cost leak do external API không timeout và route suggestion bị persist quá sớm.
5. Scheduler `checkTrackingHeartbeat` là hotspot chi phí/scalability lớn ở production.
