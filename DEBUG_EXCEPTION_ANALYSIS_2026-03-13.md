# Báo cáo phân tích log debug F5 (Android)

- Thời điểm phân tích: 13/03/2026
- Dữ liệu đầu vào: log chạy `Launching lib\\main.dart ...` do bạn cung cấp

## 1) Lỗi chính bạn thấy ở `socket_patch.dart`

### Lỗi là gì
- Exception thực tế trong log:
  - `HandshakeException: Connection terminated during handshake`
- Ngữ cảnh:
  - Xảy ra khi Flutter resolve ảnh mạng:
  - `NetworkImage("https://i.ibb.co/rRpqdxYx/23069fc139c1.jpg")`
- Vị trí `socket_patch.dart` chỉ là file nội bộ Dart VM xử lý socket/TLS, **không phải** file app của bạn gây lỗi trực tiếp.

### Nguyên nhân khả dĩ
- Kết nối TLS tới host `i.ibb.co` bị đóng sớm trong bước bắt tay SSL/TLS.
- Các nguyên nhân thường gặp:
  - Mạng emulator/device không ổn định hoặc bị chặn bởi proxy/VPN/firewall.
  - Endpoint ảnh tạm thời lỗi/CDN reset kết nối.
  - Chứng chỉ hoặc chuỗi trust trên máy ảo tại thời điểm đó có vấn đề tạm thời.

### Hậu quả
- Ảnh từ URL đó không hiển thị được.
- Exception được Flutter image pipeline bắt (`Exception caught by image resource service`), nên app **không chết toàn bộ** vì lỗi này.
- Nếu không có placeholder/errorBuilder, UX sẽ xấu (ô ảnh trống/nháy lỗi).

## 2) Các cảnh báo/lỗi phụ đáng chú ý trong log

### 2.1 `GoogleApiManager` + `DEVELOPER_ERROR`
- Log:
  - `SecurityException: Unknown calling package name 'com.google.android.gms'`
  - `ConnectionResult{statusCode=DEVELOPER_ERROR}`
- Nhận định:
  - Thường gặp trên emulator/Google Play Services khi một số API nội bộ (Phenotype/Provider flags) không tương thích môi trường debug.
  - Không phải crash chính trong log này.
- Hậu quả:
  - Một số tính năng phụ thuộc Google Play Services flags có thể hoạt động kém ổn định trong môi trường giả lập.

### 2.2 Firebase App Check chưa cấu hình
- Log:
  - `No AppCheckProvider installed.`
- Nguyên nhân:
  - Chưa cài provider App Check (Play Integrity/SafetyNet/Debug provider).
- Hậu quả:
  - Request vẫn chạy với placeholder token trong môi trường hiện tại, nhưng giảm mức bảo vệ backend.

### 2.3 Hiệu năng UI thread
- Log nhiều lần:
  - `Skipped xxx frames! The application may be doing too much work on its main thread.`
- Hậu quả:
  - Giật/khựng UI, input delay, trải nghiệm kém khi thao tác màn hình nặng.

### 2.4 Mapbox/AppCompat theme warning
- Log:
  - `... can only be used with a Theme.AppCompat theme`
- Hậu quả:
  - Một số thành phần UI plugin (compass/logo/attribution) có thể hiển thị không đúng hoặc lỗi theo thiết bị/theme.

## 3) Kết luận ngắn

- **Sự cố bạn dừng ở `socket_patch.dart` là triệu chứng của lỗi mạng TLS khi tải ảnh từ `i.ibb.co`, không phải bug trực tiếp trong file SDK đó.**
- Đây là lỗi có thể tái diễn theo mạng/CDN, gây hỏng hiển thị ảnh nhưng chưa thấy dấu hiệu crash toàn app trong log này.
- Ngoài ra, project còn các cảnh báo cấu hình (App Check, GoogleApiManager trên emulator, Mapbox theme) và vấn đề hiệu năng main thread cần xử lý riêng.

## 4) Cách sửa đề xuất (chưa sửa code)

