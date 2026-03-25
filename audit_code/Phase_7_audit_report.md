# Báo cáo Audit Phase 7

## Phase 7 - Native Android/iOS, Device Permissions và Background Execution

### 1. Android build đang khai báo toàn bộ quyền giám sát nhạy cảm ở base manifest, tăng attack surface và rủi ro policy

- Tệp: `android/app/src/main/AndroidManifest.xml:4-27`
- Tệp: `android/app/src/main/AndroidManifest.xml:73-85`
- Tệp: `android/app/src/main/res/values/strings.xml:5-7`
- Loại lỗi: `Security`, `Privacy`, `Compliance`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Base manifest đang xin đồng thời `PACKAGE_USAGE_STATS`, `ACCESS_BACKGROUND_LOCATION`, `QUERY_ALL_PACKAGES`, `ACTIVITY_RECOGNITION`, `FOREGROUND_SERVICE_LOCATION` và `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
- Các quyền này phục vụ stack theo dõi trẻ em và block app, nhưng hiện đang được bind thẳng vào APK chung thay vì tách riêng cho role/build phù hợp. Cách làm này làm tăng bề mặt tấn công, tăng áp lực review store và khó kiểm soát permission creep về sau.
- `accessibility_service_desc` chỉ ghi chung chung là "Kid Manager accessibility service", không phản ánh rõ service đang quan sát app foreground và tạo event block app gửi về backend.

Đoạn code lỗi:

```xml
<uses-permission
  android:name="android.permission.PACKAGE_USAGE_STATS"
  tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" tools:ignore="QueryAllPackagesPermission" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>

<service
  android:name=".AppAccessibilityService"
  android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE"
  android:exported="true">
```

```xml
<string name="accessibility_service_desc">
  Kid Manager accessibility service
</string>
```

Đoạn code đề xuất sửa lỗi:

```xml
<!-- android/app/src/main/AndroidManifest.xml: ch? giu cac permission thuc su can cho app core -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
</manifest>
```

```xml
<!-- android/app/src/child/AndroidManifest.xml: tach rieng stack giam sat cho child build/flavor -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  xmlns:tools="http://schemas.android.com/tools">
  <uses-permission
    android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions" />
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
  <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
</manifest>
```

```xml
<string name="accessibility_service_desc">
  Monitors foreground app usage for child safety rules and sends blocked-app alerts to the guardian account.
</string>
```

---

### 2. Accessibility service đang xin quyền đọc window content và interactive windows vượt quá nhu cầu hiện tại

- Tệp: `android/app/src/main/res/xml/accessibility_config.xml:5-14`
- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:116-176`
- Loại lỗi: `Security`, `Privacy`, `Code Smell`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Logic xử lý trong `onAccessibilityEvent()` hiện chỉ cần `event.packageName` để xác định app foreground và đánh giá rule block.
- Tuy vậy config service lại bật `flagRetrieveInteractiveWindows`, `flagReportViewIds` và `canRetrieveWindowContent="true"`, nghĩa là native service được cấp quyền đọc nội dung/màn hình rộng hơn mức cần thiết.
- Đây là vi phạm nguyên tắc least privilege ở tầng native. Nếu service bị mở rộng logic trong tương lai hoặc debug log sai cách, dữ liệu UI nhạy cảm của app khác sẽ nằm trong tầm thu thập.

Đoạn code lỗi:

```xml
<accessibility-service
  android:accessibilityEventTypes="typeWindowStateChanged"
  android:accessibilityFeedbackType="feedbackGeneric"
  android:accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows"
  android:canRetrieveWindowContent="true"
  android:notificationTimeout="100"
  android:description="@string/accessibility_service_desc" />
```

```kotlin
if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

val packageName = event.packageName?.toString() ?: return
if (packageName == lastForegroundPackage) return
lastForegroundPackage = packageName
onAppChanged(packageName)
```

Đoạn code đề xuất sửa lỗi:

```xml
<accessibility-service
  xmlns:android="http://schemas.android.com/apk/res/android"
  android:accessibilityEventTypes="typeWindowStateChanged"
  android:accessibilityFeedbackType="feedbackGeneric"
  android:notificationTimeout="250"
  android:canRetrieveWindowContent="false"
  android:description="@string/accessibility_service_desc" />
```

---

### 3. Native watcher đang poll Firestore mỗi 60 giây không có backpressure, rất tốn pin và dễ tạo sync chồng chéo

- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:31-66`
- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:68-99`
- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/UsageSyncManager.kt:60-243`
- Loại lỗi: `Performance`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `usageRunnable` và `appsRunnable` đều lặp lại mỗi `60000` ms, trong khi mỗi tick lại spawn `CoroutineScope(Dispatchers.IO).launch`.
- Code không có cơ chế khóa tránh overlap. Nếu Firestore/network chậm, tick kế tiếp vẫn tiếp tục tạo sync mới, dẫn tới chồng chéo job, tăng wakeup và tốn battery.
- Bản thân comment trong code cho thấy interval cũ đã từng là 15 phút và 5 phút, nhưng đã bị đổi về 60 giây. Đây là regression performance rõ ràng ở tầng native.

Đoạn code lỗi:

```kotlin
private val usageRunnable = object : Runnable {
  override fun run() {
    val userId = getUserId()
    if (userId != null) {
      usageSyncManager?.syncUsageApps(userId)
    }
    handler.postDelayed(this, 60000)
  }
}

