# Executive Summary Audit Dự Án

## 1. Tình trạng sức khỏe dự án

### Đánh giá nhanh

- Audit Phase 1 đến Phase 8 ghi nhận **61 findings** gồm **7 Critical**, **35 High** và **19 Medium**.
- Nhóm rủi ro lớn nhất hiện tại nằm ở **Security/Authorization**, **Auth/OTP**, **Safe Route/SOS/Location Tracking**, **notification/email retry**, và **cấu hình native/backend production**.
- Dự án đang có đủ dấu hiệu của một hệ thống **chạy được nhưng chưa an toàn để scale hoặc phát hành production ổn định** nếu chưa khóa các trust boundary quan trọng.

### Việc cần mở IDE lên làm đầu tiên

1. Xóa và rotate toàn bộ secret/config nhạy cảm đang lộ trong source; khóa lại callable/rules có thể bị abuse trực tiếp.
2. Đóng các lỗ hổng phân quyền ở `resetUserPassword`, `/users`, `email_otps`, `mail_queue`, membership rules và các flow guardian/location/zone/SOS.
3. Bổ sung idempotency/lease cho notification, email, safe-route scheduler và alert fanout để tránh gửi trùng hoặc tạo dữ liệu trùng.
4. Ổn định pipeline core gồm Location Tracking, Safe Route, Zones và SOS để tránh false state, stale data và duplicate side effects.
5. Dọn các lỗi UI/runtime có thể gây crash hoặc treo màn hình ở notification, session bootstrap và các screen đang chạy side effect trong `build()`.

## 2. Executive Summary & Findings

## Phase 1 - Kiến trúc tổng thể, bootstrap, cấu hình và dependencies

### Critical

- `[Critical] - android/app/build.gradle.kts:10,27,37-42 - Security/Release Config:` Bản release hiện vẫn ký bằng debug key và dùng `applicationId/namespace` mẫu `com.example`. Đây là blocker production trực tiếp vì làm suy yếu hardening, phát hành và nhận diện ứng dụng.
- `[Critical] - functions/src/config.ts:17-25 - Security:` Secret thật vẫn xuất hiện trong comment của source code backend. Nếu key còn hiệu lực thì đây là rò rỉ credential cần xử lý ngay và rotate lập tức.

### High

- `[High] - pubspec.yaml:114-123, lib/main.dart:107-110, .gitignore:20,35-39,95-97 - Security/Config/Logic:` Ứng dụng đang bundle `.env` vào client build và phụ thuộc vào file ngoài source control. Cấu hình này vừa tạo nguy cơ lộ secret trên mobile, vừa khiến build/deploy dễ vỡ theo kiểu khó tái hiện.
- `[High] - lib/main.dart:27-54,93-96,102-103 - Security/Logic:` Firebase App Check đang fail-open. Ứng dụng vẫn tiếp tục chạy dù hardening không kích hoạt thành công, làm giảm đáng kể mức bảo vệ ở production.
- `[High] - lib/features/sessionguard/session_guard.dart:77-80,136-142,286-292; lib/repositories/auth_repository.dart:26-48 - Bug/Logic:` `SessionGuard` có thể tự khóa ở `FlashScreen` nếu session fallback thiếu profile đầy đủ. Điều này làm người dùng bị kẹt ở startup cho tới khi đăng xuất/đăng nhập lại.
- `[High] - android/app/src/main/AndroidManifest.xml:4-27 - Security/Compliance/Performance:` Manifest Android đang khai báo sẵn nhiều quyền nhạy cảm ở build chung. Cách làm này làm tăng attack surface, burden compliance và rủi ro bị từ chối trên store.

### Medium

