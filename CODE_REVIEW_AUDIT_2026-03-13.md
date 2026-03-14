# Báo cáo Review & Audit mã nguồn - kid_manager

- Thời gian audit: 2026-03-13
- Phạm vi: Flutter app (`lib/`) + Firebase Cloud Functions (`functions/src/`) + cấu hình phụ thuộc
- Mục tiêu: tìm lỗi/rủi ro theo mức độ ưu tiên, nêu rõ nguyên nhân, hậu quả, hướng sửa

## 1) Phương pháp thực hiện

1. Quét toàn bộ cấu trúc source code và các module chính.
2. Chạy static analysis:
- `dart analyze` (toàn dự án Flutter): 133 issues.
- `npm run build` trong `functions/`: pass sau khi cài dependency.
3. Chạy bảo mật dependency:
- `npm audit`: 14 vulnerabilities (2 high, 1 moderate, 11 low).
- `npm audit --omit=dev`: 13 vulnerabilities runtime (2 high, 11 low).
4. Review thủ công các luồng rủi ro cao: auth/session, reset password, location tracking, SOS, schedule import, notification.

## 2) Tổng quan chất lượng hiện tại

- Static analysis (`dart analyze`):
- 50 warning, 83 info.
- Nhóm lỗi lớn nhất: `USE_BUILD_CONTEXT_SYNCHRONOUSLY` (30), `UNUSED_IMPORT` (14), `UNUSED_FIELD` (12).
- Cloud Functions:
- Build TypeScript pass, nhưng có cảnh báo môi trường: project yêu cầu Node 22 trong [`functions/package.json:13`](/c:/Users/ducth/kid_manager/functions/package.json:13), máy chạy Node 24.
- Bảo mật dependency (runtime):
- 2 high: `minimatch`, `fast-xml-parser`.

## 3) Findings chi tiết (ưu tiên từ cao xuống thấp)

### CRITICAL-01: Có thể reset mật khẩu tài khoản bất kỳ (thiếu auth/authorization ở backend)
- Vị trí:
- [`functions/src/functions/user_auth.ts:4`](/c:/Users/ducth/kid_manager/functions/src/functions/user_auth.ts:4)
- [`functions/src/functions/user_auth.ts:8`](/c:/Users/ducth/kid_manager/functions/src/functions/user_auth.ts:8)
- [`functions/src/functions/user_auth.ts:22`](/c:/Users/ducth/kid_manager/functions/src/functions/user_auth.ts:22)
- Hiện trạng:
- Callable `resetUserPassword` nhận `uid` và `newPassword` trực tiếp từ client, không kiểm tra `request.auth`, không kiểm tra quyền người gọi.
- Nguyên nhân:
- Thiếu guard xác thực và phân quyền trước khi gọi `admin.auth().updateUser(...)`.
- Hậu quả:
- Bất kỳ client nào gọi được function có thể đổi mật khẩu user khác nếu biết `uid`.
- Chiếm quyền tài khoản, rủi ro bảo mật cực cao.
- Hướng sửa:
1. Bắt buộc `request.auth?.uid` tồn tại.
2. Chỉ cho phép reset nếu `request.auth.uid == uid` hoặc user có quyền admin hợp lệ.
3. Đưa luồng reset qua OTP/token một lần phía server (không để client truyền `uid` tùy ý).
4. Ghi audit log bảo mật cho các lần đổi mật khẩu.

### CRITICAL-02: Lộ secret trong source code (kể cả comment)
- Vị trí:
- [`functions/src/config.ts:24`](/c:/Users/ducth/kid_manager/functions/src/config.ts:24)
- [`functions/src/functions/send_email.ts:104`](/c:/Users/ducth/kid_manager/functions/src/functions/send_email.ts:104)
- Hiện trạng:
- Secret `RESEND_API_KEY` xuất hiện trực tiếp trong comment source.
- Nguyên nhân:
- Đưa thông tin vận hành thực tế vào code repository.
- Hậu quả:
- Lộ credential gửi email, có thể bị lạm dụng gửi mail trái phép, tăng chi phí và ảnh hưởng uy tín domain.
- Hướng sửa:
1. Rotate key ngay lập tức trên Resend/Firebase Secrets.
2. Xóa key khỏi toàn bộ git history (BFG hoặc filter-repo nếu cần).
3. Dùng secret manager hoàn toàn; tuyệt đối không để mẫu key thật trong comment.

