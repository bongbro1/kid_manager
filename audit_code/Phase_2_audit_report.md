## Phase 2 - Authentication, Authorization và Security Core

### 1. Callable `resetUserPassword` không kiểm tra quyền, cho phép reset mật khẩu tùy ý theo `uid`

- File: `functions/src/functions/user_auth.ts:4-40`
- File: `lib/services/firebase_auth_service.dart:25-32`
- File: `lib/viewmodels/auth_vm.dart:159-165`
- File: `lib/views/auth/reset_pass_screen.dart:75-79`
- Loại lỗi: `Security`, `Authorization`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- Backend callable `resetUserPassword` nhận `uid` và `newPassword` trực tiếp từ client rồi gọi `admin.auth().updateUser(...)`.
- Không có bất kỳ kiểm tra nào về:
 - `request.auth`
 - quyền sở hữu account
 - trạng thái OTP đã xác minh
 - vai trò được phép reset
- Vì client gọi function này sau OTP screen nhưng server không kiểm chứng bước OTP, mọi ràng buộc hiện tại chỉ là UI convention.

Đoạn code lỗi:

```ts
export const resetUserPassword = onCall(
 { region: REGION },
 async (request) => {
  const { uid, newPassword } = request.data;

  if (!uid || !newPassword) {
   throw new HttpsError("invalid-argument", "Missing uid or newPassword");
  }

  await admin.auth().updateUser(uid, {
   password: newPassword,
  });

  await admin.auth().revokeRefreshTokens(uid);
  return { success: true };
 }
);
```

Đề xuất:

- Chỉ cho reset khi server tự xác nhận OTP token hoặc reset session marker đã được ký hợp lệ.
- Không để client truyền `uid` tùy ý.
- Thêm kiểm tra password policy ở backend vì validation hiện chỉ nằm ở UI.

Đoạn code đề xuất sửa lỗi:

```ts
export const resetUserPassword = onCall({ region: REGION }, async (request) => {
 if (!request.auth?.uid) {
  throw new HttpsError("unauthenticated", "Login required");
 }

 const newPassword = String(request.data?.newPassword ?? "").trim();
 if (newPassword.length < 8) {
  throw new HttpsError("invalid-argument", "Weak password");
 }

 const resetRef = db.doc(`password_reset_sessions/${request.auth.uid}`);
 const resetSnap = await resetRef.get();
 if (!resetSnap.exists || resetSnap.data()?.verified != true) {
  throw new HttpsError("permission-denied", "OTP verification required");
 }

 await admin.auth().updateUser(request.auth.uid, { password: newPassword });
 await admin.auth().revokeRefreshTokens(request.auth.uid);
 await resetRef.delete();

 return { success: true };
});
```

---

### 2. Firestore rules cho phép người dùng tự ý leo thang quyền bằng cách sửa `role`, `parentUid`, `managedChildIds`, `familyId`

- File: `firestore.rules:127-131`
- File: `lib/repositories/user/profile_repository.dart:69-80`
- File: `lib/models/user/user_profile_patch.dart:12-17`
- File: `lib/models/user/user_profile_patch.dart:47-65`
- File: `lib/models/user/user_profile.dart:43-61`
- Loại lỗi: `Security`, `Authorization`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- Rule `allow update: if isSelf(uid)` mở hoàn toàn cho chính user sửa document của mình.
- Đồng thời model patch/profile của client vẫn hỗ trợ ghi các field nhạy cảm như:
 - `role`
 - `parentUid`
 - `managedChildIds`
 - `familyId` thông qua `UserProfile.toMap()`
- Điều này tạo đường privilege escalation trực tiếp: user có thể tự sửa vai trò thành `parent`/`guardian`, tự gắn `parentUid`, tự khai báo child assignments.

Đoạn code lỗi:

```rules
allow update: if isSelf(uid)
 || isParentManagingGuardianAssignments(uid)
 || request.resource.data.diff(resource.data)
  .changedKeys()
  .hasOnly(["isActive"]);
```

```dart
class UserProfilePatch {
 const UserProfilePatch({
  ...
  this.role,
  ...
  this.parentUid,
  ...
  this.managedChildIds,
 });
}
```

```dart
Future<void> patchUserProfile({
 required String uid,
 required UserProfilePatch patch,
}) async {
 await _users.doc(uid).set(patch.toMap(), SetOptions(merge: true));
}
```