- `[Medium] - lib/app.dart:103,159-162,282-288,301-307; lib/viewmodels/locale_vm.dart:31-47; lib/views/setting_pages/app_appearance_screen.dart:65-76 - Bug/Logic/Code Smell:` State ngôn ngữ đang bị chia đôi giữa `MyApp` và `LocaleVm`. Flow đổi ngôn ngữ hiện không có source of truth rõ ràng nên dễ sinh hành vi không nhất quán.
- `[Medium] - lib/widgets/app/app_shell.dart:62-65,91-97,154-156 - Bug/Logic:` `AppShell` dùng sai navigator key cho notification tab. Back handling và reset stack có thể không tác động vào navigator thật của tab này.
- `[Medium] - ios/Runner/Info.plist:52-59 - Bug/UX/Compliance:` Permission strings trên iOS bị lỗi encoding. Prompt xin quyền sẽ làm giảm độ tin cậy sản phẩm và có thể ảnh hưởng review chất lượng disclosure.
- `[Medium] - analysis_options.yaml:10-13 - Code Smell/Quality Gate:` Chính sách lint hiện quá lỏng và đang bỏ qua một phần tín hiệu nợ kỹ thuật. Điều này làm repo khó phát hiện sớm các điểm gãy khi refactor hoặc nâng cấp framework/plugin.

## Phase 2 - Authentication, Authorization và Security Core

### Critical

- `[Critical] - functions/src/functions/user_auth.ts:4-40 - Security/Authorization:` Callable `resetUserPassword` không kiểm tra quyền hay trạng thái xác minh OTP phía server. Bất kỳ ai gọi trực tiếp function đều có thể reset mật khẩu của `uid` bất kỳ.
- `[Critical] - firestore.rules:127-131; lib/repositories/user/profile_repository.dart:69-80; lib/models/user/user_profile_patch.dart:12-17,47-65 - Security/Authorization:` Firestore rules cho phép user tự cập nhật các field nhạy cảm như `role`, `parentUid`, `managedChildIds`, `familyId`. Đây là đường privilege escalation trực tiếp từ client.
- `[Critical] - firestore.rules:127-131; lib/viewmodels/auth_vm.dart:62-65; lib/repositories/otp_repository.dart:219-220 - Security/Authorization/Logic:` Rules hiện cho phép mọi người sửa `isActive` của bất kỳ user nào mà không cần đăng nhập. Cơ chế activation account vì thế có thể bị bypass hoàn toàn.
- `[Critical] - firestore.rules:633-637; lib/repositories/otp_repository.dart:14-16,53-69,72-133; lib/viewmodels/otp_vm.dart:94-117 - Security/Authentication:` OTP flow không có bí mật thực sự vì `email_otps` public read/write, OTP chỉ 4 số và hash có thể brute-force offline. Toàn bộ chuỗi reset/verify hiện không đủ an toàn để tin cậy.

### High

- `[High] - firestore.rules:644-645; lib/repositories/otp_repository.dart:223-236 - Security/Abuse:` `mail_queue` đang public create. Client có thể spam mail job, giả mạo yêu cầu gửi email và đốt quota hệ thống.
- `[High] - lib/viewmodels/auth_vm.dart:106-123; lib/repositories/user/profile_repository.dart:91-103; firestore.rules:115 - Security/Privacy:` Flow quên mật khẩu cho phép user enumeration quá dễ. Client có thể dò email tồn tại trong hệ thống qua query và thông báo lỗi phân biệt.
- `[High] - functions/src/services/locationAccess.ts:108-116,147-172; functions/src/functions/locations.ts:45-53; lib/services/access_control/access_control_service.dart:73-92 - Security/Authorization Drift:` Backend cho guardian xem location của mọi child cùng family thay vì chỉ child được assign. Policy giữa client và backend đang lệch nhau theo hướng mở rộng quyền.
- `[High] - database.rules.json:9-30; functions/src/services/locationAccess.ts:108-116; lib/services/access_control/access_control_service.dart:73-92 - Logic/Authorization Drift:` RTDB rules không hỗ trợ guardian trong khi client và backend lại coi guardian là viewer hợp lệ. Hệ thống authorization đang bị chia làm ba mô hình khác nhau.
- `[High] - lib/viewmodels/auth_vm.dart:46-72,272-299,368-392; lib/repositories/user/family_repository.dart:70-90 - Security/Logic:` Social login đang bypass gate `isActive`. Điều này làm verify email không còn là enforcement thực ở cấp hệ thống.
- `[High] - firestore.rules:171-181 - Security/Authorization:` Rules của `families/{familyId}/members` đang mở quá rộng cho signed-in user create/update. Người dùng đăng nhập có thể chèn hoặc sửa membership metadata trái phép nếu biết path.
- `[High] - storage.rules:18-24 - Security/Privacy:` Storage rules hiện cho mọi user đã đăng nhập đọc user media của người khác. Đây là lỗ hổng privacy nghiêm trọng với dữ liệu gia đình và trẻ em.

