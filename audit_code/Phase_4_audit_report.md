# Báo cáo Audit Phase 4

## Phase 4 - Audit Core Business Logic cho Location Tracking, Safe Route, Zones và SOS

### 1. `resolveSos` cho phép bất kỳ family member đóng SOS, kể cả child

- Tệp: `functions/src/functions/sos.ts:485-515`
- Loại lỗi: `Security`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `resolveSos` chỉ check `requireFamilyMember(familyId, uid)` mà không check role.
- Một `child` trong cùng family có thể tự resolve incident trước khi phụ huynh xác minh.

Đoạn code lỗi:

```ts
const familyId = mustString(req.data?.familyId, "familyId");
const sosId = mustString(req.data?.sosId, "sosId");

await requireFamilyMember(familyId, uid);
```

Đoạn code đề xuất sửa lỗi:

```ts
const { familyId: callerFamilyId, role } = await getUserFamilyAndRole(uid);
if (callerFamilyId !== familyId) {
 throw new HttpsError("permission-denied", "Cross-family access denied");
}
if (role !== "parent" && role !== "guardian") {
 throw new HttpsError(
  "permission-denied",
  "Only parent or guardian can resolve SOS"
 );
}
await requireFamilyMember(familyId, uid);
```

---

### 2. Mutation zone đang dùng quyền `view` thay vì quyền `manage`

- Tệp: `functions/src/functions/zones.ts:15-20`
- Tệp: `functions/src/functions/zones.ts:65-77`
- Tệp: `functions/src/functions/zones.ts:82-90`
- Tệp: `functions/src/services/locationAccess.ts:44-125`
- Tệp: `functions/src/services/child.ts:101-113`
- Loại lỗi: `Security`, `Authorization`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `upsertChildZone` và `deleteChildZone` gate bằng `requireLocationViewerAccess`, trong khi đây là mutation nhạy cảm.
- Guardian có quyền xem location sẽ mặc nhiên có thêm quyền tạo/xóa zone.
- Code còn trust `req.data?.createdAt`, cho phép client backdate dữ liệu.

Đoạn code lỗi:

```ts
const childUid = mustString(req.data?.childUid, "childUid");
await requireLocationViewerAccess(viewerUid, childUid);
...
const zone = {
 ...
 createdBy: viewerUid,
 createdAt: req.data?.createdAt ?? nowMs,
 updatedAt: nowMs,
};
```

Đoạn code đề xuất sửa lỗi:

```ts
import { requireAdultManagerOfChild } from "../services/child";

const childUid = mustString(req.data?.childUid, "childUid");
await requireAdultManagerOfChild(viewerUid, childUid);

const existingZone =
 typeof existingZones[zoneId] === "object" && existingZones[zoneId] !== null
  ? (existingZones[zoneId] as Record<string, unknown>)
  : null;

const zone = {
 name,
 type,
 lat,
 lng,
 radiusM,
 enabled,
 createdBy:
  typeof existingZone?.createdBy === "string" ? existingZone.createdBy : viewerUid,
 createdAt:
  typeof existingZone?.createdAt === "number" ? existingZone.createdAt : nowMs,
 updatedAt: nowMs,
};
```

---

### 3. Tracking heartbeat có thể báo `ok` dù không upload location thành công

- Tệp: `lib/viewmodels/location/child_location_view_model.dart:243-305`
- Tệp: `lib/viewmodels/location/child_location_view_model.dart:629-635`
- Tệp: `functions/src/functions/tracking/checkTrackingHeartbeat.ts:143-165`
- Loại lỗi: `Logic`, `Safety`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Health monitor trên client force heartbeat `ok` mỗi 60 giây chỉ dựa trên permission/service/background.
- Upload path chỉ report `ok` nếu `sentCurrentToServer` thành công.
- Scheduler backend lại xem status mới từ app là bằng chứng "còn sống", nên có thể bỏ qua `location_stale` dù dữ liệu vị trí đã ngừng cập nhật.

Đoạn code lỗi:

```dart
final shouldHeartbeatOk =
  _lastTrackingStatus != 'ok' ||
  nowMs - _lastStatusHeartbeatAtMs >= 60000;
if (shouldHeartbeatOk) {
 _lastStatusHeartbeatAtMs = nowMs;
 await _reportTrackingStatusIfChanged(
  'ok',
  message: l10n.trackingStatusOkMessage,
  force: true,
 );
}
```