Đề xuất:

- Firestore rules phải whitelist rõ các field self-service cho user tự sửa.
- Tách admin-only / parent-only field khỏi patch object dùng cho client profile editing.
- Không cho client-side repo public API giữ khả năng sửa role/parent/managed assignments.

Đoạn code đề xuất sửa lỗi:

```rules
function selfEditableUserFields() {
 return [
  "displayName",
  "phone",
  "gender",
  "dob",
  "dobIso",
  "dobMonth",
  "dobDay",
  "address",
  "avatarUrl",
  "coverUrl",
  "locale",
  "timezone",
  "allowTracking",
  "lastActiveAt"
 ];
}

allow update: if isSelf(uid)
 && request.resource.data.diff(resource.data).changedKeys().hasOnly(selfEditableUserFields())
 || isParentManagingGuardianAssignments(uid);
```

```dart
class UserSelfProfilePatch {
 const UserSelfProfilePatch({
  this.name,
  this.phone,
  this.gender,
  this.dob,
  this.address,
  this.allowTracking,
  this.avatarUrl,
  this.coverUrl,
  this.locale,
 });
}
```

---

### 3. Firestore rules cho phép mọi người sửa `isActive` của bất kỳ user nào, kể cả không đăng nhập

- File: `firestore.rules:127-131`
- File: `lib/viewmodels/auth_vm.dart:62-65`
- File: `lib/repositories/otp_repository.dart:219-220`
- Loại lỗi: `Security`, `Authorization`, `Logic`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- Clause cuối của `allow update` không ràng buộc `isSignedIn()`.
- Nghĩa là bất kỳ client nào có thể thử update duy nhất field `isActive` của bất kỳ `/users/{uid}` nào.
- Đây là lỗ hổng activation bypass trực tiếp, đặc biệt nguy hiểm vì logic login email/password đang dựa vào `isActive` để khóa account chưa verify.

Đoạn code lỗi:

```rules
allow update: if isSelf(uid)
 || isParentManagingGuardianAssignments(uid)
 || request.resource.data.diff(resource.data)
  .changedKeys()
  .hasOnly(["isActive"]);
```

Đề xuất:

- Xóa hoàn toàn quyền update `isActive` từ client.
- Chỉ cho backend/admin hoặc một trigger/function kiểm soát activation ghi field này.

Đoạn code đề xuất sửa lỗi:

```rules
allow update: if isSelf(uid)
 && request.resource.data.diff(resource.data).changedKeys().hasOnly(selfEditableUserFields())
 || isParentManagingGuardianAssignments(uid);
```

```dart
Future<void> _activateUser(String uid) async {
 throw UnsupportedError('Client must not activate users directly');
}
```

---

### 4. OTP flow hiện không có bí mật thực sự: `email_otps` public read/write, OTP chỉ 4 số và hash có thể brute-force offline

- File: `firestore.rules:633-637`
- File: `lib/repositories/otp_repository.dart:14-16`
- File: `lib/repositories/otp_repository.dart:53-69`
- File: `lib/repositories/otp_repository.dart:72-133`
- File: `lib/viewmodels/otp_vm.dart:94-117`
- Loại lỗi: `Security`, `Authentication`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- `email_otps/{uid}` hiện `create/get/update/delete: if true`.
- Tài liệu OTP chứa `codeHash`, `expiresAt`, `attempts`, `lockedUntil`.
- Vì OTP chỉ có 4 chữ số, `sha256(code)` trên không gian 10.000 giá trị có thể brute-force gần như tức thì nếu document đọc được.
- Sau đó attacker có thể verify OTP hoặc sửa/xóa trạng thái OTP bằng client thường, vì rules cũng mở `update/delete`.

Đoạn code lỗi:

```rules
match /email_otps/{uid} {
 allow create: if true;
 allow get: if true;
 allow update: if true;
 allow delete: if true;
}
```

```dart
static const int _maxAttempts = 3;

String _generateOtp() {
 final rnd = Random();
 return (1000 + rnd.nextInt(9000)).toString();
}
```

Đề xuất:

- Không cho client truy cập trực tiếp collection OTP.
- Chuyển create/verify/resend sang callable function backend.
- Dùng OTP dài hơn hoặc signed reset token ngắn hạn; tối thiểu không để hash public.