### 4.1 Sửa lỗi `HandshakeException` khi tải ảnh mạng
- Kiểm tra URL ảnh có truy cập ổn định trên emulator và thiết bị thật hay không.
- Nếu host `i.ibb.co` không ổn định, chuyển sang nguồn ảnh ổn định hơn (Firebase Storage/CDN riêng).
- Bổ sung cơ chế fallback khi tải ảnh lỗi (`placeholder` + `errorBuilder`) để tránh ô ảnh trắng.
- Bổ sung retry nhẹ cho request ảnh hoặc prefetch trước khi vào màn hình chính.
- Không dùng giải pháp bỏ kiểm tra chứng chỉ SSL trong app vì làm giảm bảo mật.

### 4.2 Sửa cảnh báo `GoogleApiManager` + `DEVELOPER_ERROR`
- Cập nhật Android Emulator image (loại có Google Play), cập nhật Google Play Services và Cold Boot lại máy ảo.
- Đối chiếu thử trên thiết bị thật để tách lỗi môi trường giả lập.
- Rà lại cấu hình Firebase/Google services (`applicationId`, `google-services.json`) để tránh sai package khi gọi API Google.
- Nếu chức năng chính không bị ảnh hưởng, phân loại đây là cảnh báo môi trường debug và tiếp tục theo dõi.

### 4.3 Sửa lỗi Firebase App Check chưa cấu hình
- Môi trường debug: dùng `Debug App Check provider` và đăng ký debug token trên Firebase Console.
- Môi trường release: dùng `Play Integrity` (Android) để bảo vệ backend đúng chuẩn.
- Khởi tạo App Check sớm ở luồng khởi động app trước các request mạng quan trọng.
- Tiêu chí đạt: log không còn `No AppCheckProvider installed`.

### 4.4 Giảm `Skipped frames` (khựng UI)
- Chạy đo ở `--profile` và kiểm tra bằng Flutter DevTools (Timeline/CPU/Memory).
- Dời các tác vụ nặng (init dịch vụ, đọc dữ liệu lớn, xử lý ảnh/map) ra khỏi main thread và tránh chạy dồn lúc mở app.
- Trì hoãn các tác vụ không thiết yếu sang sau frame đầu tiên.
- Tối ưu widget tree (giảm rebuild không cần thiết, tận dụng `const`, kiểm soát listener/stream).

### 4.5 Sửa cảnh báo Mapbox/AppCompat theme
- Kiểm tra `android/app/src/main/res/values/styles.xml` để đảm bảo theme của `MainActivity` là hậu duệ của `Theme.AppCompat` (hoặc `Theme.MaterialComponents` tương thích AppCompat).
- Đảm bảo theme launch và theme runtime nhất quán cho Activity chứa Mapbox.
- Tiêu chí đạt: không còn warning `can only be used with a Theme.AppCompat theme`.

## 5) Thứ tự ưu tiên xử lý

1. ✅ Lỗi TLS tải ảnh + fallback UI ảnh (ảnh hưởng trực tiếp trải nghiệm).
2. ✅ Cấu hình Firebase App Check (bảo mật backend).
3. Theme AppCompat cho Mapbox (ổn định UI plugin).
4. ✅ Tối ưu jank (`Skipped frames`) theo kết quả profile (đợt 1 - đã triển khai code).
5. Theo dõi `GoogleApiManager DEVELOPER_ERROR` trên emulator, đối chiếu thiết bị thật.

## 6) Checklist xác nhận sau khi xử lý

- Không còn `HandshakeException` khi tải ảnh đại diện trong luồng đăng nhập/vào màn hình chính.
- Khi lỗi mạng, ảnh hiển thị placeholder/fallback thay vì văng exception gây nhiễu debug.
- Không còn log `No AppCheckProvider installed`.
- Giảm rõ rệt số lần `Skipped frames` ở các luồng thao tác chính.
- Không còn cảnh báo Mapbox liên quan `Theme.AppCompat`.

## 7) Tiến độ sửa thực tế (13/03/2026)

