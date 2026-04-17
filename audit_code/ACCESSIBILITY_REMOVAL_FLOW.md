# Accessibility Removal Flow

## Mục tiêu

Tài liệu này tóm tắt:

- flow cũ khi app còn dùng `AccessibilityService`
- flow mới sau khi bỏ `Accessibility`
- những gì vẫn giữ được
- những gì thay đổi về behavior

## 1. Flow cũ dùng Accessibility

### 1.1 Setup

- Child login xong sẽ gọi `AuthRuntimeManager.start(...)`.
- `AuthRuntimeManager` lưu `user_id`, `parent_id`, `child_name` vào `SharedPreferences` qua `NativeWatcherService.saveWatcherConfig(...)`.
- Android yêu cầu user bật thêm:
  - `Usage Access`
  - tắt hạn chế pin
  - `Accessibility`

### 1.2 Runtime native

- `AppAccessibilityService` được Android giữ sống khi quyền accessibility đã bật.
- Service lắng nghe `TYPE_WINDOW_STATE_CHANGED`.
- Mỗi khi app foreground đổi:
  - lấy `packageName` app vừa mở
  - đọc rule đã sync từ Firestore
  - check app đó có đang ngoài khung giờ cho phép hay không

### 1.3 Rule sync cũ

- `FirestoreRuleSyncManager` mở listener tới:
  - `blocked_items/{childId}/apps`
  - `blocked_items/{childId}/apps/{package}/usage_rule/config`
- Rule được cache ở native memory để check rất nhanh khi app foreground đổi.

### 1.4 Hành vi cũ khi phát hiện vi phạm

- Nếu app vừa mở bị coi là vi phạm:
  - service tạo notification Firestore loại `blockedApp`
  - parent nhận cảnh báo
- Ngoài ra service còn dùng timer để định kỳ:
  - sync usage stats
  - sync heartbeat app kid

### 1.5 Điểm quan trọng

- Code cũ không thấy force-close app hay bấm Home/Back.
- Nghĩa là accessibility cũ chủ yếu làm:
  - phát hiện app foreground gần realtime
  - bắn cảnh báo vi phạm
  - giữ timer sync native

## 2. Flow mới sau khi bỏ Accessibility

### 2.1 Setup mới

- Child login xong vẫn gọi `AuthRuntimeManager.start(...)`.
- Nhưng thay vì phụ thuộc `AccessibilityService`, app chỉ còn supervision permissions chính trên Android:
  - `Usage Access`
  - tắt hạn chế pin
- Flutter onboarding và supervision gate đã bỏ step accessibility.

### 2.2 Native config mới

- `NativeWatcherService.saveWatcherConfig(...)` vẫn lưu:
  - `user_id`
  - `parent_id`
  - `child_name`
- Sau khi lưu config, Android gọi `SupervisionSyncScheduler.schedule(...)`.

### 2.3 Runtime mới

- App không còn service lắng nghe foreground event realtime.
- Thay vào đó dùng `WorkManager`:
  - `SupervisionSyncScheduler`
  - `SupervisionSyncWorker`
- Worker được chạy:
  - một job chạy ngay sau khi config được lưu
  - một job định kỳ 15 phút

### 2.4 Worker làm gì

Mỗi lần `SupervisionSyncWorker` chạy:

1. Đọc `user_id` từ `SharedPreferences`
2. Khởi tạo Firebase nếu cần
3. Gọi `UsageSyncManager.syncUsageAppsOnce(userId)`
4. Gọi `UsageSyncManager.syncInstalledAppsOnce(userId)`
5. Gọi `UsageSyncManager.syncUsageViolationsOnce(userId)`

## 3. Flow mới của từng chức năng

### 3.1 Sync usage app

Nguồn dữ liệu:

- `UsageStatsManager.queryUsageStats(...)`
- `UsageStatsManager.queryEvents(...)`

Flow:

1. Đọc danh sách app đang được quản lý trong Firestore
2. Lấy usage từ đầu ngày tới hiện tại
3. Tính:
   - `todayUsageMs` cho từng app
   - `todayTotalUsageMs`
   - `usage_daily_flat`
   - `usage_hourly`