Đoạn code đề xuất sửa lỗi:

```rules
match /email_otps/{uid} {
 allow read, write: if false;
}
```

```ts
export const verifyEmailOtp = onCall({ region: REGION }, async (request) => {
 if (!request.auth?.uid) {
  throw new HttpsError("unauthenticated", "Login required");
 }
 // Read OTP server-side, compare, mutate attempts/lock state server-side only.
});
```

---

### 5. `mail_queue` public create cho phép spam mail job và giả mạo yêu cầu email

- File: `firestore.rules:644-645`
- File: `lib/repositories/otp_repository.dart:223-236`
- Loại lỗi: `Security`, `Abuse`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Collection `mail_queue` đang cho `allow create: if true`.
- Client hiện đẩy thẳng `{to, uid, code, type}` vào queue.
- Điều này mở đường cho:
 - spam queue
 - giả email reset/verify
 - đốt quota gửi mail và làm bẩn hệ thống notification/email

Đoạn code lỗi:

```rules
match /mail_queue/{docId} {
 allow create: if true;
}
```

```dart
await _db.collection("mail_queue").add({
 "to": email,
 "uid": uid,
 "code": code,
 "type": type.value,
 "createdAt": FieldValue.serverTimestamp(),
 "status": "pending",
});
```

Đề xuất:

- Client không được write trực tiếp vào mail queue.
- Queue phải chỉ được tạo bởi Cloud Function/backend.
- Nếu vẫn cần client trigger, dùng callable function có rate limiting và validation.

Đoạn code đề xuất sửa lỗi:

```rules
match /mail_queue/{docId} {
 allow read, write: if false;
}
```

```ts
await db.collection("mail_queue").add({
 to: normalizedEmail,
 uid,
 template: "reset_password",
 createdAt: admin.firestore.FieldValue.serverTimestamp(),
 status: "pending",
});
```

---

### 6. `reset password` và `forgot password` hiện cho phép user enumeration quá dễ

- File: `lib/viewmodels/auth_vm.dart:106-123`
- File: `lib/repositories/user/profile_repository.dart:91-103`
- File: `firestore.rules:115`
- Loại lỗi: `Security`, `Privacy`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `forgotPassword()` query trực tiếp `users` theo email và trả lỗi riêng `emailNotRegistered`.
- Đồng thời rules lại cho `allow list: if isSignedIn() || request.query.limit <= 1;`.
- Vì query này dùng `limit(1)`, một client không đăng nhập vẫn có thể dùng pattern này để dò email tồn tại trong hệ thống.

Đoạn code lỗi:

```dart
final user = await _userRepo.getUserByEmail(email);

if (user == null) {
 throw Exception("emailNotRegistered");
}
```

```rules
allow list: if isSignedIn() || request.query.limit <= 1;
```

Đề xuất:

- Không query user-by-email trực tiếp từ client.
- Dùng callable function server-side nhận email và luôn trả generic response kiểu “Nếu email tồn tại, chúng tôi đã gửi hướng dẫn”.
- Khóa hẳn list users khỏi unauthenticated client.

Đoạn code đề xuất sửa lỗi:

```rules
allow list: if false;
```

```dart
Future<void> forgotPassword(String email) async {
 await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
   .httpsCallable('requestPasswordReset')
   .call({'email': email.trim()});
}
```

---

### 7. Backend location authorization rộng hơn client policy: guardian có thể xem mọi child cùng family, không chỉ child được assign

- File: `functions/src/services/locationAccess.ts:108-116`
- File: `functions/src/services/locationAccess.ts:147-172`
- File: `functions/src/functions/locations.ts:45-53`
- File: `lib/services/access_control/access_control_service.dart:73-92`
- Loại lỗi: `Security`, `Authorization Drift`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Client policy `AccessControlService.canAccessChild(...)` yêu cầu guardian phải có `managedChildIds`.
- Nhưng backend `requireLocationViewerAccess(...)` chỉ kiểm tra:
 - viewer là `parent` hoặc `guardian`
 - viewer và target cùng `familyId`
 - target trackable
- Không có bước nào kiểm tra guardian được assign child đó.
- Vì locations/zones functions đều gọi service này, guardian có thể đọc location/history/zones của mọi child trong family nếu gọi backend trực tiếp.