- [x] Đã triển khai fallback UI cho ảnh mạng bằng `errorBuilder` ở các màn: profile, avatar, carousel và modal xem ảnh.
- [x] Đã thay chỗ dùng ảnh trong `DecorationImage` (không có `errorBuilder`) sang widget ảnh có fallback để tránh ô ảnh trống khi TLS fail.
- [x] Đã bổ sung guard URL ảnh không hợp lệ trong `tappable_photo.dart` (chỉ dùng `NetworkImage` khi là `http/https` hợp lệ).
- [x] Đã chạy `dart analyze` cho các file vừa sửa và không còn issue.
- [ ] Chưa xác nhận bằng log runtime mới rằng `HandshakeException` đã hết hoàn toàn (cần bạn chạy lại luồng cũ để đối chiếu).

## 8) Cập nhật điều tra đợt 2 (13/03/2026)

### 8.1 Nguyên nhân chi tiết từ log mới
- Debugger dừng ở `socket_patch.dart` do exception mạng/DNS phát sinh trong quá trình resolve host `i.ibb.co`.
- Màn `PersonalInfo` và modal xem ảnh dùng hai request độc lập:
  - Màn info fail request đầu -> rơi fallback.
  - Khi bấm vào modal, request mới có thể thành công -> ảnh hiện bình thường.
- Mapbox avatar có timeout lặp lại (`TimeoutException after 10s`) làm request ảnh bị spam và dễ dừng debugger liên tục.

### 8.2 Nội dung đã sửa trong code (đợt 2)
- [x] Thêm widget mới `SmartNetworkImage`:
  - Tải ảnh qua HTTP có retry + timeout.
  - Cache bytes trong memory để giữ ảnh đã tải thành công.
  - Khi mạng chập chờn, ưu tiên giữ ảnh cũ thay vì rớt fallback ngay.
- [x] Màn `PersonalInfo` đã chuyển sang dùng `SmartNetworkImage` cho cả cover và avatar.
- [x] Tăng độ bền tải avatar cho Mapbox:
  - `_fetchAvatarBytes` có retry nhiều lần và timeout dài hơn.
  - Khi fetch lỗi, giữ avatar thành công gần nhất thay vì xoá cache ngay.
  - Thêm cooldown 45 giây để tránh spam request lỗi liên tiếp cho cùng child.
- [x] Đã chạy `dart analyze` cho các file đợt 2 và không có issue.

### 8.3 File đã chỉnh trong đợt 2
- `lib/widgets/common/smart_network_image.dart` (mới)
- `lib/views/personal_info_screen.dart`
- `lib/features/presentation/shared/state/mapbox_controller.dart`

### 8.4 Kỳ vọng sau bản sửa đợt 2
- Ảnh ở màn info ổn định hơn, không còn tình trạng dễ rớt fallback trong khi modal vẫn hiện ảnh.
- Giảm mạnh số lần timeout avatar map lặp lại do đã có giữ-cache + cooldown.
- Có thể vẫn còn log cảnh báo mạng rời rạc nếu emulator/host `i.ibb.co` mất ổn định theo thời điểm.

## 9) Cập nhật sửa mục 2 - Firebase App Check (13/03/2026)

### 9.1 Nội dung đã triển khai
- [x] Đã thêm dependency `firebase_app_check` vào `pubspec.yaml`.
- [x] Đã activate App Check ngay sau `Firebase.initializeApp` trong luồng `main`.
- [x] Đã activate App Check trong background isolate của FCM (`_firebaseMessagingBackgroundHandler`) để tránh nền không có provider.
- [x] Cấu hình provider theo môi trường:
  - Debug: `AndroidProvider.debug` / `AppleProvider.debug`
  - Release: `AndroidProvider.playIntegrity` / `AppleProvider.deviceCheck`
- [x] Đã bật auto refresh token App Check.
- [x] Ở debug có log token rút gọn để dễ đối chiếu cấu hình.

### 9.2 File đã sửa
- `pubspec.yaml`
- `lib/main.dart`

### 9.3 Kết quả kiểm tra kỹ thuật
- [x] Đã chạy `flutter pub get` thành công sau khi thêm package.
- [x] Đã chạy `dart analyze` cho các file liên quan và không có issue.