```ts
const statusHeartbeatFresh =
 currentSource !== "scheduler" &&
 statusUpdatedMs != null && nowMs - statusUpdatedMs <= STALE_AFTER_MS;
```

Đoạn code đề xuất sửa lỗi:

```dart
// Health monitor ch? report cac trang thai suy giam.
if (!serviceEnabled) {
 await _reportTrackingStatusIfChanged('location_service_off', ...);
 return;
}
if (!permissionGranted || !preciseGranted) {
 await _reportTrackingStatusIfChanged('location_permission_denied', ...);
 return;
}
if (_requireBackground && !await _locationService.isBackgroundModeEnabled()) {
 await _reportTrackingStatusIfChanged('background_disabled', ...);
 return;
}
// Khong emit "ok" tai day.
```

```ts
const statusHeartbeatFresh =
 currentSource === "app" &&
 currentStatus !== "ok" &&
 statusUpdatedMs != null &&
 nowMs - statusUpdatedMs <= STALE_AFTER_MS;
```
---

### 4. Scheduler kích hoạt safe-route trip không có cơ chế claim/idempotency

- Tệp: `functions/src/triggers/safeRoute.ts:787-848`
- Loại lỗi: `Logic`, `Reliability`
- Mức độ nghiêm trọng: `High`

Phân tích:

- `activateScheduledSafeRouteTrips` đọc trip `planned`, đọc trip `active`, sau đó `set()` active trip và update template bằng các ghi riêng lẻ.
- Không có transaction hoặc activation key ổn định, nên retry/overlap invocation có thể tạo duplicate active trip cho cùng child.

Đoạn code lỗi:

```ts
const activeTrip = buildActivatedTripFromTemplate({
 template: trip,
 nowMs,
});
await db.collection("trips").doc(activeTrip.id).set(activeTrip, {
 merge: true,
});
await db.collection("trips").doc(trip.id).set(
 { lastScheduledActivationAt: nowMs },
 { merge: true }
);
```

Đoạn code đề xuất sửa lỗi:

```ts
await db.runTransaction(async (tx) => {
 const templateRef = db.collection("trips").doc(trip.id);
 const templateSnap = await tx.get(templateRef);
 const freshTrip = asTripRecord(templateSnap);
 if (!freshTrip || !isTripScheduleDue(freshTrip, nowMs)) {
  return;
 }

 const activationKey = `${trip.id}_${freshTrip.scheduledStartAt ?? nowMs}`;
 const activeRef = db.collection("trips").doc(activationKey);
 if ((await tx.get(activeRef)).exists) {
  return;
 }

 tx.set(activeRef, {
  ...buildActivatedTripFromTemplate({ template: freshTrip, nowMs }),
  id: activationKey,
 });
 tx.set(templateRef, { lastScheduledActivationAt: nowMs }, { merge: true });
});
```

---

### 5. Safe-route alert push có thể bị gửi trùng vì cooldown được update sau khi fanout

- Tệp: `functions/src/triggers/safeRoute.ts:999-1029`
- Tệp: `functions/src/triggers/safeRoute.ts:1031-1084`
- Tệp: `functions/src/triggers/safeRoute.ts:1086-1117`
- Tệp: `functions/src/triggers/safeRoute.ts:1119-1151`
- Loại lỗi: `Bug`, `Logic`
- Mức độ nghiêm trọng: `High`

Phân tích:

- Trigger `monitorSafeRouteLiveLocation` gửi `createSafeRouteAlert` và `sendSafeRouteAlertPush` trước, rồi mới cập nhật `lastDangerAlertAt`, `lastDeviationAlertAt`, ...
- Hai RTDB event đến sát nhau có thể cùng đọc một snapshot cũ và đều gửi push thành công.

Đoạn code lỗi:

```ts
if (evaluation.triggeredHazard && ...) {
 await createSafeRouteAlert(...);
 await sendSafeRouteAlertPush(...);
 updates.lastDangerAlertAt = now;
 updates.lastDangerHazardId = evaluation.triggeredHazard.id;
}
...
await tripRef.set(updates, {merge: true});
```

