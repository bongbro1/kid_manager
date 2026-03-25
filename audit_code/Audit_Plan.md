# Comprehensive Audit Execution Plan

Ngày lập kế hoạch: 2026-03-24

## 1. Mục tiêu

Tài liệu này chia đợt audit toàn diện thành các phase logic để review có hệ thống, bám đúng cấu trúc thực tế của project và tránh bỏ sót các vùng rủi ro cao.

Phạm vi kiến trúc nhận diện nhanh từ đợt scan:

- Mobile app chính là Flutter/Dart.
- Backend phụ trợ là Firebase Cloud Functions viết bằng TypeScript.
- Hạ tầng dữ liệu dùng Firebase Auth, Firestore, Realtime Database, Storage, Messaging, App Check.
- App có native Android code cho accessibility, usage sync, background/runtime hooks.
- Luồng bootstrap chính hiện đi qua `lib/main.dart` -> `lib/app.dart` -> `lib/features/sessionguard/session_guard.dart` -> `lib/widgets/app/app_shell.dart`.
- App chia mode theo role `parent`, `guardian`, `child`.
- Các domain lớn đang thấy rõ: auth, session, permissions, location tracking, safe route, SOS, notifications, chat, schedule, app management, memory day, zones.

## 2. Phạm vi và loại trừ

Các thư mục/file sẽ bỏ qua mặc định trong audit plan này:

- `build/`
- `.dart_tool/`
- `.git/`
- `.idea/`
- `.vscode/`
- `.tmp/`
- `node_modules/`
- `functions/node_modules/`
- output/generated artifacts của third-party nếu không ảnh hưởng trực tiếp tới logic nội bộ

Các vùng vẫn có thể đọc khi cần đối chiếu hành vi runtime:

- file generated nội bộ như `lib/firebase_options.dart`, `lib/l10n/app_localizations*.dart`
- lock/config files như `pubspec.lock`, `package-lock.json`, `firebase.json`

## 3. Nguyên tắc audit

Mỗi phase sẽ đánh giá theo 4 trục:

- Bugs: lỗi logic, race condition, null-safety, state bug, sai luồng runtime.
- Security: auth bypass, authorization gaps, secret leakage, insecure storage, unsafe defaults, privacy risk.
- Code Smells: coupling cao, side effects khó kiểm soát, duplication, hardcoded rules, thiếu ownership rõ ràng.
- Performance: rebuild thừa, query kém hiệu quả, excessive listeners, background drain, startup cost, network/write amplification.

Severity ưu tiên khi báo cáo sau này:

- Critical
- High
- Medium
- Low

## 4. Bản đồ module đã nhận diện

Root/config:

- `pubspec.yaml`
- `package.json`
- `functions/package.json`
- `firebase.json`
- `analysis_options.yaml`
- `firestore.rules`
- `storage.rules`
- `database.rules.json`
- `android/build.gradle.kts`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`

Flutter app:

- Bootstrap/composition: `lib/main.dart`, `lib/app.dart`
- Session/routing shell: `lib/features/sessionguard/`, `lib/widgets/app/`
- Core/shared: `lib/core/`, `lib/helpers/`, `lib/utils/`, `lib/background/`
- Data/business: `lib/repositories/`, `lib/services/`, `lib/models/`, `lib/viewmodels/`
- Feature modules: `lib/features/`
- UI: `lib/views/`, `lib/widgets/`

Backend/functions:

- Entry/config: `functions/src/index.ts`, `functions/src/config.ts`, `functions/src/bootstrap.ts`
- Service layer: `functions/src/services/`
- Trigger/callable layer: `functions/src/functions/`, `functions/src/triggers/`
- Shared helpers/types/i18n: `functions/src/helpers.ts`, `functions/src/types.ts`, `functions/src/i18n/`, `functions/src/utils/`

Testing hiện có:

- `test/services/access_control_service_test.dart`
- `test/models/user_serialization_test.dart`
- `test/features/safe_route/presentation/widgets/child_safe_route_hud_test.dart`
- `test/features/safe_route/presentation/viewmodels/child_safe_route_view_model_test.dart`

## 5. Audit Phases

### Phase 1. Kiến trúc tổng thể, bootstrap, cấu hình và dependencies

Mục tiêu:

- Hiểu composition root, dependency graph, session/routing flow, build/runtime setup, secret/config handling và bề mặt tấn công cấp hệ thống.

Thư mục/file trọng tâm:

- `pubspec.yaml`
- `package.json`
- `functions/package.json`
- `firebase.json`
- `analysis_options.yaml`
- `README.md`
- `lib/main.dart`
- `lib/app.dart`
- `lib/features/sessionguard/session_guard.dart`
- `lib/widgets/app/`
- `android/build.gradle.kts`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`