## Phase 3 - Data Access, Database Models và Repository Layer

### High

- `[High] - lib/repositories/user/membership_repository.dart:34-101,120-181; lib/models/app_user.dart:180-194 - Security/Logic/Performance:` `watchTrackableLocationMembers` vừa N+1 query vừa tự “chữa” dữ liệu thiếu bằng default nhạy cảm như `allowTracking=true`. Việc này có thể làm sai danh sách child được phép theo dõi.
- `[High] - lib/features/safe_route/data/datasources/safe_route_remote_data_source.dart:79-155; lib/repositories/location/location_repository_impl.dart:158-208,379-380; functions/src/triggers/safeRoute.ts:856-877 - Logic/Performance/Reliability:` Safe-route live stream đang phụ thuộc vào path mirror `live_locations/*` thay vì source canonical `locations/*/current`. Hệ thống vì thế dễ bị stale state nếu trigger mirror chậm hoặc lỗi.
- `[High] - lib/repositories/chat/family_chat_repository.dart:56-73; lib/services/chat/chat_media_service.dart:104-120; functions/src/functions/family_chat.ts:169-181,217-259; firestore.rules:232-242 - Security/Data Integrity:` Family chat image message chỉ kiểm tra `imageUrl` không rỗng mà không verify object/path thuộc đúng family và sender. Điều này mở ra rủi ro integrity, phishing và link tới object không hợp lệ.
- `[High] - lib/core/zones/zone_monitor.dart:97-105,116-124; lib/repositories/zones/zone_repository.dart:154-163; database.rules.json:27-31; functions/src/functions/zoneEvents.ts:51-89 - Security/Logic/Data Integrity:` Zone events hiện do client ghi trực tiếp lên RTDB và backend tin payload đó để bắn thông báo, cập nhật presence và thống kê. Một client bị compromise có thể forge event giả hoặc replay event để làm sai dữ liệu hệ thống.

### Medium

- `[Medium] - lib/repositories/user/family_repository.dart:120-157 - Performance/Scalability:` `watchFamilyMembers` tái hiện N+1 query cho mỗi lần snapshot thay đổi. Cách đọc này làm tăng read cost Firestore và kéo chậm UI khi số thành viên tăng.
- `[Medium] - lib/features/safe_route/data/models/safe_route_model.dart:53-54; lib/features/safe_route/data/models/trip_model.dart:42-49 - Bug/Logic/Data Integrity:` Safe-route models đang fabricate timestamp bằng `DateTime.now()` khi dữ liệu thiếu hoặc malformed. Điều này làm sai lịch sử, ordering và cả logic scheduler.
- `[Medium] - functions/src/functions/locations.ts:145-165; functions/src/services/locationAccess.ts:127-172 - Performance/Scalability:` `getFamilyChildrenCurrent` dùng backend N+1 RTDB reads cho mỗi lần refresh danh sách. Đây là hotspot đọc chéo Firestore/RTDB không tối ưu cho family có nhiều child.

## Phase 4 - Core Business Logic cho Location Tracking, Safe Route, Zones và SOS