### 9.4 Cần xác nhận thêm bằng runtime log
- [ ] Chạy lại app debug và kiểm tra log không còn lặp:
  - `No AppCheckProvider installed`
- [ ] Nếu vẫn còn warning, cần đăng ký debug token trên Firebase Console (App Check -> ứng dụng Android -> Manage debug tokens).

### 9.5 Kết quả xác nhận từ log chạy lại (13/03/2026)
- [x] Không còn lỗi `No AppCheckProvider installed` (đã qua bước thiếu provider).
- [ ] Hiện còn lỗi xác thực debug token:
  - `Error returned from API. code: 403 body: App attestation failed.`
  - `Too many attempts.`
- [x] Log đã in debug secret từ SDK:
  - `Enter this debug secret into the allow list in the Firebase Console...`
- Nhận định: code App Check trong app đã chạy, nhưng Firebase Console chưa allowlist debug token của máy/emulator hiện tại.

### 9.6 Việc cần làm trên Firebase Console (bắt buộc để hết 403)
1. Vào Firebase Console -> App Check -> chọn app Android `com.example.kid_manager`.
2. Vào mục Manage debug tokens (hoặc Debug tokens).
3. Thêm debug secret vừa in ra logcat.
4. Chờ 1-5 phút, uninstall app debug trên emulator và chạy lại.
5. Kiểm tra lại log:
   - Không còn `App attestation failed`
   - Không còn `Too many attempts`

### 9.7 Cập nhật kỹ thuật đã chỉnh sau log mới
- [x] Đã chỉnh lại logging trong `main.dart` để tránh thông báo gây hiểu nhầm `AppCheck activation skipped` khi thực tế chỉ fail lúc lấy token.
- [x] Tách riêng các bước: `activate` -> `setTokenAutoRefreshEnabled` -> `getToken` (debug), giúp chẩn đoán rõ nguyên nhân hơn.

### 9.8 Ghi nhận phụ từ log mới (không thuộc App Check)
- Avatar map đã tải thành công cho cả 2 child:
  - `✅ fetched bytes ...`
  - `✅ avatar ready ...`
- Điều này xác nhận bản vá ảnh mạng/map marker ở mục 1 hoạt động tốt hơn so với trước.

## 10) Cập nhật lỗi logout crash (13/03/2026)

### 10.1 Dấu hiệu trong log
- Có lỗi trong lúc logout:
  - `[firebase_functions/unauthenticated] UNAUTHENTICATED` tại `unregisterFcmToken`.
- Ngay sau sign-out xuất hiện nhiều warning:
  - Firestore `PERMISSION_DENIED`
  - Realtime Database `This client does not have permission`
- Đây là pattern điển hình của việc stream session cũ còn sống khi auth đã đổi trạng thái.

### 10.2 Nguyên nhân kỹ thuật
- Luồng logout trước đó chưa dọn hết watcher/session stream trước khi signOut.
- Một số listener notification/session chưa có `onError`, dễ phát sinh uncaught async exception (thường dừng ở `schedule_microtask.dart`/`zone.dart` trong debug).

### 10.3 Nội dung đã sửa
- [x] `NotificationVM`: thêm `onError` cho các stream listen để chặn uncaught async exception.
- [x] `AppManagementVM`: thêm hàm `clear()` để hủy watcher và reset state khi logout.
- [x] `ConfirmLogoutSheet.logout`: dọn thứ tự an toàn trước khi signOut:
  - stop watcher location
  - clear notification/user/appManagement state
  - rồi mới gọi `authVM.logout()`
- [x] `AuthRepository.watchSessionUser`: bọc `try/catch` để không quăng lỗi stream khi Firestore fail sau signOut.
- [x] `SessionVM`: thêm `onError` cho auth/session stream để fallback về `unauthenticated`.
- [x] `AuthVM.logout`: set `_user = null` ngay sau logout thành công để UI thoát session nhanh và sạch.

### 10.4 File đã sửa cho lỗi logout
- `lib/viewmodels/notification_vm.dart`
- `lib/viewmodels/app_management_vm.dart`
- `lib/views/personal_info_screen.dart`
- `lib/repositories/auth_repository.dart`
- `lib/viewmodels/session/session_vm.dart`
- `lib/viewmodels/auth_vm.dart`

