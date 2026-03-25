## Phase 1 - Kiến trúc tổng thể, bootstrap, cấu hình và dependencies

### 1. Bundle toàn bộ `.env` vào client build và hard-depend vào file ngoài source control

- File: `pubspec.yaml:114-123`
- File: `lib/main.dart:107-110`
- File: `.gitignore:20,35-39,95-97`
- Loại lỗi: `Security`, `Config`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- App đang đóng gói `.env` như một Flutter asset và load trực tiếp lúc startup.
- `.env` lại bị ignore khỏi git, nên build/runtime phụ thuộc vào một file nằm ngoài source control.
- Mẫu này có 2 rủi ro:
 - Bất kỳ secret nào được thêm vào `.env` trong tương lai sẽ bị bundle vào APK/IPA.
 - Máy build mới hoặc CI không có `.env` sẽ dễ vỡ startup/deploy theo kiểu khó tái hiện.

Đoạn code lỗi:

```yaml
# pubspec.yaml
flutter:
 assets:
  - assets/map/
  - .env
```

```dart
// lib/main.dart
await dotenv.load(fileName: '.env');

final accessToken = dotenv.env['ACCESS_TOKEN'] ?? '';
MapboxOptions.setAccessToken(accessToken);
```

Đề xuất:

- Không bundle `.env` vào client app.
- Với token public dành cho mobile, dùng `--dart-define` hoặc config platform-specific.
- Với secret thật, giữ ở backend bằng `defineSecret(...)` hoặc secure remote config.
- Thêm validation fail-fast với thông báo rõ ràng nếu token public bắt buộc bị thiếu.

Đoạn code đề xuất sửa lỗi:

```yaml
# pubspec.yaml
flutter:
 assets:
  - assets/map/
```

```dart
// lib/main.dart
const mapboxPublicToken = String.fromEnvironment('MAPBOX_PUBLIC_TOKEN');

if (mapboxPublicToken.isEmpty) {
 throw StateError('Missing MAPBOX_PUBLIC_TOKEN dart-define');
}

MapboxOptions.setAccessToken(mapboxPublicToken);
```

---

### 2. Firebase App Check đang fail-open, cho phép app tiếp tục chạy dù hardening bị lỗi

- File: `lib/main.dart:27-54`
- File: `lib/main.dart:93-96`
- File: `lib/main.dart:102-103`
- Loại lỗi: `Security`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `_activateFirebaseAppCheck()` bắt exception rồi chỉ `debugPrint(...)` và `return`.
- `main()` và background handler vẫn tiếp tục khởi động app/notification flow dù App Check activation thất bại.
- Với production build, đây là một kiểu fail-open: app tiếp tục chạy trong trạng thái hardening không được đảm bảo.

Đoạn code lỗi:

```dart
Future<void> _activateFirebaseAppCheck({required bool background}) async {
 try {
  await FirebaseAppCheck.instance.activate(
   androidProvider: kDebugMode
     ? AndroidProvider.debug
     : AndroidProvider.playIntegrity,
   appleProvider: kDebugMode
     ? AppleProvider.debug
     : AppleProvider.deviceCheck,
  );
 } catch (e) {
  debugPrint('AppCheck activation failed: $e');
  return;
 }
}
```

Đề xuất:

- Trả về `bool` hoặc ném lỗi có chủ đích.
- Ở production, nếu App Check không kích hoạt được, nên chặn các flow mạng nhạy cảm hoặc hiển thị màn startup failure rõ ràng.
- Chỉ fail-open trong debug/test nếu thật sự cần.

Đoạn code đề xuất sửa lỗi:

```dart
Future<bool> _activateFirebaseAppCheck({required bool background}) async {
 try {
  await FirebaseAppCheck.instance.activate(
   androidProvider: kDebugMode
     ? AndroidProvider.debug
     : AndroidProvider.playIntegrity,
   appleProvider: kDebugMode
     ? AppleProvider.debug
     : AppleProvider.deviceCheck,
  );
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  return true;
 } catch (e) {
  debugPrint('AppCheck activation failed: $e');
  return kDebugMode;
 }
}

final appCheckReady = await _activateFirebaseAppCheck(background: false);
if (!appCheckReady) {
 runApp(const _StartupFailureApp());
 return;
}
```

---

### 3. `SessionGuard` có thể tự khóa vĩnh viễn ở `FlashScreen` khi session fallback thiếu profile

- File: `lib/features/sessionguard/session_guard.dart:77-80`
- File: `lib/features/sessionguard/session_guard.dart:136-142`
- File: `lib/features/sessionguard/session_guard.dart:286-292`
- File: `lib/repositories/auth_repository.dart:26-48`
- Loại lỗi: `Bug`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `AuthRepository.watchSessionUser()` có fallback sang `AppUser.fromFirebase(fbUser)` khi Firestore user chưa có hoặc query lỗi.
- Session fallback này có thể thiếu `familyId`, `parentUid`, `role`.
- `SessionGuard` chỉ trigger bootstrap profile khi `status/uid` đổi, nhưng UI lại chặn vào app nếu `session.user` chưa có identity.
- Nếu lần bootstrap đầu chưa resolve được profile đầy đủ, app có thể bị kẹt ở `FlashScreen` cho tới khi logout/login lại.

Đoạn code lỗi:

```dart
final shouldTriggerMeWatch =
  status == SessionStatus.authenticated &&
  uid != null &&
  (_lastStatus != status || _lastUid != uid);

if (profile == null && !hasResolvedSessionIdentity) {
 debugPrint(
  '[SessionGuard] skip bootstrap until profile is available '
  'uid=$uid',
 );
 return;
}
```

```dart
final hasResolvedSessionIdentity =
  (session.user?.familyId?.trim().isNotEmpty ?? false) ||
  (session.user?.parentUid?.trim().isNotEmpty ?? false);

if (!hasResolvedSessionIdentity) {
 return const FlashScreen();
}
```

Đề xuất:

- Tách “auth state” khỏi “profile bootstrap state”.
- Khi `session.user` là fallback incomplete, vẫn phải có cơ chế retry bootstrap hoặc dùng `UserVm.profile` làm source of truth tạm thời.
- Không gắn bootstrap một lần duy nhất vào điều kiện `uid/status changed`.

Đoạn code đề xuất sửa lỗi:

```dart
String? _bootstrappedUid;
bool _bootstrapInFlight = false;

void _ensureSessionBootstrap(BuildContext context, String uid) {
 if (_bootstrapInFlight || _bootstrappedUid == uid) return;
 _bootstrapInFlight = true;

 WidgetsBinding.instance.addPostFrameCallback((_) async {
  try {
   final userVm = context.read<UserVm>();
   final profile = await userVm.loadProfile(uid: uid, caller: 'SessionGuard');
   if (profile != null) {
    _bootstrappedUid = uid;
   }
  } finally {
   _bootstrapInFlight = false;
  }
 });
}
```

---

### 4. State ngôn ngữ bị chia đôi giữa `MyApp` và `LocaleVm`, làm flow đổi ngôn ngữ hiện tại không đáng tin

- File: `lib/app.dart:103`
- File: `lib/app.dart:159-162`
- File: `lib/app.dart:282-288`
- File: `lib/app.dart:301-307`
- File: `lib/viewmodels/locale_vm.dart:31-47`
- File: `lib/views/setting_pages/app_appearance_screen.dart:65-76`
- Loại lỗi: `Bug`, `Logic`, `Code Smell`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `MyApp` có field `late Locale locale;` và method `updateLanguage(...)`, nhưng `MaterialApp` lại không dùng field này mà watch `LocaleVm`.
- `app_appearance_screen.dart` gọi `MyApp.of(context).updateLanguage(lang)`, nên change path hiện tại đang đi qua một state không phải source of truth thực tế.
- Đồng thời `ChangeNotifierProxyProvider.update(...)` gọi `localeVm.syncFromProfile(...)`, mà bản thân method này có `notifyListeners()` ngay trong quá trình build/update provider graph.
- Đây là dấu hiệu split-brain state và side effect trong build pipeline.

