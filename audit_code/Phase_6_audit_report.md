# Báo cáo Audit Phase 6

## Phase 6 - UI, Presentation Layer, State Management và UX Correctness

### 1. `ChildScheduleScreen` đang bootstrap session trong `build()`, dễ lặp vô hạn post-frame work và reload thừa

- Tệp: `lib/views/child/schedule/child_schedule_screen.dart:94-164`
- Tệp: `lib/views/child/schedule/child_schedule_screen.dart:193-203`
- Loại lỗi: `Bug`, `Performance`, `State Management`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `build()` đang đăng ký `WidgetsBinding.instance.addPostFrameCallback` mỗi lần rebuild.
- Mỗi callback lại gọi `_bindSessionIfNeeded()`, bên trong có read storage, load profile, reset `ScheduleViewModel`, `MemoryDayViewModel`, `BirthdayViewModel` và `loadMonth()`.
- Dù có cờ `_binding`, pattern này vẫn tạo ra post-frame task liên tục, dễ làm UI bị "tự refresh", khó debug và rất tốn tài nguyên khi screen rebuild thường xuyên.

Đoạn code lỗi:

```dart
@override
Widget build(BuildContext context) {
 ...
 WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  _bindSessionIfNeeded();
 });
 ...
}
```

Đoạn code đề xuất sửa lỗi:

```dart
@override
void initState() {
 super.initState();
 WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  unawaited(_bindSessionIfNeeded());
 });
}

@override
void didUpdateWidget(covariant ChildScheduleScreen oldWidget) {
 super.didUpdateWidget(oldWidget);
 if (oldWidget.initialDate != widget.initialDate) {
  _appliedNotificationTarget = false;
  unawaited(_bindSessionIfNeeded());
 }
}
```

---

### 2. `FamilyGroupChatScreen` đang chạy side effect trong `build()`, dễ bind/clear chat state lặp lại theo mỗi rebuild

- Tệp: `lib/views/chat/family_group_chat_screen.dart:114-156`
- Tệp: `lib/views/chat/family_group_chat_screen.dart:298-301`
- Loại lỗi: `Bug`, `Code Smell`, `State Management`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `build()` gọi trực tiếp `_syncSession(me, familyId)`.
- Hàm này có side effect: clear text, đổi session local, và schedule `postFrameCallback` để `bindFamily()` và `clearChatNotificationIfNeeded()`.
- Khi `UserVm`, locale, theme hoặc bất kỳ `InheritedWidget` nào gây rebuild, logic session này lại có thể chạy lại. Đây là anti-pattern presentation rất dễ gây race, flicker và duplicate network work.

Đoạn code lỗi:

```dart
final me = context.select<UserVm, AppUser?>((vm) => vm.me);
final vmFamilyId = context.select<UserVm, String?>((vm) => vm.familyId);
final familyId = widget.initialFamilyId ?? vmFamilyId;
_syncSession(me, familyId);
```

Đoạn code đề xuất sửa lỗi:

```dart
@override
void didChangeDependencies() {
 super.didChangeDependencies();
 final me = context.read<UserVm>().me;
 final vmFamilyId = context.read<UserVm>().familyId;
 _syncSession(me, widget.initialFamilyId ?? vmFamilyId);
}

@override
void didUpdateWidget(covariant _FamilyGroupChatBody oldWidget) {
 super.didUpdateWidget(oldWidget);
 if (oldWidget.initialFamilyId != widget.initialFamilyId ||
   oldWidget.initialComposerText != widget.initialComposerText) {
  final me = context.read<UserVm>().me;
  final vmFamilyId = context.read<UserVm>().familyId;
  _syncSession(me, widget.initialFamilyId ?? vmFamilyId);
 }
}
```

---

### 3. `NotificationScreen` force unwrap `createdAt`, có thể crash khi doc mới chưa có server timestamp

- Tệp: `lib/views/notifications/notification_screen.dart:205-220`
- Tệp: `lib/models/notifications/app_notification.dart:342-346`
- Loại lỗi: `Bug`, `Runtime Crash`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `AppNotification.createdAt` có thể `null` nếu Firestore doc vừa tạo và `serverTimestamp` chưa resolve hoặc dữ liệu lỗi.
- Tuy nhiên `NotificationScreen` lại gọi `_buildDateHeader(item.createdAt!)`.
- Chỉ cần một notification có timestamp null là màn hình notification có thể crash ngay trong lúc render list.

Đoạn code lỗi:

```dart
final item = notifications[index];
final showDateHeader =
  index == 0 ||
  !_isSameDay(
   item.createdAt,
   notifications[index - 1].createdAt,
  );

...
if (showDateHeader) ...[
 const SizedBox(height: 16),
 _buildDateHeader(item.createdAt!),
 const SizedBox(height: 12),
],
```

Đoạn code đề xuất sửa lỗi:

```dart
final item = notifications[index];
final createdAt = item.createdAt;
final previousCreatedAt =
  index > 0 ? notifications[index - 1].createdAt : null;
final showDateHeader =
  createdAt != null &&
  (index == 0 || !_isSameDay(createdAt, previousCreatedAt));

...
if (showDateHeader && createdAt != null) ...[
 const SizedBox(height: 16),
 _buildDateHeader(createdAt),
 const SizedBox(height: 12),
],
```
---

### 4. `StatisticsTab` không thay listener khi `widget.vm` đổi instance, dễ stale listener và rebuild sai nguồn state