Đoạn code đề xuất sửa lỗi:

```ts
let shouldSendDanger = false;

await db.runTransaction(async (tx) => {
 const freshSnap = await tx.get(tripRef);
 const freshTrip = asTripRecord(freshSnap);
 if (!freshTrip || !evaluation.triggeredHazard) {
  return;
 }

 const canSend =
  (freshTrip.lastDangerAlertAt ?? 0) + SAFE_ROUTE_ALERT_COOLDOWN_MS <= now ||
  freshTrip.lastDangerHazardId !== evaluation.triggeredHazard.id;

 if (!canSend) {
  return;
 }

 tx.set(
  tripRef,
  {
   lastDangerAlertAt: now,
   lastDangerHazardId: evaluation.triggeredHazard.id,
  },
  { merge: true }
 );
 shouldSendDanger = true;
});

if (shouldSendDanger) {
 await createSafeRouteAlert(...);
 await sendSafeRouteAlertPush(...);
}
```

---

### 6. `stopWatchingChild` không cập nhật `_watchingIds`, làm `syncWatching` bỏ qua subscribe lại

- Tệp: `lib/viewmodels/location/parent_location_vm.dart:140-185`
- Loại lỗi: `Bug`, `Logic`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `syncWatching` short-circuit bằng `setEquals(newSet, _watchingIds)`.
- `stopWatchingChild` hủy stream nhưng không remove `childId` khỏi `_watchingIds`.
- Lần `syncWatching` tiếp theo với cùng list sẽ return sớm dù subscription đã mất.

Đoạn code lỗi:

```dart
Future<void> stopWatchingChild(String childId) async {
 await _subs[childId]?.cancel();
 _subs.remove(childId);
 _childrenLocations.remove(childId);
 _childrenTrails.remove(childId);
 notifyListeners();
}
```

Đoạn code đề xuất sửa lỗi:

```dart
Future<void> stopWatchingChild(String childId) async {
 await _subs[childId]?.cancel();
 _subs.remove(childId);
 _childrenLocations.remove(childId);
 _childrenTrails.remove(childId);
 _watchingIds.remove(childId);
 if (_watchingIds.isEmpty) {
  _status = LocationSharingStatus.paused;
 }
 notifyListeners();
}
```

---

### 7. `ParentZonesVm.bind` giữ stream cũ nếu bind sang child không được phép

- Tệp: `lib/viewmodels/zones/parent_zones_vm.dart:76-92`
- Loại lỗi: `Logic`, `Security`
- Mức độ nghiêm trọng: `Medium`

Phân tích:

- `bind()` check access trước, rồi mới cancel `_sub`.
- Nếu đang xem child A hợp lệ mà user chuyển sang child B không hợp lệ, `_sub` của A vẫn sống và UI có thể tiếp tục hiển thị dữ liệu cũ trong context mới.

Đoạn code lỗi:

```dart
Future<void> bind(String childUid) async {
 try {
  await _ensureCanManageChild(childUid);
  await _sub?.cancel();
  _sub = _repo.watchZones(childUid).listen((list) {
   ...
  });
 } catch (e) {
  _setError(e);
 }
}
```

Đoạn code đề xuất sửa lỗi:

```dart
Future<void> bind(String childUid) async {
 await _sub?.cancel();
 _sub = null;
 _zones = [];
 _error = null;
 notifyListeners();

 try {
  await _ensureCanManageChild(childUid);
  _sub = _repo.watchZones(childUid).listen((list) {
   _zones = list;
   _error = null;
   notifyListeners();
  }, onError: (e) {
   _setError(e);
  });
 } catch (e) {
  _zones = [];
  _setError(e);
 }
}
```

---

## Tóm tắt rủi ro Phase 4

Những ưu tiên cần xử lý trước:

1. Khóa lại authorization cho `resolveSos` và mutation zone ở backend.
2. Tách rõ "app healthy" và "location upload healthy" trong heartbeat tracking.
3. Bổ sung transaction/idempotency cho scheduler kích hoạt trip và alert fanout của safe-route.
4. Sửa các bug state-management ở `ParentLocationVm` và `ParentZonesVm` để tránh stale subscription và stale data.