### 10.5 Kết quả kỹ thuật
- [x] Đã chạy `dart analyze` cho các file liên quan logout và không còn issue.

### 10.6 Cần bạn xác nhận lại
- [ ] Chạy lại flow: login -> vào app -> logout.
- [ ] Kiểm tra không còn dừng debugger ở `schedule_microtask.dart` khi logout.
- [ ] Kiểm tra không còn burst `PERMISSION_DENIED` kéo dài sau khi đã về màn Login.

### 10.7 Ghi chú App Check từ log mới
- Debug secret đã đổi (log hiện secret mới), nên nếu bạn chỉ allowlist token cũ thì vẫn còn `403 App attestation failed`.
- Cần add đúng debug secret mới đang in trong log của lần chạy hiện tại.

## 11) Cập nhật lỗi Mapbox removeStyleImage (13/03/2026)

### 11.1 Lỗi
- `PlatformException ... Image 'focus_bubble_img' is not present in style, cannot remove`
- Xuất hiện khi gọi `removeStyleImage` trong lúc style chưa có image đó.

### 11.2 Nguyên nhân
- Luồng focus bubble luôn cố remove image cũ trước khi add image mới.
- Ở một số vòng đời style (clean run, style reload, detach/attach), image chưa từng được add nhưng vẫn bị remove.

### 11.3 Đã sửa
- [x] Thêm cờ `_bubbleImageAdded` để chỉ remove khi image đã từng add trong session style hiện tại.
- [x] Reset cờ này khi `attach`, `detach`, `onStyleLoaded`.
- [x] Bỏ qua an toàn lỗi “image not present in style” khi remove.

### 11.4 File đã sửa
- `lib/features/presentation/shared/state/mapbox_controller.dart`

## 12) Cập nhật mục 4 - Tối ưu jank `Skipped frames` (13/03/2026)

### 12.1 Nhận định nguyên nhân chính
- App khởi động đang `await` nhiều tác vụ non-critical trước `runApp` (notification/alarm/FCM permission/token/date formatting), làm chậm frame đầu.
- Luồng map xử lý avatar có decode ảnh lớn + add style image liên tiếp, dễ tạo spike CPU/GPU khi vừa vào màn map.
- Avatar map được kick cùng lúc cho nhiều child ngay khi style load (burst xử lý), tăng khả năng khựng.

### 12.2 Đã sửa trong code (đợt 1)
- [x] `lib/main.dart`
  - Dời các tác vụ non-critical sang sau frame đầu (`addPostFrameCallback`) qua `_runDeferredStartupTasks()`:
    - `LocalNotificationService.init()`
    - `NotificationService.init()`
    - `NotificationService.handleInitialMessage()`
    - `LocalAlarmService.I.init()`
    - `initializeDateFormatting('vi_VN')`
    - `FirebaseMessaging.requestPermission()`
    - `FirebaseMessaging.getToken()`
  - Giữ lại phần critical trước `runApp`: `Firebase.initializeApp`, AppCheck activate, background handler, dotenv/mapbox token, `StorageService.create`.
  - Bỏ block startup từ debug AppCheck token: đổi sang `unawaited(getToken())`.

- [x] `lib/features/presentation/shared/state/mapbox_controller.dart`
  - Tăng debounce update marker map từ `60ms` lên `100ms` để giảm tần suất cập nhật dồn dập.
  - Tối ưu decode avatar:
    - `instantiateImageCodec(..., targetWidth: 192, targetHeight: 192)` thay vì decode full-size ảnh gốc.
  - Thêm cache ảnh đã normalize theo `style image id + fingerprint bytes` để tránh normalize lặp lại khi style reload.

- [x] `lib/views/parent/location/parent_location_screen.dart`
  - Không còn nạp avatar đồng loạt cùng lúc khi `onStyleLoaded`.
  - Chuyển sang warm-up tuần tự `_warmupAvatars(...)` (mỗi item nhường frame ~16ms) để giảm burst CPU trên UI isolate.
  - `_syncToMap()` và `_focusFirstChildOnce()` chuyển sang `unawaited` tại nhánh setup style để tránh giữ callback quá lâu.