### CRITICAL-03: UI reset mật khẩu báo thành công ngay cả khi backend lỗi
- Vị trí:
- [`lib/viewmodels/auth_vm.dart:129`](/c:/Users/ducth/kid_manager/lib/viewmodels/auth_vm.dart:129)
- [`lib/viewmodels/auth_vm.dart:133`](/c:/Users/ducth/kid_manager/lib/viewmodels/auth_vm.dart:133)
- [`lib/views/auth/reset_pass_screen.dart:77`](/c:/Users/ducth/kid_manager/lib/views/auth/reset_pass_screen.dart:77)
- [`lib/views/auth/reset_pass_screen.dart:84`](/c:/Users/ducth/kid_manager/lib/views/auth/reset_pass_screen.dart:84)
- Hiện trạng:
- `AuthVM.resetPassword()` gọi `_runAuthAction()` (hàm này nuốt exception và trả `null`), nhưng `ResetPasswordScreen` luôn hiển thị dialog success sau `await`.
- Nguyên nhân:
- Contract giữa VM và UI không rõ: VM không throw, UI lại xử lý theo `try/catch` như thể VM có throw.
- Hậu quả:
- Người dùng thấy “đổi mật khẩu thành công” giả, dẫn đến lock-out/không đăng nhập được.
- Hướng sửa:
1. Cho `resetPassword()` trả `bool`/`Result` rõ ràng, UI chỉ báo thành công khi `true`.
2. Hoặc để `resetPassword()` throw thật khi thất bại và UI bắt lỗi chuẩn.

### CRITICAL-04: Endpoint SOS worker dùng `onRequest` nhưng chưa xác thực caller
- Vị trí:
- [`functions/src/functions/sos.ts:24`](/c:/Users/ducth/kid_manager/functions/src/functions/sos.ts:24)
- [`functions/src/functions/sos.ts:30`](/c:/Users/ducth/kid_manager/functions/src/functions/sos.ts:30)
- Đối chiếu cấu hình enqueue có OIDC:
- [`functions/src/services/tasks.ts:72`](/c:/Users/ducth/kid_manager/functions/src/services/tasks.ts:72)
- Hiện trạng:
- Worker nhận POST body và xử lý ngay, chưa verify token/caller.
- Nguyên nhân:
- Chưa implement bước verify OIDC/JWT từ Cloud Tasks trước khi xử lý business logic.
- Hậu quả:
- Endpoint có thể bị gọi trái phép để spam reminder, đốt quota và gây nhiễu cảnh báo SOS.
- Hướng sửa:
1. Verify ID token của request (issuer/audience/service account).
2. Từ chối request không hợp lệ bằng `401/403`.
3. Bổ sung idempotency key + rate limit ở worker.

### HIGH-01: Lỗi đọc profile bị diễn giải thành trạng thái đăng xuất
- Vị trí:
- [`lib/repositories/auth_repository.dart:21`](/c:/Users/ducth/kid_manager/lib/repositories/auth_repository.dart:21)
- [`lib/repositories/auth_repository.dart:30`](/c:/Users/ducth/kid_manager/lib/repositories/auth_repository.dart:30)
- [`lib/viewmodels/session/session_vm.dart:32`](/c:/Users/ducth/kid_manager/lib/viewmodels/session/session_vm.dart:32)
- Hiện trạng:
- Nếu `getUserById` lỗi (network/permission tạm thời), `watchSessionUser` trả `null` -> `SessionVM` chuyển sang `unauthenticated`.
- Nguyên nhân:
- Trộn lẫn “lỗi dữ liệu tạm thời” với “đăng xuất thật”.
- Hậu quả:
- Người dùng bị bật về màn login sai ngữ cảnh, tạo loop đăng nhập khó chịu.
- Hướng sửa:
1. Tách trạng thái `error`/`profileUnavailable` khỏi `unauthenticated`.
2. Chỉ coi là logout khi FirebaseAuth thật sự `null`.