Đoạn code lỗi:

```ts
if (viewerRole !== "parent" && viewerRole !== "guardian") {
 throw new HttpsError("permission-denied", "Only parent or guardian can view location");
}

if (!targetTrackable) {
 throw new HttpsError("permission-denied", "Target is not available for location tracking");
}

return {
 viewerUid,
 viewerRole,
 viewerFamilyId,
 targetUid,
 targetRole,
 targetFamilyId,
 targetAllowTracking,
};
```

Đề xuất:

- Đồng bộ backend policy với `managedChildIds` hoặc một nguồn assignment server-side duy nhất.
- Không dựa vào client-side filtering cho authorization thực.

Đoạn code đề xuất sửa lỗi:

```ts
if (viewerRole === "guardian") {
 const assigned = Array.isArray(viewer.managedChildIds) ? viewer.managedChildIds : [];
 const normalizedAssigned = assigned
  .map((item) => String(item).trim())
  .filter(Boolean);

 if (!normalizedAssigned.includes(targetUid)) {
  throw new HttpsError("permission-denied", "Guardian is not assigned to this child");
 }

 if (String(target.parentUid ?? "").trim() !== viewerUidParent) {
  throw new HttpsError("permission-denied", "Target does not belong to guardian owner parent");
 }
}
```

---

### 8. RTDB rules không hỗ trợ `guardian`, mâu thuẫn trực tiếp với mô hình quyền hiện tại

- File: `database.rules.json:9-30`
- File: `functions/src/services/locationAccess.ts:108-116`
- File: `lib/services/access_control/access_control_service.dart:73-92`
- Loại lỗi: `Logic`, `Authorization Drift`
- Mức độ nghiêm trọng: `High`

Phân tích:

- RTDB rules chỉ cho child tự đọc hoặc parent đọc thông qua `meta.parentUid == auth.uid`.
- Không có nhánh nào cho guardian.
- Trong khi client policy và backend functions đều coi guardian là location viewer hợp lệ.
- Kết quả là hệ thống authz hiện đang chia ba:
 - client: guardian có điều kiện
 - backend functions: guardian quá rộng
 - RTDB rules: guardian bị deny hoàn toàn

Đoạn code lỗi:

```json
".read": "auth != null && (auth.uid === $childUid || root.child('locations').child($childUid).child('meta').child('parentUid').val() === auth.uid)"
```

Đề xuất:

- Chọn một canonical ownership model cho guardian.
- Nếu guardian được phép, RTDB rules phải đọc từ `users/{auth.uid}` hoặc materialized access map để công nhận guardian cùng parent owner.

Đoạn code đề xuất sửa lỗi:

```json
".read": "auth != null && (auth.uid === $childUid || root.child('locations').child($childUid).child('meta').child('parentUid').val() === auth.uid || (root.child('users').child(auth.uid).child('role').val() === 'guardian' && root.child('users').child(auth.uid).child('parentUid').val() === root.child('locations').child($childUid).child('meta').child('parentUid').val()))"
```

Lưu ý:

- Nếu dùng RTDB cho access control, cần materialize metadata tối thiểu để tránh phụ thuộc chéo nguy hiểm giữa Firestore và RTDB.

---

### 9. Social login hiện bypass hoàn toàn gate `isActive`, khiến luồng verify email không còn là enforcement thực

- File: `lib/viewmodels/auth_vm.dart:46-72`
- File: `lib/viewmodels/auth_vm.dart:272-299`
- File: `lib/viewmodels/auth_vm.dart:368-392`
- File: `lib/repositories/user/family_repository.dart:70-90`
- Loại lỗi: `Security`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Login email/password chặn account chưa active:

```dart
if (userInfo.isActive != true) {
 await _authRepo.logout();
 throw Exception("accountNotActivated");
}
```

- Nhưng social login đi qua `_handleUser(...)`, nếu chưa có user doc thì gọi `createParentIfMissing(...)`.
- Doc parent mới được tạo với `'isActive': false`, nhưng không có bước nào chặn session social login tiếp tục dùng app.
- Tức là verify/activation chỉ áp dụng với email-password flow, không phải enforcement toàn hệ thống.

Đoạn code lỗi:

```dart
final user = await _authRepo.signInWithGoogle();
await _handleUser(user);
```

