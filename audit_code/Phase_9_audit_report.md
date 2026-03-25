# Báo cáo Audit Phase 9

## Phase 9 - Performance tổng thể, test coverage gap và báo cáo hợp nhất

### 1. Hệ thống verification gần như chưa tồn tại: root `test` script fail mặc định, backend không có test script và repo không có CI workflow

- Tệp: `package.json:17-19`
- Tệp: `functions/package.json:3-13`
- Tệp: `functions/package.json:28-36`
- Tệp: `pubspec.yaml:97-100`
- Loại lỗi: `Code Smell`, `Process`, `Security`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- Root `package.json` đang để `npm test` fail có chủ đích bằng `echo "Error: no test specified" && exit 1`.
- `functions/package.json` có `firebase-functions-test` trong `devDependencies`, nhưng không có bất kỳ `test` script nào cho backend, rules hay emulators.
- Flutter side chỉ khai báo `flutter_test`, nhưng toàn repo không có CI workflow ở root để bắt buộc chạy test/lint trước khi merge/deploy.
- Hệ quả là toàn bộ fix của Phase 1 -> Phase 8 không có cơ chế khóa regression. Mỗi lần deploy đang phụ thuộc vào manual QA và trí nhớ của team.

Đoạn code lỗi:

```json
"scripts": {
 "test": "echo \"Error: no test specified\" && exit 1"
}
```

```json
"scripts": {
 "lint": "eslint --ext .js,.ts .",
 "build": "tsc",
 "build:watch": "tsc --watch",
 "serve": "npm run build && firebase emulators:start --only functions",
 "shell": "npm run build && firebase functions:shell",
 "start": "npm run shell",
 "deploy": "firebase deploy --only functions",
 "logs": "firebase functions:log"
},
"devDependencies": {
 "firebase-functions-test": "^3.4.1"
}
```

Đoạn code đề xuất sửa lỗi:

```json
// package.json
"scripts": {
 "test": "flutter test",
 "analyze": "flutter analyze"
}
```

```json
// functions/package.json
"scripts": {
 "lint": "eslint --ext .js,.ts .",
 "build": "tsc",
 "test": "vitest run",
 "test:emulator": "firebase emulators:exec --only firestore,database,storage \"vitest run\""
}
```

```yaml
# .github/workflows/ci.yml
name: ci
on: [push, pull_request]
jobs:
 verify:
  runs-on: ubuntu-latest
  steps:
   - uses: actions/checkout@v4
   - uses: subosito/flutter-action@v2
   - run: flutter pub get
   - run: flutter analyze
   - run: flutter test
   - run: cd functions && npm ci && npm run build && npm test
```

---

### 2. Test suite hiện tại chỉ có 4 file và tập trung vào presentation/model nhẹ, bỏ trống hoàn toàn backend, rules và native critical paths

- Tệp: `test/features/safe_route/presentation/viewmodels/child_safe_route_view_model_test.dart:15-59`
- Tệp: `test/features/safe_route/presentation/widgets/child_safe_route_hud_test.dart:10-65`
- Tệp: `test/models/user_serialization_test.dart:9-85`
- Tệp: `test/services/access_control_service_test.dart:43-305`
- Loại lỗi: `Code Smell`, `Regression Risk`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Toàn bộ `test/` hiện chỉ cover 4 vùng:
 - dispose race của `ChildSafeRouteViewModel`
 - overflow safety của `ChildSafeRouteHud`
 - serialization của `SubscriptionInfo`/`UserProfile`
 - logic `AccessControlService` thuần client
- Không có test nào cho repository, Firebase integration, callable functions, scheduler, trigger retry, rules, auth flow, FCM/email pipeline, native permission flow hay background tracking.
- Nghĩa là những vùng rủi ro cao nhất sau audit lại chính là những vùng chưa có "safety net".

Đoạn code lỗi:

```dart
group('ChildSafeRouteViewModel', () {
 test('does not notify after dispose when active trip request completes late', () async {
  ...
 });
});
```

```dart
group('SubscriptionInfo serialization', () {
 test('toMap keeps Firestore wire values', () {
  ...
 });
});
```

Đoạn code đề xuất sửa lỗi:

```text
Mo rong test matrix toi thiếu:

- test/repositories/location_repository_test.dart
- test/repositories/auth_repository_test.dart
- test/features/safe_route/domain/safe_route_policy_test.dart
- functions/test/sos.test.ts
- functions/test/notifications.test.ts
- functions/test/send_email.test.ts
- functions/test/tracking_heartbeat.test.ts
- functions/test/firestore.rules.test.ts
- functions/test/database.rules.test.ts
- functions/test/storage.rules.test.ts
```

---

### 3. Các trust boundary nguy hiểm nhất không có một regression test nào, dù đây là nơi đã phát hiện lỗ hổng Critical/High