Đoạn code lỗi:

```dart
late Locale locale;

void updateLanguage(String lang) {
 setState(() {
  locale = Locale(lang);
 });
}
```

```dart
ChangeNotifierProxyProvider<UserVm, LocaleVm>(
 create: (_) => LocaleVm(_storageService),
 update: (context, userVm, localeVm) {
  localeVm ??= LocaleVm(_storageService);
  localeVm.syncFromProfile(userVm.profile?.locale);
  return localeVm;
 },
)
```

```dart
final locale = context.watch<LocaleVm>().locale;
return MaterialApp(
 locale: locale,
 ...
);
```

Đề xuất:

- Chỉ giữ một source of truth cho locale: `LocaleVm`.
- Xóa `late Locale locale` và `updateLanguage(...)` khỏi `MyApp`.
- UI settings nên gọi trực tiếp `LocaleVm.setLocaleCode(...)`.
- Tránh `notifyListeners()` từ trong `ProxyProvider.update`; thay bằng explicit state update ngoài build hoặc refactor sang provider giá trị thuần.

Đoạn code đề xuất sửa lỗi:

```dart
// lib/app.dart
class _MyAppState extends State<MyApp> {
 void updateTheme(Color color, bool dark) {
  setState(() {
   _primaryColor = color;
   _isDark = dark;
  });
 }
}
```

```dart
// lib/views/setting_pages/app_appearance_screen.dart
final localeVm = context.read<LocaleVm>();
await localeVm.setLocaleCode(lang);
```

```dart
// lib/app.dart
Provider<LocaleVm>(
 create: (_) => LocaleVm(_storageService),
)
```

---

### 5. `AppShell` dùng sai `NavigatorState` key cho notification tab

- File: `lib/widgets/app/app_shell.dart:62-65`
- File: `lib/widgets/app/app_shell.dart:91-97`
- File: `lib/widgets/app/app_shell.dart:154-156`
- Loại lỗi: `Bug`, `Logic`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Notification tab dùng `NotificationTabNavigator.key`.
- Nhưng `_onNavTap()` và `_onWillPop()` lại luôn đọc từ `_navKeys[index]`.
- Kết quả là khi đang ở notification tab, `popUntil(...)` và back handling không chạm vào navigator thật của tab này.

Đoạn code lỗi:

```dart
if (i == _index) {
 _navKeys[i].currentState?.popUntil((r) => r.isFirst);
 ...
}
```

```dart
Future<bool> _onWillPop() async {
 final nav = _navKeys[_index].currentState;
 if (nav != null && nav.canPop()) {
  nav.pop();
  return false;
 }
 return true;
}
```

```dart
return Navigator(
 key: isNotificationTab ? NotificationTabNavigator.key : _navKeys[index],
 onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => tab.root),
);
```

Đề xuất:

- Chuẩn hóa một hàm `_navigatorKeyFor(index)` và dùng nhất quán ở mọi nơi.

Đoạn code đề xuất sửa lỗi:

```dart
GlobalKey<NavigatorState> _navigatorKeyFor(int index) {
 final tab = _config.tabs[index];
 return tab.isNotificationTab ? NotificationTabNavigator.key : _navKeys[index];
}

if (i == _index) {
 _navigatorKeyFor(i).currentState?.popUntil((r) => r.isFirst);
}

Future<bool> _onWillPop() async {
 final nav = _navigatorKeyFor(_index).currentState;
 if (nav != null && nav.canPop()) {
  nav.pop();
  return false;
 }
 return true;
}
```

---

### 6. Android release đang ký bằng debug key và vẫn dùng package/namespace mẫu `com.example`