### High

- `[High] - functions/src/functions/sos.ts:485-515 - Security/Logic:` `resolveSos` chỉ kiểm tra family membership mà không kiểm tra role. Một `child` có thể tự đóng incident trước khi phụ huynh xác minh.
- `[High] - functions/src/functions/zones.ts:15-20,65-77,82-90; functions/src/services/locationAccess.ts:44-125; functions/src/services/child.ts:101-113 - Security/Authorization:` Mutation zone đang dùng quyền `view` thay vì `manage`. Guardian có quyền xem location vì thế có thể tạo/xóa zone và còn có thể backdate dữ liệu từ client.
- `[High] - lib/viewmodels/location/child_location_view_model.dart:243-305,629-635; functions/src/functions/tracking/checkTrackingHeartbeat.ts:143-165 - Logic/Safety:` Tracking heartbeat có thể báo `ok` dù location không upload thành công. Backend vì thế có thể bỏ qua trạng thái stale location dù dữ liệu vị trí đã ngừng cập nhật.
- `[High] - functions/src/triggers/safeRoute.ts:787-848 - Logic/Reliability:` Scheduler kích hoạt safe-route trip không có claim/idempotency ổn định. Invocation trùng hoặc overlap có thể tạo duplicate active trip cho cùng child.
- `[High] - functions/src/triggers/safeRoute.ts:999-1151 - Bug/Logic:` Safe-route alert push đang update cooldown sau khi fanout. Hai event đến sát nhau có thể cùng gửi notification giống nhau trước khi trạng thái được ghi lại.

### Medium

- `[Medium] - lib/viewmodels/location/parent_location_vm.dart:140-185 - Bug/Logic:` `stopWatchingChild` không cập nhật `_watchingIds`, làm `syncWatching` bỏ qua subscribe lại. Kết quả là location subscription có thể mất mà UI vẫn nghĩ đang theo dõi bình thường.
- `[Medium] - lib/viewmodels/zones/parent_zones_vm.dart:76-92 - Logic/Security:` `ParentZonesVm.bind` chỉ cancel stream cũ sau khi check quyền thành công. Khi bind sang child không hợp lệ, dữ liệu cũ có thể tiếp tục hiển thị trong context mới.

## Phase 5 - Notifications, Chat, Email và Communication Flows

### High

- `[High] - lib/viewmodels/auth_vm.dart:201-204; lib/services/notifications/fcm_push_receiver_service.dart:36-38; functions/src/functions/tokens.ts:64-92 - Security/Privacy:` Logout hiện không unregister FCM token. Thiết bị đã đăng xuất vẫn có thể nhận push của tài khoản cũ.
- `[High] - functions/src/functions/notifications.ts:26-31,100-155 - Bug/Reliability:` `onNotificationCreated` bật `retry: true` nhưng không có idempotency claim trước khi gửi. Khi function crash sau khi FCM thành công, hệ thống có thể gửi trùng push.
- `[High] - functions/src/functions/send_email.ts:5-10,27-31,42-68 - Bug/Security:` `onMailQueueCreated` cũng có race tương tự và có thể gửi trùng OTP/reset email. Đây là rủi ro trực tiếp cho flow xác thực và khôi phục tài khoản.

### Medium

- `[Medium] - lib/viewmodels/notification_vm.dart:241-254; lib/views/notifications/notification_detail_screen.dart:273-294 - Bug/UX:` `NotificationDetailScreen` có thể treo loading vô hạn khi load detail thất bại. Người dùng không nhận được thông báo lỗi hay đường lui rõ ràng.
- `[Medium] - lib/services/notifications/notification_service.dart:101-103,663-666; functions/src/functions/notifications/sendLocalizedNotification.ts:102-115; functions/src/functions/send_email.ts:40-41,61-63 - Security/Privacy:` Logging hiện đang in quá nhiều PII và payload nhạy cảm của notification, email và chat. Dữ liệu này không nên tồn tại ở production logs với mức chi tiết như hiện tại.
- `[Medium] - functions/src/functions/birthday_notifications.ts:247-365; functions/src/functions/memory_day_reminders.ts:188-276 - Performance/Scalability:` Birthday và memory-day schedulers đang dùng nested/N+1 reads khá nặng. Khi số family và member tăng, cost và latency sẽ tăng rất nhanh.