### HIGH-02: Cache `parentUid` có thể sai user sau khi đổi tài khoản
- Vị trí:
- [`lib/repositories/location/location_repository_impl.dart:23`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:23)
- [`lib/repositories/location/location_repository_impl.dart:67`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:67)
- [`lib/repositories/location/location_repository_impl.dart:69`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:69)
- Hiện trạng:
- `_cachedParentUid` dùng lại không gắn với `uid` hiện tại.
- Nguyên nhân:
- Cache thiếu key theo user hoặc thiếu invalidate khi auth đổi.
- Hậu quả:
- Có thể ghi metadata location với parent sai sau khi switch account cùng phiên app.
- Hướng sửa:
1. Cache theo cặp `(uid, parentUid)`.
2. Xóa cache khi logout/auth state changed.

### HIGH-03: Polling vị trí trẻ em 2 giây/lần qua Cloud Function (rủi ro scale và chi phí)
- Vị trí:
- [`lib/repositories/location/location_repository_impl.dart:243`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:243)
- [`lib/repositories/location/location_repository_impl.dart:248`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:248)
- [`lib/repositories/location/location_repository_impl.dart:250`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:250)
- Hiện trạng:
- Mỗi child tạo timer riêng, cứ 2s gọi callable `getChildLocationCurrent`.
- Nguyên nhân:
- Thiết kế pull polling thay vì stream/subscription realtime.
- Hậu quả:
- Tăng mạnh số request Function theo số child và thời gian mở màn hình.
- Dễ chạm quota/độ trễ cao khi quy mô tăng.
- Hướng sửa:
1. Chuyển sang listener RTDB/Firestore trực tiếp cho dữ liệu current location.
2. Nếu bắt buộc polling: backoff thích ứng + interval lớn hơn + gộp request nhiều child.

### HIGH-04: Vulnerabilities runtime ở Cloud Functions dependencies
- Nguồn dữ liệu: `npm audit --omit=dev`.
- Hiện trạng:
- 13 lỗ hổng runtime, gồm 2 high (`minimatch`, `fast-xml-parser`).
- Nguyên nhân:
- Chuỗi phụ thuộc transitives chưa được nâng cấp/ghim phiên bản an toàn.
- Hậu quả:
- Tăng rủi ro ReDoS/DoS trên backend function (tùy đường gọi thực tế).
- Hướng sửa:
1. Ưu tiên xử lý 2 high trước (update dependency tree).
2. Thiết lập quy trình `npm audit` định kỳ trong CI.

### HIGH-05: Log nhạy cảm (FCM token, toạ độ, payload location)
- Vị trí tiêu biểu:
- [`lib/repositories/auth_repository.dart:79`](/c:/Users/ducth/kid_manager/lib/repositories/auth_repository.dart:79)
- [`lib/repositories/location/location_repository_impl.dart:41`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:41)
- [`lib/repositories/location/location_repository_impl.dart:42`](/c:/Users/ducth/kid_manager/lib/repositories/location/location_repository_impl.dart:42)
- Hiện trạng:
- In trực tiếp token và dữ liệu vị trí chi tiết trong debug log.
- Nguyên nhân:
- Logging chưa phân tầng theo môi trường và mức nhạy cảm dữ liệu.
- Hậu quả:
- Rò rỉ dữ liệu cá nhân qua log collector/thiết bị debug.
- Hướng sửa:
1. Mask token bắt buộc, không log full token.
2. Tắt log vị trí chi tiết ở production; dùng structured logging + sampling.