private val appsRunnable = object : Runnable {
  override fun run() {
    val userId = getUserId()
    if (userId != null) {
      usageSyncManager?.syncInstalledApps(userId)
    }
    handler.postDelayed(this, 60000)
  }
}
```

Đoạn code đề xuất sửa lỗi:

```kotlin
private val isUsageSyncRunning = java.util.concurrent.atomic.AtomicBoolean(false)
private val isInstallSyncRunning = java.util.concurrent.atomic.AtomicBoolean(false)

private val usageRunnable = object : Runnable {
  override fun run() {
    val userId = getUserId()
    if (userId != null && isUsageSyncRunning.compareAndSet(false, true)) {
      usageSyncManager?.syncUsageApps(userId) {
        isUsageSyncRunning.set(false)
      }
    }
    handler.postDelayed(this, 15 * 60 * 1000L)
  }
}

private val appsRunnable = object : Runnable {
  override fun run() {
    val userId = getUserId()
    if (userId != null && isInstallSyncRunning.compareAndSet(false, true)) {
      usageSyncManager?.syncInstalledApps(userId) {
        isInstallSyncRunning.set(false)
      }
    }
    handler.postDelayed(this, 6 * 60 * 60 * 1000L)
  }
}
```

---

### 4. `syncInstalledApps` có logic dead branch, hardcode package name và không bao giờ ghi đúng trạng thái đã gỡ app

- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/UsageSyncManager.kt:245-289`
- Tệp: `android/app/build.gradle.kts:25-27`
- Loại lỗi: `Bug`, `Logic`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Hàm kiểm tra `pm.getPackageInfo("com.example.kid_manager", 0)` để xem app còn installed hay không, nhưng biến `installed` sau đó không hề được dùng.
- Dù package có tồn tại hay không, code vẫn luôn ghi `kidLastSeen` và reset `kidAppRemovedAlertSent = false`. Như vậy signal "kid đã gỡ app" sẽ không bao giờ đúng.
- Package name lại đang hardcode theo `com.example.kid_manager`, tăng rủi ro sai khi đổi `applicationId` ở các môi trường khác.

Đoạn code lỗi:

```kotlin
val packageName = "com.example.kid_manager"

var installed = true

try {
  pm.getPackageInfo(packageName, 0)
} catch (e: Exception) {
  installed = false
}

val data = mapOf(
  "kidLastSeen" to FieldValue.serverTimestamp(),
  "kidAppRemovedAlertSent" to false
)
```

Đoạn code đề xuất sửa lỗi:

```kotlin
val packageName = context.packageName
val installed = try {
  pm.getPackageInfo(packageName, 0)
  true
} catch (_: Exception) {
  false
}

val data = mutableMapOf<String, Any>(
  "packageName" to packageName,
  "isInstalled" to installed,
  "installCheckAt" to FieldValue.serverTimestamp()
)

if (installed) {
  data["kidLastSeen"] = FieldValue.serverTimestamp()
  data["kidAppRemovedAlertSent"] = false
}

docRef.set(data, SetOptions.merge()).await()
```

---

### 5. `MainActivity` đang log raw notification payload và extras, dễ lộ PII/metadata vào logcat

- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/MainActivity.kt:148-164`
- Loại lỗi: `Security`, `Privacy`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Mỗi lần activity nhận `onNewIntent`, code log toàn bộ `intent.extras` và chuỗi `payload`.
- Notification payload của app này có thể chứa `receiverId`, `senderId`, `sosId`, `tripId`, tên trẻ em, tên gia đình hoặc metadata vị trí. Khi log raw như vậy, dữ liệu sẽ xuất hiện trong logcat và các crash/reporting pipeline nếu có thu thập log.
- Đây là lỗ hổng quan sát dữ liệu nhạy cảm rất phổ biến ở mobile app.

Đoạn code lỗi:

```kotlin
Log.d("NOTI_DEBUG", "onNewIntent called")
Log.d("NOTI_DEBUG", "extras=" + intent.extras)

val payload = intent.extras?.getString("payload")

Log.d("NOTI_DEBUG", "payload=$payload")
```

Đoạn code đề xuất sửa lỗi:

```kotlin
if (BuildConfig.DEBUG) {
  val keys = intent.extras?.keySet()?.joinToString(",") ?: "none"
  Log.d("NOTI_DEBUG", "onNewIntent extrasKeys=$keys")
}