## Phase 6 - UI, Presentation Layer, State Management và UX Correctness

### High

- `[High] - lib/views/child/schedule/child_schedule_screen.dart:94-164,193-203 - Bug/Performance/State Management:` `ChildScheduleScreen` đang bootstrap session từ `build()`. Mẫu này dễ tạo post-frame work lặp vô hạn và reload thừa mỗi lần rebuild.
- `[High] - lib/views/chat/family_group_chat_screen.dart:114-156,298-301 - Bug/Code Smell/State Management:` `FamilyGroupChatScreen` chạy side effect ngay trong `build()`. Việc bind/clear chat state có thể lặp lại theo mọi rebuild và sinh race/flicker/network work không cần thiết.
- `[High] - lib/views/notifications/notification_screen.dart:205-220; lib/models/notifications/app_notification.dart:342-346 - Bug/Runtime Crash:` `NotificationScreen` force unwrap `createdAt`. Chỉ cần một document mới chưa resolve server timestamp là màn hình có thể crash khi render.

### Medium

- `[Medium] - lib/views/parent/dashboard/statistics_tab.dart:181-216 - Bug/State Management:` `StatisticsTab` không thay listener khi `widget.vm` đổi instance. Điều này có thể gây stale listener, chart không update hoặc leak callback.
- `[Medium] - lib/views/setting_pages/change_password_screen.dart:17-20,59-186 - Performance/Lifecycle:` `ChangePasswordScreen` tạo 3 `TextEditingController` nhưng không dispose. Screen mở/đóng nhiều lần sẽ tích lũy memory/lifecycle debt không cần thiết.
- `[Medium] - lib/views/auth/dialog/phone_auth_dialog.dart:35-39,182-184,208-237,253-257 - Performance/Localization/Code Smell:` `PhoneAuthDialog` tạo controller cục bộ không dispose và còn hardcode nhiều copy UI. Đây là debt về lifecycle và i18n, tuy chưa phải blocker nghiệp vụ.

## Phase 7 - Native Android/iOS, Device Permissions và Background Execution

### High

- `[High] - android/app/src/main/AndroidManifest.xml:4-27,73-85; android/app/src/main/res/values/strings.xml:5-7 - Security/Privacy/Compliance:` Android build đang khai báo toàn bộ quyền giám sát nhạy cảm ở base manifest. Điều này làm tăng attack surface và rủi ro policy cho mọi build variant.
- `[High] - android/app/src/main/res/xml/accessibility_config.xml:5-14; android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:116-176 - Security/Privacy/Code Smell:` Accessibility service đang xin quyền đọc window content vượt quá nhu cầu thực tế. Native layer hiện không tuân thủ least privilege.
- `[High] - android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:31-66,68-99; android/app/src/main/kotlin/com/example/kid_manager/UsageSyncManager.kt:60-243 - Performance/Logic:` Native watcher poll Firestore mỗi 60 giây mà không có backpressure. Điều này vừa tốn pin vừa dễ sinh sync chồng chéo trên thiết bị child.
- `[High] - ios/Runner/Info.plist:52-59; ios/Runner/AppDelegate.swift:5-11; ios/Runner.xcodeproj/project.pbxproj:1-255 - Bug/Compliance/Platform:` `Info.plist` đang lỗi encoding và chưa thấy capability cần thiết cho push/background tracking trên iOS. Nếu không hoàn thiện, tính năng native rất dễ không ổn định hoặc không đạt yêu cầu review.

### Medium

