1. **Các file liên quan**

- [signup_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/signup_screen.dart):60 `_onSignUpPressed` gọi `AuthVM.register(...)`, rồi điều hướng OTP.
- [login_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/login_screen.dart):72 `_onLoginPressed` gọi `AuthVM.login(...)`, xử lý lỗi `accountNotActivated`.
- [otp_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/otp_screen.dart):77 `_handleVerifyOtp`, 316 resend OTP, success verify-email thì `AuthVM.logout()`.
- [forgot_pass_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/forgot_pass_screen.dart):46 gọi `AuthVM.forgotPassword(...)` rồi vào OTP reset password.
- [auth_vm.dart](c:/Users/ducth/kid_manager/lib/viewmodels/auth_vm.dart):46 `login`, 136 `register`, 178 `logout`.
- [otp_vm.dart](c:/Users/ducth/kid_manager/lib/viewmodels/otp_vm.dart):48 `verifyOtp`, 86 `resendOtp`, cooldown/lock timer.
- [auth_repository.dart](c:/Users/ducth/kid_manager/lib/repositories/auth_repository.dart):26 `watchSessionUser`, 77 `login`, 81 `register`, 99 `logout`.
- [firebase_auth_service.dart](c:/Users/ducth/kid_manager/lib/services/firebase_auth_service.dart):15 sign-in email/password, 19 create user, 89 sign-out.
- [otp_repository.dart](c:/Users/ducth/kid_manager/lib/repositories/otp_repository.dart):24 `requestEmailOtp`, 34 `verifyEmailOtp`, 70 `resendOtp`.
- [user_repository.dart](c:/Users/ducth/kid_manager/lib/repositories/user_repository.dart):60 `createParentIfMissing`, 52 `getUserById`.
- [family_repository.dart](c:/Users/ducth/kid_manager/lib/repositories/user/family_repository.dart):23 tạo Firestore `users/{uid}` + `families/*`, mặc định `isActive=false`.
- [app_user.dart](c:/Users/ducth/kid_manager/lib/models/app_user.dart):50 model `isActive`.
- [session_vm.dart](c:/Users/ducth/kid_manager/lib/viewmodels/session/session_vm.dart):30 nghe `watchSessionUser` để set authenticated/unauthenticated.
- [session_guard.dart](c:/Users/ducth/kid_manager/lib/features/sessionguard/session_guard.dart):280 unauthenticated => `LoginScreen`.
- [user_auth.ts](c:/Users/ducth/kid_manager/functions/src/functions/user_auth.ts):611 `requestEmailOtp`, 650 `verifyEmailOtp`, 228 `setUserActive`.
- [firestore.rules](c:/Users/ducth/kid_manager/firestore.rules):155 users rules; `isActive` không nằm trong self-editable fields; 736/744 khóa `email_otps`/`mail_queue`.

2. **Luồng hiện tại của project**

- **Call flow đăng ký (email/password)**:  
  `SignupScreen -> AuthVM.register -> AuthRepository.register -> FirebaseAuth.createUserWithEmailAndPassword -> UserRepository.createParentIfMissing (Firestore users/families, isActive=false) -> OtpRepository.requestEmailOtp (Cloud Function requestEmailOtp) -> OtpScreen`
- **Call flow đăng nhập**:  
  `LoginScreen -> AuthVM.login -> AuthRepository.login -> FirebaseAuth.signInWithEmailAndPassword -> UserRepository.getUserById -> check isActive -> (active: vào app, inactive: chặn)`
- **Call flow verify OTP email**:  
  `OtpScreen -> OtpVM.verifyOtp -> OtpRepository.verifyEmailOtp -> Cloud Function verifyEmailOtp -> setUserActive(uid)=true (Firestore)`

**Happy path**
- Register thành công: tạo Auth user + Firestore user `isActive=false`, gửi OTP, verify đúng => Cloud Function set `isActive=true`, rồi app logout để user login lại.
- Login active account: pass check `isActive`, load profile, vào SessionGuard authenticated.
- Forgot password: request OTP reset -> verify -> reset password bằng `resetSessionToken`.

**Unhappy path**
- OTP sai: tăng `attempts`; quá 3 lần lock 10 phút (`resource-exhausted`).
- OTP hết hạn: `failed-precondition`.
- Resend quá mức: rate limit theo email/IP (5 request/10 phút), có cooldown/lock.
- Login khi `isActive=false`: bị chặn với `accountNotActivated`.

**Edge cases / trạng thái**
- Account chưa tồn tại: login fail `accountNotFound`.
- Account tồn tại + active: login bình thường.
- Account tồn tại + chưa active: bị chặn đăng nhập app chính, chỉ nên đi OTP.
- OTP đúng/sai/hết hạn: xử lý qua `verifyOtpRecord` trong Cloud Function.
- User bấm back ở OTP: trước đây quay về signup, dễ kẹt.
- App bị kill giữa chừng: FirebaseAuth có thể vẫn còn session, nhưng `watchSessionUser` trả `null` nếu chưa active nên app hiện login.

3. **Nguyên nhân bug**