### 12.3 Kỳ vọng sau bản vá
- Frame đầu vào app mượt hơn do giảm blocking trước `runApp`.
- Khi vào màn bản đồ, giảm đột biến `Skipped frames` do avatar được xử lý dàn đều và decode nhẹ hơn.
- Giảm nguy cơ jank khi style reload hoặc khi quay lại màn map.

### 12.4 Việc cần bạn xác nhận bằng profile/runtime
- [ ] Chạy lại bằng `flutter run --profile` trên cùng flow và so sánh:
  - Số lượng `Skipped frames` lúc vào appi   - Spike lúc mở màn map parent.
- [ ] Đối chiếu log có còn các cụm `Skipped 1000+ frames`/`Davey duration` dài bất thường không.
- [ ] Nếu vẫn còn jank lớn, bước tiếp theo là profile timeline để khoanh chính xác widget/rebuild hay plugin platform view.

### 12.5 Tối ưu bổ sung (đợt 2)
- [x] `lib/features/sessionguard/session_guard.dart`
  - Thêm debounce `120ms` cho `_syncChildrenWatch()` để giảm gọi dồn dập khi `UserVm` notify liên tục.
  - Thêm bộ nhớ `_lastSyncedChildren` để bỏ qua sync trùng tập child IDs.
  - Giảm rủi ro async-context warning bằng cách lấy `AppManagementVM` trước `await`.

- [x] `lib/viewmodels/location/parent_location_vm.dart`
  - Dọn log nóng trong `syncWatching`, chỉ log khi `kDebugMode` và đã có thay đổi thật.
  - Bỏ notify trung gian không cần thiết khi sync để tránh thêm rebuild giữa chừng.

- [x] `lib/views/parent/location/parent_location_screen.dart`
  - Dọn warning analyzer liên quan kiểu dữ liệu và callback `catchError`.

### 12.6 Kết quả kiểm tra kỹ thuật sau đợt 2
- [x] Đã chạy `dart analyze` cho các file chính của mục 4:
  - `lib/main.dart`
  - `lib/features/presentation/shared/state/mapbox_controller.dart`
  - `lib/views/parent/location/parent_location_screen.dart`
  - `lib/features/sessionguard/session_guard.dart`
  - `lib/viewmodels/location/parent_location_vm.dart`
- [x] Kết quả: `No issues found!`

## 13) Cập nhật fix UI overflow (13/03/2026)

### 13.1 Lỗi
- `A RenderFlex overflowed by 20 pixels on the right`
- Vị trí log chỉ ra: `lib/views/parent/schedule/schedule_import_excel_screen.dart:692`
- Ngữ cảnh: nút hiển thị text dài (`Choose another file`) trên vùng width hẹp.

### 13.2 Nguyên nhân
- `Row` trong nút chưa giới hạn co giãn cho `Text`.
- `Text` không có `maxLines`/`overflow` nên giữ kích thước tự nhiên, đẩy `Row` tràn ngang.

### 13.3 Đã sửa
- [x] Vá `_PrimaryButton`:
  - Bọc nội dung bằng `Padding(horizontal: 12)`.
  - Bọc text bằng `Flexible`.
  - Thêm `maxLines: 1`, `overflow: TextOverflow.ellipsis`, `textAlign: TextAlign.center`.
- [x] Vá tương tự cho `_PrimaryOutlineButton` để tránh lỗi tái diễn ở biến thể nút còn lại.

### 13.4 File đã sửa
- `lib/views/parent/schedule/schedule_import_excel_screen.dart`

### 13.5 Kết quả kiểm tra
- [x] Đã chạy `dart analyze lib/views/parent/schedule/schedule_import_excel_screen.dart`.
- [x] Không còn compile error liên quan bản fix overflow.
- [i] Còn một số `info` cũ (`use_build_context_synchronously`, `unnecessary_underscores`) không thuộc lỗi overflow này.