- `[Medium] - android/app/src/main/kotlin/com/example/kid_manager/UsageSyncManager.kt:245-289; android/app/build.gradle.kts:25-27 - Bug/Logic:` `syncInstalledApps` có dead branch, hardcode package name và không phản ánh đúng trạng thái đã gỡ app. Tín hiệu “child đã gỡ app” vì vậy có thể sai hoàn toàn.
- `[Medium] - android/app/src/main/kotlin/com/example/kid_manager/MainActivity.kt:148-164 - Security/Privacy:` `MainActivity` log raw notification payload và extras vào logcat. Đây là cách rò metadata/PII rất phổ biến trên mobile.
- `[Medium] - android/app/src/main/kotlin/com/example/kid_manager/MainActivity.kt:43-68; android/app/src/main/kotlin/com/example/kid_manager/FirestoreRuleSyncManager.kt:164-205; android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:196-225 - Security/Privacy:` Native layer đang lưu nhiều dữ liệu nhạy cảm và rule block dạng plaintext trong `SharedPreferences`. Trên thiết bị root/debuggable hoặc backup sai cấu hình, đây là một điểm rò dữ liệu rõ rệt.

## Phase 8 - Cloud Functions backend, secrets, scheduler và operational resilience

### Critical

- `[Critical] - functions/src/config.ts:16-26; functions/src/index.ts:5-7; functions/src/functions/send_email.ts:42-50,103-104 - Security/Operational/Code Smell:` Backend vẫn commit secret/config nhạy cảm trong comment và còn bỏ qua `MAIL_FROM` param đã khai báo. Đây là rủi ro trực tiếp về lộ thông tin vận hành, config drift và deploy sai môi trường.

### High

- `[High] - functions/src/config.ts:16-21; functions/src/services/tasks.ts:7-11,44-52; functions/src/functions/sos.ts:24-36,56-63 - Bug/Operational/Reliability:` SOS reminder stack đang chia đôi cấu hình giữa `defineString()` và `process.env`. Sai lệch cấu hình kiểu này rất dễ gây outage khó debug sau deploy.
- `[High] - functions/src/functions/send_email.ts:5-10,27-29,40-68 - Bug/Operational/Security:` `onMailQueueCreated` có `retry: true` nhưng không claim lease trước khi gửi. Email/OTP có thể bị gửi trùng khi retry hoặc crash giữa chừng.
- `[High] - functions/src/functions/notifications.ts:26-31,45-54,100-155 - Bug/Operational:` `onNotificationCreated` cũng thiếu idempotency/lease. Notification có thể bị bắn trùng khi worker retry sau một lần gửi thành công nhưng chưa update status.
- `[High] - functions/src/services/safeRouteDirectionsService.ts:90-135,145-186; functions/src/triggers/safeRoute.ts:506-557 - Performance/Operational/Cost Control:` `getSuggestedSafeRoutes` gọi Mapbox không timeout và persist suggestion quá sớm vào Firestore. Flow này vừa tăng rủi ro treo instance vừa tạo write amplification/cost leak.
- `[High] - functions/src/functions/tracking/checkTrackingHeartbeat.ts:101-208 - Performance/Operational/Scalability:` `checkTrackingHeartbeat` đang quét toàn bộ family mỗi 2 phút và thực hiện N+1 reads theo từng child. Đây là một hotspot backend lớn về chi phí và khả năng scale.

### Medium

- `[Medium] - functions/src/functions/notifications/sendLocalizedNotification.ts:70-115 - Security/Privacy/Observability:` `sendLocalizedNotification` đang log toàn bộ `payload.data` và message metadata. Logging hiện tại vượt quá mức cần thiết cho observability cơ bản và làm tăng rủi ro PII trong server logs.

## 3. Remediation Roadmap

### [P0] Immediate Action - Bắt buộc fix ngay