### HIGH-06: Gọi HTTP Mapbox chưa có timeout, lại log full response body
- Vị trí:
- [`lib/services/location/mapbox_route_service.dart:54`](/c:/Users/ducth/kid_manager/lib/services/location/mapbox_route_service.dart:54)
- [`lib/services/location/mapbox_route_service.dart:56`](/c:/Users/ducth/kid_manager/lib/services/location/mapbox_route_service.dart:56)
- [`lib/features/map_engine/services/map_matching_service.dart:135`](/c:/Users/ducth/kid_manager/lib/features/map_engine/services/map_matching_service.dart:135)
- [`lib/features/map_engine/services/map_matching_service.dart:137`](/c:/Users/ducth/kid_manager/lib/features/map_engine/services/map_matching_service.dart:137)
- Hiện trạng:
- `http.get(...)` không timeout; khi lỗi lại log toàn bộ body.
- Nguyên nhân:
- Thiếu network guard chuẩn cho dịch vụ ngoài.
- Hậu quả:
- Có thể treo request lâu, làm UI chậm; log body lớn gây noise và lộ dữ liệu.
- Hướng sửa:
1. Áp dụng `.timeout(...)` và retry có backoff.
2. Chỉ log metadata (`statusCode`, `requestId`) thay vì full body.

### MEDIUM-01: Parse giờ import schedule chưa validate range giờ/phút
- Vị trí:
- [`lib/services/schedule/schedule_import_service.dart:454`](/c:/Users/ducth/kid_manager/lib/services/schedule/schedule_import_service.dart:454)
- [`lib/services/schedule/schedule_import_service.dart:540`](/c:/Users/ducth/kid_manager/lib/services/schedule/schedule_import_service.dart:540)
- Trạng thái cập nhật (2026-03-13):
- ✅ Đã sửa.
- Hiện trạng:
- Parse `HH:mm` rồi tạo `TimeOfDay` ngay, không chặn trường hợp `25:61` (đặc biệt release mode assert không bảo vệ).
- Nguyên nhân:
- Thiếu check range thủ công trước khi dựng object thời gian.
- Hậu quả:
- Dữ liệu giờ lỗi có thể bị normalize sai (lệch sang ngày khác) thay vì báo lỗi import.
- Hướng sửa:
1. Validate `0<=hour<=23` và `0<=minute<=59` rõ ràng.
2. Trả lỗi row cụ thể khi vượt range.
- Đã triển khai:
1. Bổ sung hàm validate range giờ/phút trước khi tạo `TimeOfDay`.
2. Chặn giá trị số thời gian ngoài khoảng `[0, 1)` (tránh normalize sai ngày/giờ).
3. Chuẩn hóa parse `AM/PM` chỉ nhận giờ `1..12`.
- Kết quả kiểm tra sau sửa:
1. `dart analyze lib/services/schedule/schedule_import_service.dart lib/views/parent/schedule/schedule_import_excel_screen.dart` không có warning/error mới liên quan phần parse time.

### MEDIUM-02: Hiển thị số dòng preview import bị lệch (off-by-one)
- Vị trí:
- [`lib/views/parent/schedule/schedule_import_excel_screen.dart:922`](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_import_excel_screen.dart:922)
- [`lib/views/parent/schedule/schedule_import_excel_screen.dart:929`](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_import_excel_screen.dart:929)
- Trạng thái cập nhật (2026-03-13):
- ✅ Đã sửa.
- Hiện trạng:
- UI trừ 1 khỏi `rowIndex`, trong khi `rowIndex` đã là số dòng Excel thực tế.
- Hậu quả:
- Người dùng đối chiếu lỗi sai dòng, mất thời gian sửa file import.
- Hướng sửa:
1. Dùng trực tiếp `r.rowIndex` khi render.
- Đã triển khai:
1. Thay `r.rowIndex - 1` thành `r.rowIndex` cho cả dòng lỗi và dòng tiêu đề preview.
- Kết quả kiểm tra sau sửa:
1. `rowIndex` hiển thị theo đúng số dòng Excel thực tế tại [`lib/views/parent/schedule/schedule_import_excel_screen.dart:922`](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_import_excel_screen.dart:922) và [`lib/views/parent/schedule/schedule_import_excel_screen.dart:929`](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_import_excel_screen.dart:929).