Sẽ kiểm tra:

- Bugs: bootstrap order, duplicated initialization, unsafe lifecycle calls, routing/session inconsistencies, provider graph sai scope.
- Security: secrets/env loading, debug provider/config rò rỉ sang production, release signing/build defaults, quyền native khai báo quá rộng.
- Code Smells: composition root quá nặng, dependency wiring phân tán, role flow khó truy vết, config trùng lặp giữa mobile và backend.
- Performance: cold-start cost, init đồng bộ nặng ở `main`, eager provider creation, startup I/O hoặc network không cần thiết.

Kết quả mong đợi của phase:

- Sơ đồ luồng runtime chính.
- Danh sách dependency/config có rủi ro cao.
- Ưu tiên audit sâu cho các vùng downstream.

### Phase 2. Authentication, Authorization và Security Core

Mục tiêu:

- Kiểm tra toàn bộ cơ chế xác thực, phân quyền theo role, session persistence và enforcement giữa client, rules và backend.

Thư mục/file trọng tâm:

- `lib/views/auth/`
- `lib/viewmodels/auth_vm.dart`
- `lib/viewmodels/session/`
- `lib/repositories/auth_repository.dart`
- `lib/repositories/user/`
- `lib/repositories/user_repository.dart`
- `lib/services/firebase_auth_service.dart`
- `lib/services/secondary_auth_service.dart`
- `lib/services/access_control/`
- `lib/services/storage_service.dart`
- `lib/core/storage_keys.dart`
- `lib/models/user/`
- `firestore.rules`
- `storage.rules`
- `database.rules.json`
- `functions/src/functions/user_auth.ts`
- `functions/src/services/user.ts`
- `functions/src/services/locationAccess.ts`
- `test/services/access_control_service_test.dart`
- `test/models/user_serialization_test.dart`

Sẽ kiểm tra:

- Bugs: login/logout/session rehydration sai, role resolution sai, guardian/parent ownership sai namespace, stale storage dẫn tới wrong privileges.
- Security: privilege escalation, broken access control, mass assignment, insecure token/session storage, excessive read rules, writable public collections.
- Code Smells: role strings rải rác, client-side authorization thay cho server/rules, duplicated policy logic, thiếu invariant cho user profile.
- Performance: auth bootstrap lặp, profile fetch thừa, redundant listeners/watchers theo session.

Kết quả mong đợi của phase:

- Ma trận quyền thực tế giữa `parent`, `guardian`, `child`.
- Danh sách mismatch giữa UI gating, service checks, Firestore/RTDB/Storage rules và Cloud Functions.

### Phase 3. Data Access, Models, Repository Layer và schema consistency

Mục tiêu:

- Đánh giá tính đúng đắn của model mapping, repository contracts, ownership boundaries và chiến lược truy cập Firestore/RTDB/Storage.

Thư mục/file trọng tâm:

- `lib/models/`
- `lib/repositories/`
- `lib/features/safe_route/data/`
- `lib/features/safe_route/domain/`
- `lib/services/location/`
- `lib/services/chat/`
- `lib/services/crypto/`
- `functions/src/services/`
- `functions/src/types.ts`
- `firestore.indexes.json`
- `database.rules.json`
- `storage.rules`

Sẽ kiểm tra:

- Bugs: serialization/deserialization lỗi, null handling kém, query trả sai ownership, path/document mismatch, cập nhật partial ghi đè dữ liệu.
- Security: model chứa field nhạy cảm nhưng không được che chắn, repository đọc/ghi ngoài quyền được phép, file upload paths lộ dữ liệu.
- Code Smells: repository làm quá nhiều việc, business rules đặt sai layer, schema không nhất quán giữa client và functions, magic strings/path literals.
- Performance: N+1 queries, thiếu pagination/chunking, read amplification, ghi lặp, index usage kém, cache không ổn định.

Kết quả mong đợi của phase:

- Bản đồ schema thực tế.
- Danh sách repository/model có nguy cơ gây bug dây chuyền hoặc regressions diện rộng.

### Phase 4. Core business logic cho Location Tracking, Safe Route, Zones và SOS

Mục tiêu:

- Review sâu các luồng nhạy cảm nhất về logic, an toàn và dữ liệu thời gian thực.

Thư mục/file trọng tâm:

- `lib/features/safe_route/`
- `lib/viewmodels/location/`
- `lib/views/location/`
- `lib/views/child/`
- `lib/views/parent/location/`
- `lib/views/parent/zones/`
- `lib/widgets/location/`
- `lib/widgets/sos/`
- `lib/services/location/`
- `lib/services/notifications/sos_*`
- `lib/background/`
- `functions/src/triggers/safeRoute.ts`
- `functions/src/functions/sos.ts`
- `functions/src/functions/locations.ts`
- `functions/src/functions/zones.ts`
- `functions/src/functions/zoneEvents.ts`
- `functions/src/functions/tracking/`
- `functions/src/functions/detect_offline_child.ts`
- `functions/src/services/safeRoute*`
- `functions/src/services/child.ts`
- `functions/src/services/locationAccess.ts`