- Xóa toàn bộ secret/config nhạy cảm khỏi source, rotate ngay các key đã lộ và chuẩn hóa cơ chế config production cho backend/email/SOS worker.
- Khóa ngay các trust boundary nguy hiểm: `resetUserPassword`, `email_otps`, `mail_queue`, `/users` update rules, `/families/*/members`, storage media read và các điểm cho phép client tự ghi dữ liệu nhạy cảm.
- Đồng bộ lại authorization cho các flow cốt lõi: guardian/location access, zone mutation, `resolveSos`, social login activation và RTDB rules cho location/guardian.
- Bổ sung idempotency/lease cho notification trigger, email trigger, safe-route trip activation và alert fanout để chặn duplicate side effects.
- Ổn định pipeline dữ liệu an toàn: dùng source canonical cho live location, ngừng tin tưởng zone events do client tự forge và tách rõ heartbeat “app sống” với “location upload khỏe”.
- Chặn các lỗi có thể gây crash hoặc làm người dùng kẹt ngay: `SessionGuard`, `NotificationScreen.createdAt!`, notification detail treo loading, logout không unregister FCM token.

### [P1] High Priority - Ưu tiên cao

- Tối ưu các điểm N+1 và nested reads trong repository, schedulers và backend location queries để giảm read cost và latency trước khi quy mô dữ liệu tăng.
- Siết manifest/quyền native, accessibility scope và polling frequency để giảm rủi ro policy, battery drain và native overlap.
- Hoàn thiện capability/background config trên iOS để bảo đảm push/location tracking hoạt động đúng trong môi trường thực tế.
- Rà soát lại toàn bộ flow Safe Route, SOS, Location Tracking, Notifications và Email theo hướng “single source of truth + retry-safe + authorization server-side”.
- Giảm log PII ở mobile/backend và chuẩn hóa logging theo nguyên tắc chỉ log metadata tối thiểu cần cho điều tra sự cố.

### [P2] Medium - Tech Debt

- Refactor các screen đang chạy side effect trong `build()` và chuẩn hóa lifecycle controller/listener để giảm stale state, race và memory debt.
- Gỡ các fallback “tự chữa dữ liệu” ở repository/model, đặc biệt với field nhạy cảm cho authorization hoặc timeline.
- Hợp nhất source of truth cho locale, navigator key, session bootstrap và các state nền tảng đang bị split-brain.
- Chuẩn hóa parser dữ liệu và validation model theo hướng fail-fast thay vì fabricate dữ liệu giả như `DateTime.now()`.
- Từng bước tách các logic nghiệp vụ quan trọng khỏi UI/trigger để dễ test và giảm coupling.

### [P3] Low - Backlog

- Dọn hardcode text còn sót và chuẩn hóa i18n/copy ở các dialog, permission prompt, accessibility description và messaging UI.
- Nâng quality gate của analyzer/lint để phát hiện sớm API cũ, side effects không an toàn và code smell lặp lại.
- Dọn các lỗi nhỏ về UX/presentation chưa ảnh hưởng trực tiếp tới an toàn hệ thống nhưng làm giảm release quality về lâu dài.
- Bổ sung tài liệu kỹ thuật ngắn cho permission model, ownership model và các rule production để việc onboarding/refactor về sau ít rủi ro hơn.

## 4. Kết luận điều hành

- Đây không phải là một codebase “hỏng toàn diện”, nhưng hiện đang có **một cụm rủi ro production rất rõ** ở security, authorization và data flow cốt lõi.
- Nếu chỉ có một sprint ngắn, nên tập trung toàn lực vào **P0** trước; đây là nhóm việc vừa có rủi ro cao nhất, vừa mở đường an toàn cho mọi refactor phía sau.
- Sau khi hoàn tất P0, đội ngũ nên xử lý **P1** theo từng cụm năng lực: `Auth/Security`, `Location & Safe Route`, `Notifications & Email`, `Native mobile`, rồi mới chuyển sang P2/P3 để dọn nợ kỹ thuật.