val payload = intent.extras?.getString("payload")
if (payload != null) {
  MethodChannel(
    flutterEngine?.dartExecutor?.binaryMessenger
      ?: return,
    NOTIFICATION_CHANNEL
  ).invokeMethod("notificationTap", payload)
}
```

---

### 6. Native layer đang lưu `user_id`, `parent_id`, `child_name` và rule block ở dạng plaintext trong `SharedPreferences`

- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/MainActivity.kt:43-68`
- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/FirestoreRuleSyncManager.kt:164-205`
- Tệp: `android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt:196-225`
- Loại lỗi: `Security`, `Privacy`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- Native code đang cache `user_id`, `parent_id`, `child_name`, danh sách package block và rule chi tiết bằng `SharedPreferences` thông thường.
- `MODE_PRIVATE` không phải mã hóa. Trên thiết bị root/debuggable/backup sai cấu hình, đây là một điểm rò dữ liệu nhạy cảm.
- Service accessibility sau đó đọc lại các field này để tạo notification payload, nghĩa là cache native đang trở thành nguồn dữ liệu PII lâu dài mà không có rotation/TTL.

Đoạn code lỗi:

```kotlin
val prefs = getSharedPreferences("watcher_rules", MODE_PRIVATE)
prefs.edit()
  .putString("user_id", userId)
  .putString("parent_id", parentId)
  .putString("child_name", childName)
  .apply()
```

```kotlin
editor.putBoolean("${packageName}_enabled", enabled)
editor.putString("${packageName}_weekdays", weekdays.joinToString(",") { it.toString() })
editor.putString("${packageName}_windows", windowPairs.joinToString(","))
editor.putString("${packageName}_overrides", overridePairs.joinToString(","))
```

Đoạn code đề xuất sửa lỗi:

```kotlin
val masterKey = androidx.security.crypto.MasterKey.Builder(context)
  .setKeyScheme(androidx.security.crypto.MasterKey.KeyScheme.AES256_GCM)
  .build()

val securePrefs = androidx.security.crypto.EncryptedSharedPreferences.create(
  context,
  "watcher_rules_secure",
  masterKey,
  androidx.security.crypto.EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
  androidx.security.crypto.EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
)

securePrefs.edit()
  .putString("user_id", userId)
  .putString("parent_id", parentId)
  .apply()
```

---

### 7. `Info.plist` đang có permission text bị lỗi encoding và thiếu capability cần thiết cho background tracking/push ở iOS

- Tệp: `ios/Runner/Info.plist:52-59`
- Tệp: `ios/Runner/AppDelegate.swift:5-11`
- Tệp: `ios/Runner.xcodeproj/project.pbxproj:1-255`
- Loại lỗi: `Bug`, `Compliance`, `Platform`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `Info.plist` đang chứa các chuỗi tiếng Việt bị mojibake (`á»¨ng dá»¥ng...`), nghĩa là permission prompt trên iOS sẽ hiện nội dung lỗi font/encoding, gây mất tin cậy và có thể fail review về disclosure quality.
- App sử dụng `firebase_messaging` và có flow theo dõi vị trí liên tục, nhưng trong thư mục `ios/` hiện không thấy `Runner.entitlements`, `aps-environment` hay `UIBackgroundModes` cho `location`/`remote-notification`.
- Suy luận từ cấu hình hiện tại: nếu app kỳ vọng push APNs và theo dõi nền liên tục trên iOS, config native này chưa đủ để đảm bảo tính năng chạy ổn định.

Đoạn code lỗi:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>á»¨ng dá»¥ng cáº§n gá»­i thÃ´ng bÃ¡o SOS kháº©n cáº¥p.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>á»¨ng dá»¥ng cáº§n truy cáº­p vá»‹ trÃ­ Ä‘á»ƒ theo dÃµi vÃ  báº£o vá»‡ tráº».</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>á»¨ng dá»¥ng cáº§n truy cáº­p vá»‹ trÃ­ liÃªn tá»¥c Ä‘á»ƒ há»— trá»£ tÃ­nh nÄƒng an toÃ n.</string>
```

Đoạn code đề xuất sửa lỗi:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Ung dung can truy cap vi tri de hi?n thi và theo doi tre trong qua trinh di chuyen.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Ung dung can truy cap vi tri lien tuc de gui canh bao an toan và cap nhat hanh trinh ngay ca khi chay nen.</string>
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>remote-notification</string>
</array>
```

```text
Tao them file ios/Runner/Runner.entitlements voi aps-environment
và bat Push Notifications + Background Modes trong Xcode target Runner.
```

---

## Tóm tắt rủi ro Phase 7

Những điểm native cần ưu tiên xử lý sớm nhất sau Phase 7:

1. Android stack giám sát đang xin quyền rộng và accessibility surface lớn hơn nhu cầu thực tế.
2. Accessibility service đang poll Firestore mỗi phút, có nguy cơ tốn pin và tạo sync overlap trên máy trẻ em.
3. `syncInstalledApps` hiện không thể phát hiện đúng trường hợp app bị gỡ bỏ.
4. Notification payload và danh tính native đang được log/cache theo cách chưa đủ an toàn.
5. iOS chưa hoàn chỉnh permission text/capability cho push và background tracking.