Sẽ kiểm tra:

- Bugs: shared state sai scope, race condition khi stream/location update, lịch sử và live state bị trộn, retry/idempotency sai, alert resolution không đáng tin.
- Security: location privacy leaks, guardian access vượt phạm vi, abuse qua SOS/spam trigger, callable functions kiểm tra actor không chặt.
- Code Smells: state ownership mơ hồ giữa VM/screen/service, logic geo phân tán, TODOs trong emergency flow, duplicated role checks.
- Performance: GPS update gây rebuild diện rộng, polling/scheduler quá dày, background sync hao pin, Firestore/RTDB writes quá thường xuyên.

Kết quả mong đợi của phase:

- Danh sách rủi ro cao cho các tính năng safety-critical.
- Mapping đầy đủ client flow <-> backend trigger/callable <-> data stores.

### Phase 5. Notifications, Chat, Email và Communication Flows

Mục tiêu:

- Kiểm tra integrity của push flow, inbox state, unread state, family chat, notification routing và các giao tiếp bất đồng bộ với người dùng.

Thư mục/file trọng tâm:

- `lib/services/notifications/`
- `lib/repositories/chat/`
- `lib/viewmodels/notification_vm.dart`
- `lib/views/notifications/`
- `lib/views/chat/`
- `lib/widgets/notifications/`
- `lib/widgets/app/` liên quan navigator/notifiers
- `functions/src/functions/notifications.ts`
- `functions/src/functions/tokens.ts`
- `functions/src/functions/family_chat.ts`
- `functions/src/functions/family_chat_read.ts`
- `functions/src/functions/send_email.ts`
- `functions/src/functions/birthday_notifications.ts`
- `functions/src/functions/memory_day_reminders.ts`
- `functions/src/services/fcmInstallations.ts`
- `functions/src/services/sosPush.ts`
- `functions/src/i18n/`

Sẽ kiểm tra:

- Bugs: deep-link/tap routing sai, duplicate initial message handling, unread counter lệch, token lifecycle không sạch, retry tạo notification trùng.
- Security: push spoofing surface, chat payload validation kém, email trigger có thể bị abuse, PII xuất hiện trong notification/body/log.
- Code Smells: nhiều router xử lý notification chồng chéo, event naming không nhất quán, side effect nằm trong UI hoặc provider updates.
- Performance: listener trùng, fan-out push/chat không tối ưu, excessive writes cho read receipts/badges.

Kết quả mong đợi của phase:

- Sơ đồ notification/chat pipeline đầu-cuối.
- Danh sách lỗi UX và security trong các flow giao tiếp quan trọng.

### Phase 6. UI, Presentation Layer, State Management và UX correctness

Mục tiêu:

- Đánh giá chất lượng tầng hiển thị, cách tổ chức state ở VM/widgets/views và các lỗi hành vi người dùng có thể gặp trong runtime.

Thư mục/file trọng tâm:

- `lib/views/`
- `lib/widgets/`
- `lib/viewmodels/`
- `lib/features/presentation/`
- `lib/l10n/`
- `assets/` liên quan UX hoặc localization

Sẽ kiểm tra:

- Bugs: `setState`/listener/lifecycle misuse, navigation stack bugs, null UI states, stale context usage, action không có feedback hoặc đóng sai màn.
- Security: lộ dữ liệu nhạy cảm trên UI, debug info/log hiển thị production, clipboard/share/export không đủ guard.
- Code Smells: widget quá lớn, logic nghiệp vụ nằm trong screen, duplicated UI state, hardcoded strings, localization/copy inconsistency.
- Performance: rebuild quá rộng, controllers không dispose, expensive layouts/animations, image/video loading kém tối ưu.

Kết quả mong đợi của phase:

- Danh sách màn hình có debt cao nhất.
- Ưu tiên refactor presentation/state management.

### Phase 7. Native Android/iOS, device permissions và background execution

Mục tiêu:

- Audit lớp native/platform để phát hiện rủi ro về quyền hệ thống, exported components, accessibility/usage tracking, battery impact và privacy compliance.

Thư mục/file trọng tâm:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/example/kid_manager/`
- `android/app/build.gradle.kts`
- `android/build.gradle.kts`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`

Sẽ kiểm tra:

- Bugs: service/class name mismatch, native bridge lỗi lifecycle, permission flow không khớp với Flutter layer, background services không cleanup.
- Security: exported service/activity quá rộng, accessibility abuse surface, overly broad permissions, package visibility/query-all-packages risk.
- Code Smells: native logic business-heavy, config production còn TODO/defaults, Android/iOS permission text không phản ánh đúng hành vi.
- Performance: foreground/background service drain, periodic sync quá dày, unnecessary wakeups, native-to-Firebase write amplification.

Kết quả mong đợi của phase:

- Danh sách platform-specific risks có thể ảnh hưởng release/compliance.
- Ưu tiên hardening native layer và policy prompts.

### Phase 8. Cloud Functions backend, secrets, scheduler và operational resilience

Mục tiêu:

- Review backend TypeScript ở góc nhìn security, correctness, cost control, idempotency và production resilience.

Thư mục/file trọng tâm:

- `functions/src/index.ts`
- `functions/src/config.ts`
- `functions/src/bootstrap.ts`
- `functions/src/functions/`
- `functions/src/triggers/`
- `functions/src/services/`
- `functions/src/helpers.ts`
- `functions/src/utils/`
- `functions/src/i18n/`
- `functions/.eslintrc.js`
- `functions/tsconfig.json`

Sẽ kiểm tra:

- Bugs: callable validation thiếu, scheduler logic sai timezone/window, race condition trong document triggers, xử lý lỗi không nhất quán, duplicate side effects.
- Security: secret handling, auth context verification, insecure comments/config, log lộ token/uid/email, callable functions tin dữ liệu client quá mức.
- Code Smells: functions phình to, domain rules lặp giữa nhiều file, thiếu abstraction cho ownership/quota, mixed v1/v2 API patterns gây khó bảo trì.
- Performance: cold start, network calls tới external APIs, unbounded fan-out, retry storm, high Firestore read/write cost, thiếu batching.

Kết quả mong đợi của phase:

- Danh sách function/trigger có nguy cơ production incident cao nhất.
- Khuyến nghị hardening về secrets, retries, quotas, logging và observability.

### Phase 9. Performance tổng thể, test coverage gap và báo cáo hợp nhất

Mục tiêu:

- Tổng hợp toàn bộ findings, đối chiếu test coverage hiện có, gom thành roadmap fix theo mức độ nghiêm trọng và ROI.

Thư mục/file trọng tâm:

- `test/`
- các file trọng yếu bị gắn cờ từ Phase 1 đến Phase 8
- config/build files liên quan verification nếu cần

Sẽ kiểm tra:

- Bugs: vùng critical chưa có test bảo vệ, behavior dễ regression sau fix.
- Security: thiếu test cho access control, rules, callable authorization, sensitive flows.
- Code Smells: không có test strategy cho feature critical, snapshot/manual testing phụ thuộc con người quá mức.
- Performance: hotspot xuyên suốt app/backend, phase nào gây startup cost/cost leakage lớn nhất.

Kết quả mong đợi của phase:

- Báo cáo audit cuối cùng theo severity.
- Danh sách quick wins, medium refactors, structural redesigns.
- Đề xuất test plan để khóa regressions sau audit.

## 6. Thứ tự thực thi đề xuất

Thứ tự chạy audit nên là:

1. Phase 1 để dựng baseline kiến trúc và config.
2. Phase 2 để chốt trust boundaries và ma trận quyền.
3. Phase 3 để hiểu schema/repository trước khi đi sâu feature logic.
4. Phase 4 và Phase 5 cho các domain runtime có rủi ro cao nhất.
5. Phase 6 và Phase 7 để đánh giá client/native behavior và UX correctness.
6. Phase 8 để review toàn bộ backend vận hành và bảo mật phía server.
7. Phase 9 để tổng hợp, xếp hạng và đề xuất remediation roadmap.

## 7. Tiêu chí thành công của đợt audit

Đợt audit được xem là hoàn chỉnh khi:

- Có danh sách findings theo severity, có file/path cụ thể và mô tả tác động.
- Làm rõ được mismatch giữa client, backend và security rules.
- Xác định rõ các feature safety-critical cần xử lý trước.
- Có roadmap remediation khả thi theo nhóm: quick fixes, medium refactors, architectural changes.
- Có đề xuất test coverage tối thiểu cho các vùng rủi ro cao.

## 8. Ghi chú thực thi

Trong quá trình audit các phase sau, ưu tiên đặc biệt sẽ dành cho:

- `safe_route`
- `location tracking`
- `SOS`
- `session/auth/access control`
- `notifications/chat`
- native Android background/accessibility logic

Lý do:

- Đây là các vùng vừa nhạy cảm về security/privacy, vừa có rủi ro runtime và performance cao nhất trong cấu trúc hiện tại.