- Tệp: `firestore.rules:105-132`
- Tệp: `database.rules.json:9-38`
- Tệp: `storage.rules:18-33`
- Tệp: `functions/src/functions/user_auth.ts:4-40`
- Tệp: `functions/src/functions/sos.ts:361-519`
- Tệp: `functions/src/functions/notifications.ts:26-155`
- Tệp: `functions/src/functions/send_email.ts:5-70`
- Loại lỗi: `Security`, `Regression Risk`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- Phase 2 và Phase 8 đã chỉ ra các lỗ hổng ở `resetUserPassword`, mail queue/notification trigger, Firestore rules và RTDB access.
- Tuy nhiên hiện không có bất kỳ test nào xác minh:
 - ai được phép reset password
 - ai được read/write location, zone events, storage chat images
 - retry trigger có gửi trùng email/push hay không
 - user/guardian có thể privilege-escalate qua rules hay không
- Đây là khoảng trống nguy hiểm nhất của toàn bộ project, vì các bug access control thường "sống sót" rất lâu nếu không bị test emulator chặn lại.

Đoạn code lỗi:

```ts
export const resetUserPassword = onCall(
 { region: REGION },
 async (request) => {
  const { uid, newPassword } = request.data;
  ...
  await admin.auth().updateUser(uid, {
   password: newPassword,
  });
```

```rules
match /users/{uid} {
 allow update: if isSelf(uid)
  || isParentManagingGuardianAssignments(uid)
  || request.resource.data.diff(resource.data)
   .changedKeys()
   .hasOnly(["isActive"]);
}
```

Đoạn code đề xuất sửa lỗi:

```ts
// functions/test/user_auth.test.ts
it("rejects password reset when caller is not admin or target owner", async () => {
 const wrapped = test.wrap(resetUserPassword);
 await expect(
  wrapped({ data: { uid: "victim", newPassword: "12345678" }, auth: { uid: "attacker" } })
 ).rejects.toMatchObject({ code: "permission-denied" });
});
```

```ts
// functions/test/firestore.rules.test.ts
it("prevents guardian from updating protected fields on users doc", async () => {
 const db = authedApp({ uid: "guardian-1" }).firestore();
 await assertFails(
  db.doc("users/child-1").set({ role: "parent", isActive: true }, { merge: true })
 );
});
```

---

### 4. Không có test nào bảo vệ các flow retry/idempotency và scheduler, trong khi đây là nguồn incident production lớn nhất ở backend

- Tệp: `functions/src/functions/notifications.ts:26-155`
- Tệp: `functions/src/functions/send_email.ts:5-70`
- Tệp: `functions/src/functions/tracking/checkTrackingHeartbeat.ts:101-208`
- Tệp: `functions/src/triggers/safeRoute.ts:779-853`
- Tệp: `functions/src/services/safeRouteDirectionsService.ts:145-186`
- Loại lỗi: `Bug`, `Performance`, `Operational`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Những finding lớn của Phase 4, 5, 8 đều liên quan đến side effect lặp:
 - duplicate push/email khi retry
 - scheduler quét quá rộng
 - safe-route tạo route/trip duplicate
 - external API call không được cảnh báo timeout/idempotency