- File: `android/app/build.gradle.kts:10`
- File: `android/app/build.gradle.kts:27`
- File: `android/app/build.gradle.kts:37-42`
- Loại lỗi: `Security`, `Release Config`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- Release build hiện cấu hình `signingConfig = signingConfigs.getByName("debug")`.
- `namespace` và `applicationId` vẫn là `com.example.kid_manager`.
- Đây là blocker trực tiếp cho production hardening, update path, OAuth/social callback consistency, ký phát hành và nhận diện app.

Đoạn code lỗi:

```kotlin
android {
  namespace = "com.example.kid_manager"
  ...
  defaultConfig {
    applicationId = "com.example.kid_manager"
  }
  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("debug")
    }
  }
}
```

Đề xuất:

- Tạo signing config release riêng từ `key.properties`.
- Đổi `namespace` và `applicationId` sang package chính thức của sản phẩm.
- Không để TODO mặc định của template Flutter trong config phát hành.

Đoạn code đề xuất sửa lỗi:

```kotlin
android {
  namespace = "vn.io.homiesmart.kidmanager"

  defaultConfig {
    applicationId = "vn.io.homiesmart.kidmanager"
  }

  signingConfigs {
    create("release") {
      val props = java.util.Properties().apply {
        load(rootProject.file("key.properties").inputStream())
      }
      storeFile = file(props["storeFile"] as String)
      storePassword = props["storePassword"] as String
      keyAlias = props["keyAlias"] as String
      keyPassword = props["keyPassword"] as String
    }
  }

  buildTypes {
    release {
      signingConfig = signingConfigs.getByName("release")
      isMinifyEnabled = true
      isShrinkResources = true
    }
  }
}
```

---

### 7. AndroidManifest khai báo quá nhiều quyền nhạy cảm ở manifest chính, tạo rủi ro compliance và attack surface

- File: `android/app/src/main/AndroidManifest.xml:4-27`
- Loại lỗi: `Security`, `Compliance`, `Performance`
- Mức độ nghiêm trọng: `High`

Phân tích:

- App đang khai báo sẵn các quyền rất nhạy cảm trong manifest gốc:
 - `PACKAGE_USAGE_STATS`
 - `ACCESS_BACKGROUND_LOCATION`
 - `READ_CONTACTS`
 - `QUERY_ALL_PACKAGES`
 - `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
- Khi dồn toàn bộ vào manifest chính, mọi build variant đều mang attack surface và compliance burden như nhau.
- `QUERY_ALL_PACKAGES` và `PACKAGE_USAGE_STATS` đặc biệt nhạy với Play policy.

Đoạn code lỗi:

```xml
<uses-permission
  android:name="android.permission.PACKAGE_USAGE_STATS"
  tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES"
  tools:ignore="QueryAllPackagesPermission" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

Đề xuất:

- Tách các quyền restricted sang flavor/build variant thật sự cần.
- Chỉ giữ quyền nền tảng tối thiểu trong manifest chung.
- Bổ sung tài liệu justification theo feature và kiểm tra policy store trước khi phát hành.

Đoạn code đề xuất sửa lỗi:

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<!-- Move restricted permissions such as QUERY_ALL_PACKAGES,
   PACKAGE_USAGE_STATS and REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
   into a child-only or internal build flavor manifest. -->
```

---

### 8. `functions/src/config.ts` đang chứa secret thật trong comment source code

- File: `functions/src/config.ts:17-25`
- Loại lỗi: `Security`
- Mức độ nghiêm trọng: `Critical`

Phân tích:

- File config backend đã dùng `defineSecret("RESEND_API_KEY")`, nhưng ngay bên dưới lại để lại một API key thực trong comment.
- Dù chỉ là comment, đây vẫn là leakage trong source control nếu key còn hiệu lực.
- Đây là finding cần xử lý ngay: xóa comment và rotate secret.

Đoạn code lỗi:

```ts
export const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
export const MAIL_FROM = defineString("MAIL_FROM");