- Gốc bug là **đăng ký tạo Auth account quá sớm** (trước OTP hoàn tất) + Firestore `isActive=false`.
- Khi user chưa verify OTP:
  - đăng ký lại => `email-already-in-use`;
  - login => `AuthVM.login` chặn `isActive` và **trước đây logout ngay**, làm mất session cần thiết để gọi `requestEmailOtp/verifyEmailOtp` (2 hàm này yêu cầu `request.auth.uid`).
- Kết quả: user rơi vào trạng thái account tồn tại nhưng không có lối recover rõ ràng.

4. **Các vấn đề thiết kế / code**

- **High**: Coupling giữa OTP verify và authenticated session, nhưng login inactive lại logout ngay (kẹt luồng recover).  
  [auth_vm.dart](c:/Users/ducth/kid_manager/lib/viewmodels/auth_vm.dart):62-64 (trước patch).
- **High**: `watchSessionUser` ép inactive email/password thành unauthenticated, nên route guard đẩy về login dù FirebaseAuth vẫn còn user.  
  [auth_repository.dart](c:/Users/ducth/kid_manager/lib/repositories/auth_repository.dart):45 + [session_guard.dart](c:/Users/ducth/kid_manager/lib/features/sessionguard/session_guard.dart):280.
- **Medium**: Không có flow “resume pending verification” rõ ràng ở Login/Signup.
- **Medium**: Có khả năng lệch Auth/Firestore nếu lỗi giữa chừng (Auth user có nhưng Firestore user thiếu).
- **Medium**: Không có cleanup strategy cho pending account `isActive=false` lâu ngày.

5. **Phương án sửa A (ít thay đổi codebase)**

- Giữ kiến trúc hiện tại.
- Cho account chưa active **đi tiếp OTP** từ login (không logout cưỡng bức).
- Giảm khả năng back-trap bằng điều hướng signup -> OTP theo replacement.
- Ưu điểm: ít file sửa, an toàn rollout nhanh, không đụng Cloud Functions/rules.
- Nhược điểm: vẫn tạo Auth account trước OTP, vẫn có pending account.
- Ảnh hưởng: thấp-trung bình.
- Số file: ~3-5 file Flutter.
- Rủi ro: UX pending account vẫn cần quản lý dài hạn.

6. **Phương án sửa B (tối ưu kiến trúc hơn)**

- Thiết kế “pending registration” riêng (không tạo Firebase Auth user ngay).
- OTP verify xong mới tạo Auth user + Firestore user active.
- Hoặc tạo Auth user bằng Admin SDK sau verify và trả custom token sign-in.
- Ưu điểm: sạch dữ liệu, giảm account rác, logic chuẩn hơn.
- Nhược điểm: thay đổi backend lớn (Cloud Functions, bảo mật password/pending token, migration flow).
- Ảnh hưởng: cao.
- Số file: nhiều (Flutter + Functions + có thể rules + test).
- Rủi ro: regression auth lớn nếu rollout không theo phase.

7. **Khuyến nghị nên chọn**

- Nên chọn **A ngay** để gỡ kẹt user hiện tại nhanh, an toàn.
- Song song lên roadmap **B** nếu sản phẩm cần mở rộng auth nghiêm túc và giảm pending/rác lâu dài.

8. **Kế hoạch sửa file-by-file**

- [auth_vm.dart](c:/Users/ducth/kid_manager/lib/viewmodels/auth_vm.dart):46  
  Đổi `login` để không logout khi `isActive=false`; thêm self-heal tạo user doc nếu Auth có user nhưng Firestore chưa có.
- [login_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/login_screen.dart):96  
  Nếu `accountNotActivated` thì điều hướng vào OTP verify email thay vì chỉ báo lỗi.
- [otp_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/otp_screen.dart):23  
  Thêm cờ `armCooldownOnStart` để cho flow recover vào OTP có thể resend ngay.
- [signup_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/signup_screen.dart):100  
  Đổi sang `Navigator.pushReplacement` để giảm back vào signup gây loop.

**Migration dữ liệu**
- Không bắt buộc migration ngay.
- Account cũ `isActive=false` giờ có thể recover qua login -> OTP.
- Nên cân nhắc job dọn pending account quá hạn (vd 7-30 ngày) ở phase sau.

9. **Code patch đề xuất**

Đã áp patch theo phương án A trên 4 file:
- [auth_vm.dart](c:/Users/ducth/kid_manager/lib/viewmodels/auth_vm.dart):46
- [login_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/login_screen.dart):72
- [otp_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/otp_screen.dart):18
- [signup_screen.dart](c:/Users/ducth/kid_manager/lib/views/auth/signup_screen.dart):60

Kiểm tra:
- Đã chạy `dart analyze` cho 4 file sửa; không có error, chỉ còn các `info` lint không chặn build.  
- Lưu ý worktree đang có nhiều thay đổi sẵn từ trước; mình chỉ chỉnh đúng 4 file nêu trên.

Nếu bạn muốn, mình có thể làm tiếp phase B ở mức thiết kế chi tiết Cloud Functions + contract API + rollout/migration plan theo sprint.