### MEDIUM-03: API watchChildrenByParentUid thiếu filter role
- Vị trí:
- [`lib/repositories/user_repository.dart:373`](/c:/Users/ducth/kid_manager/lib/repositories/user_repository.dart:373)
- [`lib/repositories/user_repository.dart:376`](/c:/Users/ducth/kid_manager/lib/repositories/user_repository.dart:376)
- Hiện trạng:
- Query chỉ lọc `parentUid`, không lọc `role == child`.
- Hậu quả:
- Dữ liệu trả về có thể lẫn document không phải child nếu schema mở rộng sau này.
- Hướng sửa:
1. Bổ sung điều kiện `where('role', isEqualTo: 'child')`.

### MEDIUM-04: 30 điểm dùng `BuildContext` qua async gap
- Nguồn dữ liệu: `dart analyze`.
- Ví dụ vị trí:
- [`lib/views/parent/schedule/schedule_import_excel_screen.dart:366`](/c:/Users/ducth/kid_manager/lib/views/parent/schedule/schedule_import_excel_screen.dart:366)
- [`lib/views/auth/login_screen.dart:83`](/c:/Users/ducth/kid_manager/lib/views/auth/login_screen.dart:83)
- [`lib/views/terms_screen.dart:17`](/c:/Users/ducth/kid_manager/lib/views/terms_screen.dart:17)
- Hậu quả:
- Dễ crash/throw khi widget đã dispose nhưng vẫn gọi `Navigator/ScaffoldMessenger`.
- Hướng sửa:
1. Chuẩn hóa pattern `if (!mounted) return;` ngay sau mọi `await` trước khi dùng `context`.

### LOW-01: Nhiều TODO chưa hoàn thiện ở các luồng người dùng
- Số lượng: 15 TODO.
- Vị trí tiêu biểu:
- [`lib/services/notifications/notification_service.dart:109`](/c:/Users/ducth/kid_manager/lib/services/notifications/notification_service.dart:109)
- [`lib/views/auth/start_screen.dart:69`](/c:/Users/ducth/kid_manager/lib/views/auth/start_screen.dart:69)
- [`lib/views/home/home_screen.dart:52`](/c:/Users/ducth/kid_manager/lib/views/home/home_screen.dart:52)
- Hậu quả:
- Feature gap, click flow không đầy đủ ở production.
- Hướng sửa:
1. Lập backlog rõ owner/deadline cho TODO có ảnh hưởng hành vi người dùng.

### LOW-02: Thiếu test tự động trong repo
- Hiện trạng:
- Không có thư mục `test/` (đang `NO_TEST_DIR`).
- Hậu quả:
- Dễ regression khi refactor các luồng phức tạp (auth, location, import).
- Hướng sửa:
1. Bắt đầu từ unit test cho `AuthVM`, `ScheduleImportService`, `LocationRepositoryImpl`.
2. Thêm smoke test cho các flow quan trọng (login/reset/import).

## 4) Kế hoạch khắc phục đề xuất (ưu tiên thực thi)

1. P0 - Chặn lỗ hổng bảo mật ngay:
- Khóa/reset `resetUserPassword` bằng auth + authorization.
- Rotate tất cả secret đã lộ, xóa khỏi lịch sử git.
- Thêm verify token cho `sosReminderWorker`.

2. P1 - Ổn định hành vi người dùng:
- Sửa logic báo thành công giả ở reset password.
- Sửa session handling để không logout giả khi lỗi đọc profile.
- Sửa parse time + row number ở import.

3. P2 - Nâng khả năng scale/vận hành:
- Thay polling location 2s bằng realtime stream hoặc cơ chế hợp nhất request.
- Giảm log nhạy cảm và thêm timeout/retry chuẩn cho network.

4. P3 - Nâng chất lượng dài hạn:
- Giảm dần 133 analyzer issues (ưu tiên nhóm `use_build_context_synchronously`).
- Thiết lập test và `npm audit`/`dart analyze` trong CI.

## 5) Ghi chú minh bạch

- Audit này dựa trên code hiện có tại thời điểm 2026-03-13 trong workspace.
- Do không có test suite hiện hữu, mức độ đúng/sai runtime được đánh giá theo static analysis + code reasoning + kinh nghiệm vận hành.
- `flutter test` không cho kết quả hoàn chỉnh trong phiên chạy này (timeout).