// RESEND_API_KEY=...
// MAIL_FROM=Kid Manager <no-reply@homiesmart.io.vn>
```

Đề xuất:

- Xóa comment chứa credential khỏi repo.
- Rotate `RESEND_API_KEY` ngay lập tức nếu key còn hiệu lực.
- Bổ sung pre-commit/secret scanning trong CI.

Đoạn code đề xuất sửa lỗi:

```ts
import { defineSecret, defineString } from "firebase-functions/params";

export const RESEND_API_KEY = defineSecret("RESEND_API_KEY");
export const MAIL_FROM = defineString("MAIL_FROM");
```

---

### 9. Permission strings trên iOS đang bị mojibake/encoding lỗi

- File: `ios/Runner/Info.plist:52-59`
- Loại lỗi: `Bug`, `UX`, `Compliance`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Các chuỗi mô tả quyền vị trí/notification trong `Info.plist` đang hiển thị ký tự lỗi encoding.
- Đây là vấn đề UX và có thể ảnh hưởng trực tiếp tới trust của người dùng trong permission prompt.
- Với app tracking/safety, prompt bị lỗi encoding làm giảm mạnh độ tin cậy sản phẩm.

Đoạn code lỗi:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>á»¨ng dá»¥ng cáº§n gá»­i thÃ´ng bÃ¡o SOS kháº©n cáº¥p.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>á»¨ng dá»¥ng cáº§n truy cáº­p vá»‹ trÃ­ Ä‘á»ƒ theo dÃµi vÃ  báº£o vá»‡ tráº».</string>
```

Đề xuất:

- Chuẩn hóa file sang UTF-8 sạch.
- Viết lại permission copy ngắn gọn, đúng hành vi thực tế và dễ hiểu với người dùng.

Đoạn code đề xuất sửa lỗi:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền vị trí để hiển thị vị trí và hỗ trợ bảo vệ trẻ.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Ứng dụng cần quyền vị trí nền để theo dõi an toàn và gửi cảnh báo kịp thời.</string>
```

---

### 10. Chính sách lint/analyzer quá lỏng, đang che bớt tín hiệu nợ kỹ thuật nền tảng

- File: `analysis_options.yaml:10-13`
- Loại lỗi: `Code Smell`, `Quality Gate`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Project mới chỉ dùng bộ `flutter_lints` mặc định.
- `deprecated_member_use` bị ignore toàn cục, làm giảm áp lực sửa API cũ và có thể che mất điểm gãy khi nâng Flutter/plugin.
- Với codebase có nhiều native/service/background flow, quality gate này hơi quá nhẹ.

Đoạn code lỗi:

```yaml
analyzer:
 errors:
  deprecated_member_use: ignore
include: package:flutter_lints/flutter.yaml
```

Đề xuất:

- Không ignore `deprecated_member_use` trên toàn project.
- Bật thêm các lint giúp giảm side effects và tăng tính an toàn của refactor.

Đoạn code đề xuất sửa lỗi:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
 errors:
  deprecated_member_use: warning

linter:
 rules:
  avoid_print: true
  prefer_final_fields: true
  prefer_final_locals: true
  avoid_unnecessary_containers: true
  use_build_context_synchronously: true
```

---

## Tóm tắt rủi ro Phase 1

Các vấn đề ưu tiên xử lý ngay sau Phase 1:

1. Gỡ debug signing và package id mẫu khỏi Android release config.
2. Xóa comment chứa secret trong `functions/src/config.ts` và rotate key.
3. Dừng bundle `.env` vào client app; chuyển sang cấu hình public token an toàn hơn.
4. Sửa `SessionGuard` để không tự khóa ở `FlashScreen` khi profile bootstrap chậm/lỗi.
5. Chuẩn hóa lại state ownership cho locale và navigator keys trong app shell.