4. Ghi lại lên `blocked_items/{childId}/...`

Kết quả:

- parent vẫn xem được số liệu usage
- thống kê usage theo ngày/giờ vẫn còn

### 3.2 Sync heartbeat app kid

Flow:

1. Worker định kỳ gọi `syncInstalledAppsOnce(userId)`
2. Native update app doc của chính app kid:
   - `kidLastSeen`
   - `kidAppRemovedAlertSent = false`

Kết quả:

- Cloud Function `detectKidAppRemoved` vẫn có dữ liệu để phát hiện app kid bị gỡ/tắt quá lâu

### 3.3 Phát hiện vi phạm rule giờ dùng app

Flow mới:

1. Worker đọc các rule usage từ Firestore
2. Dùng `UsageStatsManager.queryEvents(scanFrom, now)`
3. Lọc `MOVE_TO_FOREGROUND`
4. Với mỗi app được quản lý:
   - parse rule
   - check app có mở ngoài khung giờ cho phép hay không
5. Nếu vi phạm:
   - ghi nhận timestamp vi phạm mới nhất
   - áp cooldown để không spam
   - tạo notification Firestore

### 3.4 Loại notification mới

Trước đây:

- notification thường được tạo dưới type `blockedApp`

Bây giờ:

- worker tạo notification loại `usageLimitExceeded`
- ý nghĩa đúng hơn với behavior mới:
  - app phát hiện vi phạm
  - không claim là hệ thống đã chặn realtime

## 4. Những gì còn giữ được

- lưu context child supervision ở native
- sync usage stats lên Firestore
- sync heartbeat của app kid
- phát hiện app mở ngoài khung giờ
- parent vẫn nhận cảnh báo vi phạm
- app management vẫn có dữ liệu để hiển thị usage

## 5. Những gì thay đổi

### 5.1 Mất realtime foreground detection

Trước:

- gần như ngay khi app đổi foreground là native biết

Bây giờ:

- chỉ biết khi `WorkManager` chạy và quét lại `UsageEvents`

Hệ quả:

- cảnh báo có độ trễ
- không còn behavior "vừa mở là biết ngay"

### 5.2 Không còn mô hình phụ thuộc Accessibility

Trước:

- logic supervision phụ thuộc `AccessibilityService`

Bây giờ:

- supervision dựa trên:
  - `Usage Access`
  - `WorkManager`
  - battery optimization exemption

### 5.3 Không còn claim "auto block"

Trước:

- copy/UI dễ hiểu là app đã tự động chặn app bị cấm

Bây giờ:

- đúng bản chất hơn:
  - app ghi nhận vi phạm
  - sync usage
  - báo cho parent theo dõi

## 6. Tóm tắt ngắn

### Flow cũ

- Accessibility nghe app foreground realtime
- rule sync bằng Firestore listener
- phát hiện vi phạm ngay lúc app mở
- bắn cảnh báo cho parent
- kèm timer sync usage/heartbeat

### Flow mới

- không còn Accessibility
- child login lưu config native
- `WorkManager` chạy job supervision
- job đọc usage stats + usage events
- sync usage/heartbeat
- dò các lần mở app ngoài khung giờ
- tạo cảnh báo vi phạm cho parent

## 7. Kết luận thực tế

Refactor mới làm hệ thống hợp lệ hơn với Android/Play vì không còn dựa vào `AccessibilityService` cho parental monitoring. Đổi lại, supervision không còn realtime như trước mà chuyển sang mô hình batch scan định kỳ bằng `Usage Access + WorkManager`.

Nếu sau này muốn nâng độ mạnh của enforcement hơn nữa mà vẫn hợp lệ, cần đổi kiến trúc sản phẩm sang mô hình khác như:

- `Device Owner` / MDM
- managed device
- dedicated device mode

Các hướng đó là bài toán sản phẩm và triển khai thiết bị, không còn là app consumer thông thường trên Play nữa.