- Tệp: `lib/views/parent/dashboard/statistics_tab.dart:181-216`
- Loại lỗi: `Bug`, `State Management`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `initState()` add listener vào `widget.vm`.
- `dispose()` remove listener, nhưng `didUpdateWidget()` không xử lý trường hợp parent rebuild với `AppManagementVM` instance mới.
- Khi VM bị thay instance, listener cũ vẫn bám vào object cũ, còn object mới thì không được subscribe. Hệ quả có thể là chart không update, duplicate callback, hoặc leak listener.

Đoạn code lỗi:

```dart
@override
void initState() {
 super.initState();

 widget.vm.addListener(_onVmChanged);
 _buildChart();
}

@override
void didUpdateWidget(covariant StatisticsTab oldWidget) {
 super.didUpdateWidget(oldWidget);

 if (_lastUsageVersion != widget.vm.usageVersion) {
  _lastUsageVersion = widget.vm.usageVersion;
  WidgetsBinding.instance.addPostFrameCallback((_) {
   _buildChart(l10n: AppLocalizations.of(context));
  });
 }
}
```

Đoạn code đề xuất sửa lỗi:

```dart
@override
void didUpdateWidget(covariant StatisticsTab oldWidget) {
 super.didUpdateWidget(oldWidget);

 if (!identical(oldWidget.vm, widget.vm)) {
  oldWidget.vm.removeListener(_onVmChanged);
  widget.vm.addListener(_onVmChanged);
 }

 if (_lastUsageVersion != widget.vm.usageVersion) {
  _lastUsageVersion = widget.vm.usageVersion;
  _buildChart(l10n: AppLocalizations.of(context));
 }
}
```

---

### 5. `ChangePasswordScreen` tạo 3 `TextEditingController` nhưng không `dispose()`

- Tệp: `lib/views/setting_pages/change_password_screen.dart:17-20`
- Tệp: `lib/views/setting_pages/change_password_screen.dart:59-186`
- Loại lỗi: `Performance`, `Lifecycle`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Screen là `StatefulWidget` và tạo 3 controller cho form đổi mật khẩu.
- File không có `dispose()`, nên khi mở/đóng screen nhiều lần các controller sẽ tồn tại đến khi GC thu hồi object state, để lại debt memory và listener lifecycle không sạch.

Đoạn code lỗi:

```dart
class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
 final _oldCtrl = TextEditingController();
 final _newCtrl = TextEditingController();
 final _confirmCtrl = TextEditingController();
 ...
}
```

Đoạn code đề xuất sửa lỗi:

```dart
@override
void dispose() {
 _oldCtrl.dispose();
 _newCtrl.dispose();
 _confirmCtrl.dispose();
 super.dispose();
}
```

---

### 6. `PhoneAuthDialog` tạo controller cục bộ không dispose và còn hardcode copy UI

- Tệp: `lib/views/auth/dialog/phone_auth_dialog.dart:35-39`
- Tệp: `lib/views/auth/dialog/phone_auth_dialog.dart:182-184`
- Tệp: `lib/views/auth/dialog/phone_auth_dialog.dart:208-237`
- Tệp: `lib/views/auth/dialog/phone_auth_dialog.dart:253-257`
- Loại lỗi: `Performance`, `Localization`, `Code Smell`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `showPhoneDialog()` tạo `phoneController`, `showOtpDialog()` tạo `otpController`, nhưng không dispose sau khi bottom-sheet/dialog đóng.
- Cùng file này hardcode nhiều string UI (`Thất bại`, `Vui lòng nhập số điện thoại`, `Đang gửi...`, hint số điện thoại, hint OTP).
- Hệ quả là leak nhỏ nhưng lặp lại mỗi lần mở dialog, đồng thời chất lượng localization không đồng nhất với phần còn lại của app.

Đoạn code lỗi:

```dart
final phoneController = TextEditingController();
...
label: Text(
 vm.isSendingOtp
   ? 'Đang gửi...'
   : l10n.phoneAuthSendOtpButton,
),
...
title: 'Thất bại',
message: 'Vui lòng nhập số điện thoại',
```

```dart
final otpController = TextEditingController();
showDialog(
 context: context,
 builder: (sheetContext) {
  ...
 },
);
```

Đoạn code đề xuất sửa lỗi:

```dart
static Future<void> showPhoneDialog(BuildContext context) async {
 final l10n = AppLocalizations.of(context);
 final phoneController = TextEditingController();

 try {
  await showModalBottomSheet(
   context: context,
   ...
  );
 } finally {
  phoneController.dispose();
 }
}

static Future<void> showOtpDialog(BuildContext context) async {
 final l10n = AppLocalizations.of(context);
 final otpController = TextEditingController();

 try {
  await showDialog(
   context: context,
   ...
  );
 } finally {
  otpController.dispose();
 }
}
```

---

## Tóm tắt rủi ro Phase 6

Những màn hình có debt presentation/state management cao nhất sau Phase 6:

1. `ChildScheduleScreen` và `FamilyGroupChatScreen` đang có side effect chạy từ `build()`.
2. `NotificationScreen` có khả năng crash khi dữ liệu Firestore chưa resolve `createdAt`.
3. `StatisticsTab` có nguy cơ stale listener nếu `vm` bị thay instance.
4. `ChangePasswordScreen` và `PhoneAuthDialog` cần dọn dẹp lifecycle controller.
5. Nhiều flow UI vẫn hardcode copy thay vì đi qua `AppLocalizations`, làm localization không nhất quán.