```dart
if (existingUser == null) {
 await _userRepo.createParentIfMissing(
  uid: user.uid,
  email: user.email ?? '',
  displayName: user.displayName,
  locale: user.locale ?? 'vi',
  timezone: user.timezone ?? 'Asia/Ho_Chi_Minh',
 );
 currentUser = await _authRepo.getUser(user.uid);
}
```

```dart
'isActive': false,
```

Đề xuất:

- Quyết định rõ social login có cần activation hay không.
- Nếu không cần activation, tạo doc social user với `isActive: true`.
- Nếu cần activation, phải chặn session sau social login tương tự email/password.

Đoạn code đề xuất sửa lỗi:

```dart
if (existingUser == null) {
 await _userRepo.createParentIfMissing(
  uid: user.uid,
  email: user.email ?? '',
  displayName: user.displayName,
  locale: user.locale ?? 'vi',
  timezone: user.timezone ?? 'Asia/Ho_Chi_Minh',
  isActive: true,
 );
}

currentUser = await _authRepo.getUser(user.uid);
if (currentUser?.isActive != true) {
 await _authRepo.logout();
 _setError(runtimeL10n().accountNotActivated);
 return;
}
```

---

### 10. Firestore family membership rules mở quá rộng, cho phép signed-in user tạo/sửa membership metadata tùy ý

- File: `firestore.rules:171-181`
- Loại lỗi: `Security`, `Authorization`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `families/{familyId}/members/{memberId}` đang:
 - `allow create: if isSignedIn();`
 - `allow update: if isSignedIn();`
- Điều này có nghĩa là chỉ cần đăng nhập là có thể chèn/sửa member docs của family bất kỳ nếu biết path.
- Vì nhiều nhánh rule khác dựa trên `isFamilyMember(familyId)`, đây là một điểm trust rất nguy hiểm.

Đoạn code lỗi:

```rules
match /members/{memberId} {
 allow read: if isFamilyMember(familyId);
 allow create: if isSignedIn();
 allow update: if isSignedIn();
 allow delete: if false;
}
```

Đề xuất:

- Chỉ backend hoặc parent owner mới được tạo membership.
- User thường không được update arbitrary family member metadata.
- Nếu cần self metadata, whitelist field rất chặt.

Đoạn code đề xuất sửa lỗi:

```rules
match /members/{memberId} {
 allow read: if isFamilyMember(familyId);
 allow create, delete: if false;
 allow update: if false;
}
```

---

### 11. Storage rules làm lộ toàn bộ user media cho bất kỳ người dùng đã đăng nhập

- File: `storage.rules:18-24`
- Loại lỗi: `Security`, `Privacy`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `match /users/{uid}/{allPaths=**}` hiện `allow read: if isSignedIn();`
- Điều này cho phép bất kỳ user đăng nhập nào đọc avatar/cover/private images của mọi user khác nếu biết path.
- Với app có dữ liệu trẻ em/family, đây là privacy leak không chấp nhận được.

Đoạn code lỗi:

```rules
match /users/{uid}/{allPaths=**} {
 allow read: if isSignedIn();
 allow write: if isSelf(uid)
  && request.resource != null
  && request.resource.size < 10 * 1024 * 1024
  && request.resource.contentType.matches('image/.*');
}
```

Đề xuất:

- Chỉ cho self đọc, hoặc chỉ public avatar path mới cho family/public read có kiểm soát.
- Tách avatar công khai và file riêng tư thành path khác nhau.

Đoạn code đề xuất sửa lỗi:

```rules
match /users/{uid}/{allPaths=**} {
 allow read: if isSelf(uid);
 allow write: if isSelf(uid)
  && request.resource != null
  && request.resource.size < 10 * 1024 * 1024
  && request.resource.contentType.matches('image/.*');
}
```

---

## Tóm tắt rủi ro Phase 2

Các vấn đề ưu tiên xử lý ngay sau Phase 2:

1. Khóa ngay callable `resetUserPassword` và chuyển OTP/reset sang server-verified flow.
2. Đóng toàn bộ quyền public của `email_otps` và `mail_queue`.
3. Siết `firestore.rules` cho `/users` và `/families/*/members`.
4. Đồng bộ authorization của guardian giữa client, Cloud Functions và RTDB.
5. Quyết định lại semantics của `isActive` cho social login và activation flow.