- Hiện không có test nào mô phỏng retry lần 2, crash giữa chừng, hay scheduler chạy lặp trên dữ liệu cũ.
- Khi sửa các issue này, nếu không viết test theo kiểu "run twice should still send once", team rất dễ làm đổ fix trong lần refactor sau.

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
export const activateScheduledSafeRouteTrips = onSchedule(
 {
  region: REGION,
  schedule: SAFE_ROUTE_SCHEDULE,
  timeZone: TZ,
 },
 async () => {
  ...
 }
);
```

Đoạn code đề xuất sửa lỗi:

```ts
describe("onNotificationCreated idempotency", () => {
 it("sends at most once when retried", async () => {
  const repo = fakeNotificationRepo({ status: "pending" });
  await processPendingNotification(repo, "notification-1");
  await processPendingNotification(repo, "notification-1");
  expect(repo.sendCount).toBe(1);
 });
});
```

```ts
describe("activateScheduledSafeRouteTrips", () => {
 it("does not create duplicate active trips for the same child on repeated scheduler runs", async () => {
  const repo = fakeTripRepo.withPlannedTrip("trip-template-1");
  await activateDueTrips(repo, fixedNow);
  await activateDueTrips(repo, fixedNow);
  expect(repo.activeTripsForChild("child-1")).toHaveLength(1);
 });
});
```

---

### 5. Verification thực tế cũng chưa ổn định: bộ test Flutter hiện tại không xác nhận được trạng thái xanh trong môi trường audit

- Tệp: `package.json:17-19`
- Tệp: `pubspec.yaml:97-100`
- Loại lỗi: `Process`, `Maintainability`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Trong quá trình audit, `flutter test` trên workspace này bị timeout lặp lại, trong khi root `package.json` lại không có script verification hợp lệ.
- Điều này cho thấy quy trình chạy test chưa được sẵn sàng như một "one-command verification path" để team hoặc CI có thể lặp lại ổn định.
- Không có dữ liệu cho thấy suite hiện tại thật sự xanh và reproducible.

Đoạn code lỗi:

```json
"scripts": {
 "test": "echo \"Error: no test specified\" && exit 1"
}
```

Đoạn code đề xuất sửa lỗi:

```json
"scripts": {
 "test": "flutter test --reporter compact",
 "test:unit": "flutter test test/models test/services test/features",
 "verify": "flutter analyze && flutter test --reporter compact"
}
```

---

## Severity tổng hợp sau 9 phase

### Critical

1. `functions/src/config.ts` và `functions/src/functions/send_email.ts` dễ lộ secret/config trong source comment.
2. `functions/src/functions/user_auth.ts` cho phép reset password tùy ý nếu callable bị gọi trực tiếp.
3. `firestore.rules` và các queue collection/rules trust boundary có khả năng privilege escalation / public abuse.
4. Toàn bộ trust boundary trên chưa có emulator test hay regression test khóa lại.

### High

1. `functions/src/functions/notifications.ts` và `functions/src/functions/send_email.ts` thiếu idempotency khi retry.
2. `android/app/src/main/AndroidManifest.xml` + accessibility stack xin quyền quá rộng và poll quá dày.
3. `functions/src/functions/tracking/checkTrackingHeartbeat.ts` và các scheduler safe-route có nguy cơ cost/scalability incident.
4. Safe-route/location pipeline có mirror data và duplicate activation risk.
5. Logout/push/native cache/logging đang dễ lộ PII và state cũ trên thiết bị.

### Medium

1. Nhiều screen UI đang có side effect trong `build()`, lifecycle controller chưa sạch.
2. Các native/client log và string hardcode/localization debt làm giảm độ ổn định và release quality.
3. Test suite hiện tại quá mỏng, chưa có một lệnh verification đơn giản và ổn định.

## Roadmap remediation đề xuất

### Quick wins (1-3 ngày)

1. Xóa ngay secret/comment nhạy cảm khỏi repo; chuyển `MAIL_FROM`, `SOS_REMINDER_WORKER_URL`, `SOS_TASK_CALLER_SA` về một cơ chế config thống nhất.
2. Đóng public access ở `email_otps`, `mail_queue`, harden `resetUserPassword`, và sửa rules `/users` + guardian assignment.
3. Bổ sung claim `processing`/lease cho email và notification trigger.
4. Tắt log payload/PII ở native + backend.
5. Thêm script `verify`, `flutter test`, backend test runner và CI workflow tối thiểu.

### Medium refactors (1-2 tuần)

1. Tách business logic khỏi Cloud Functions trigger/callable thành pure services để dễ unit test.
2. Viết emulator tests cho `firestore.rules`, `database.rules.json`, `storage.rules`.
3. Viết regression tests cho `sos`, `notifications`, `send_email`, `locations`, `safe_route`.
4. Giảm polling native accessibility/background và đưa các sync sang scheduler/work manager có backpressure.

### Structural redesigns (2-6 tuần)

1. Hợp nhất trust model giữa client, Cloud Functions, Firestore rules, RTDB rules và native watcher.
2. Thiết kế lại notification/email/scheduler pipeline theo hướng idempotent-by-design.
3. Thay các job quét toàn hệ thống bằng index/heartbeat collection tập trung để giảm read cost.
4. Xây test strategy chính thức theo 4 lớp: unit, emulator rules, backend integration, widget/regression.

## Test plan tối thiểu sau audit

1. Rules tests:
  - Firestore: `/users`, `/families/*`, `notifications`, `mail_queue`
  - RTDB: `locations`, `live_locations`, `zoneEventsByChild`
  - Storage: `families/{familyId}/chat/{uid}/{fileName}`
2. Backend callable/trigger tests:
  - `resetUserPassword`
  - `createSos`, `resolveSos`, `sosReminderWorker`
  - `onNotificationCreated`, `onMailQueueCreated`
  - `getSuggestedSafeRoutes`, `startSafeRouteTrip`, `activateScheduledSafeRouteTrips`
  - `checkTrackingHeartbeat`
3. Flutter tests:
  - auth/session guards
  - notification detail/loading failure
  - logout unregister FCM token
  - permission onboarding / native watcher bridge
  - safe-route tracking state transitions
4. Native/backend resilience tests:
  - duplicate retry should still send once
  - scheduler rerun should not duplicate trip/alert
  - stale location / offline app detection should not false-positive
