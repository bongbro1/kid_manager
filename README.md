# Flutter/Mobile Architecture & Runtime Audit

Ngày rà soát: 2026-03-21

## Phạm vi và cách đọc project

Tôi đọc project theo thứ tự:

1. Bootstrap và composition root: `lib/main.dart`, `lib/app.dart`, `lib/features/sessionguard/session_guard.dart`
2. State management và provider graph
3. Tracking/location/SOS/notification/Firebase flow
4. Các màn hình runtime chính: login, splash, parent map, child map, notification, chat
5. Android native/background code và Cloud Functions

Lưu ý:

- Tôi đã đọc code thực tế của các module chính, không review chung chung.
- `flutter analyze` không chạy xong trong thời gian cho phép, nên báo cáo này ưu tiên lỗi runtime, lỗi kiến trúc và flow có thể suy ra trực tiếp từ source.
- Repo hiện không có file rules/index Firebase được commit, nên không thể audit đầy đủ security rules từ source control.

## Góc nhìn kiến trúc tổng thể

Kiến trúc hiện tại có một số vấn đề hệ thống:

- Composition root đang nằm trong `Widget.build()` nên dependency graph không ổn định.
- State cho location của parent/guardian bị tạo ở nhiều scope khác nhau, dẫn tới cleanup và runtime behavior khó đoán.
- Flow notification/SOS bị tách ra nhiều service cùng lắng nghe `FirebaseMessaging`, nhưng navigation/tap routing chưa có một điểm điều phối duy nhất.
- Logic live-tracking, history, map overlay và SOS đang đan xen giữa ViewModel và screen, khiến side effect lan sang nhau.
- Native background sync phía Android đang khá “nặng tay”, có nguy cơ tốn pin và tạo write amplification lên Firestore.
- Chất lượng copy tiếng Việt và encoding chưa ổn; đã có string production bị mojibake.

## Các vấn đề chi tiết

### 1. Dependency graph bị tạo lại trong `build()` và phát sinh side effect trong lúc rebuild

Vị trí:

- File: `lib/app.dart`
- Class: `MyApp`
- Hàm: `build()`
- Đoạn liên quan: dòng 111-279, đặc biệt 111-135 và 254-267

[ Mức độ ]
- High

[ Vấn đề ]
- Toàn bộ service/repository graph được khởi tạo lại trong `build()`. Ngoài ra `NotificationVM.bindUser()` bị kích bằng `Future.microtask()` ngay trong `ProxyProvider.update()`.

[ Tác động ]
- Khi app rebuild do locale/theme/session/profile thay đổi, graph có thể bị lệch instance.
- Một số `ChangeNotifier` giữ dependency cũ trong khi provider ngoài đã expose dependency mới.
- Notification binding có thể bị gọi lặp ngoài ý muốn, gây listen/relisten không cần thiết.
- Kiến trúc khó bảo trì và khó debug bug kiểu “lúc được lúc không”.

[ Nguyên nhân ]
- `FirebaseAuthService`, `SecondaryAuthService`, `UserRepository`, `AuthRepository`, `AppManagementRepository`... đều được `new` trực tiếp trong `build()`.
- `NotificationVM.bindUser()` là side effect async nhưng lại được kích từ `update()` thông qua `Future.microtask`.

[ Cách sửa ]
- Dời toàn bộ composition root sang `State.initState()` hoặc một bootstrap container riêng.
- Chỉ tạo service/repository một lần cho lifecycle của app.
- Không chạy side effect async trong `ProxyProvider.update()`. Nếu cần bind theo user, dùng guard idempotent ở VM hoặc trigger từ session layer khi user thực sự đổi.

[ Mẫu code nếu cần ]
```dart
class _MyAppState extends State<MyApp> {
  late final FirebaseAuthService _authService;
  late final SecondaryAuthService _secondaryAuthService;
  late final UserRepository _userRepo;
  late final AuthRepository _authRepo;

  @override
  void initState() {
    super.initState();
    _authService = FirebaseAuthService();
    _secondaryAuthService = SecondaryAuthService();
    _userRepo = UserRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
      _secondaryAuthService,
    );
    _authRepo = AuthRepository(_authService, _userRepo);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _authService),
        Provider.value(value: _userRepo),
        Provider.value(value: _authRepo),
      ],
      child: const SessionGuard(),
    );
  }
}
```

### 2. `ParentLocationVm` bị tạo 2 lần ở 2 scope khác nhau, làm state và cleanup không đáng tin

Vị trí:

- File: `lib/app.dart`, dòng 273-277
- File: `lib/features/sessionguard/session_guard.dart`, dòng 206-236 và 246-261
- Class: `ParentLocationVm`, `_SessionGuardState`

[ Mức độ ]
- High

[ Vấn đề ]
- `ParentLocationVm` đang có một instance global ở app scope và thêm instance khác ở parent/guardian session scope.

[ Tác động ]
- Cleanup khi logout có thể dừng sai instance.
- Màn hình parent/guardian và session cleanup không chắc đang tác động lên cùng một state.
- Dễ sinh bug kiểu watcher còn chạy ngầm, marker không đồng bộ, hoặc state bị reset “không đúng chỗ”.

[ Nguyên nhân ]
- `lib/app.dart` đã provider `ParentLocationVm`.
- `SessionGuard` lại provider tiếp một `ParentLocationVm` khác cho parent/guardian.
- `_clearSessionScopedState()` dùng `context.read<ParentLocationVm>()`, nhưng scope thật sự đang dùng ở runtime trở nên mơ hồ.

[ Cách sửa ]
- Chỉ giữ một nguồn sự thật cho `ParentLocationVm`.
- Nếu state này là session-scoped thì chỉ tạo trong `SessionGuard`.
- Cleanup phải thuộc chính owner của instance đó, không đọc chéo từ scope khác.

[ Mẫu code nếu cần ]
- Không cần mẫu code dài; refactor đúng hướng là bỏ provider global ở `lib/app.dart` và để parent/guardian session tự sở hữu instance.

### 3. Tap vào push SOS gần như không làm gì

Vị trí:

- File: `lib/features/sessionguard/session_guard.dart`, dòng 198-202
- File: `lib/services/notifications/notification_service.dart`, dòng 115-118
- File: `lib/services/notifications/sos_notification_service.dart`, dòng 53-123

[ Mức độ ]
- Critical

[ Vấn đề ]
- Flow mở app từ notification SOS chưa hoàn chỉnh. `onTapSos` được khởi tạo bằng callback rỗng, còn `NotificationService.handleTap()` với type `sos` chỉ log rồi `return`.

[ Tác động ]
- User bấm notification SOS nhưng app không điều hướng tới bối cảnh SOS.
- Đây là lỗi production trực tiếp trong tình huống khẩn cấp.

[ Nguyên nhân ]
- `SessionGuard` gọi `SosNotificationService.instance.init(onTapSos: (data) {})`.
- `NotificationService` có branch `if (type == 'sos')` nhưng vẫn để `// TODO`.

[ Cách sửa ]
- Tạo một router duy nhất cho notification tap.
- Khi nhận SOS, điều hướng về màn parent map hoặc tab phù hợp, đồng thời bơm `sosFocusNotifier`/route args để camera focus đúng vị trí.
- Không được để callback rỗng trong flow production.

[ Mẫu code nếu cần ]
```dart
await SosNotificationService.instance.init(
  onTapSos: (data) {
    activeTabNotifier.value = 0;
    sosFocusNotifier.value = SosFocus(
      lat: double.tryParse(data['lat']?.toString() ?? ''),
      lng: double.tryParse(data['lng']?.toString() ?? ''),
      familyId: data['familyId']?.toString() ?? '',
      sosId: data['sosId']?.toString() ?? '',
      childUid: data['childUid']?.toString(),
    );
  },
);
```

### 4. `getInitialMessage()` đang bị xử lý hai lần

Vị trí:

- File: `lib/main.dart`, dòng 67-71
- File: `lib/services/notifications/notification_service.dart`, dòng 58-67 và 81-88

[ Mức độ ]
- High

[ Vấn đề ]
- App cold-start từ notification có thể xử lý cùng một `initialMessage` hai lần.

[ Tác động ]
- Có thể điều hướng trùng, mở trùng screen, mark-read trùng hoặc kích side effect hai lần.

[ Nguyên nhân ]
- `NotificationService.init()` đã tự gọi `FirebaseMessaging.instance.getInitialMessage()`.
- Sau đó `main.dart` lại tiếp tục gọi `NotificationService.handleInitialMessage()`.

[ Cách sửa ]
- Chỉ giữ một nơi xử lý `initialMessage`.
- Nếu vẫn cần nhiều tầng handler, phải có cờ “consumed” dùng chung.

[ Mẫu code nếu cần ]
```dart
static bool _initialMessageHandled = false;

static Future<void> handleInitialMessage() async {
  if (_initialMessageHandled) return;
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage == null) return;
  _initialMessageHandled = true;
  await handleTap(initialMessage.data);
}
```

### 5. `SosViewModel.resolve()` nuốt lỗi, khiến UI hiểu nhầm là resolve thành công

Vị trí:

- File: `lib/viewmodels/location/sos_view_model.dart`
- Hàm: `resolve()`
- Dòng 77-86
- Caller bị ảnh hưởng: `lib/widgets/sos/incoming_sos_overlay.dart`, dòng 182-217

[ Mức độ ]
- High

[ Vấn đề ]
- `resolve()` catch exception rồi chỉ set `_error`, không `rethrow` và cũng không trả kết quả thất bại.

[ Tác động ]
- `IncomingSosOverlay._handleConfirm()` đang `try/catch` theo giả định resolve sẽ throw nếu lỗi.
- Trong thực tế, overlay có thể đóng như thể đã confirm thành công dù backend resolve thất bại.
- User nhận tín hiệu sai trong lúc SOS đang active.

[ Nguyên nhân ]
- Contract giữa ViewModel và UI không nhất quán.

[ Cách sửa ]
- Hoặc `rethrow`, hoặc đổi sang `Future<bool>` trả success/failure rõ ràng.
- Overlay chỉ được coi là confirm thành công khi backend xác nhận success.

[ Mẫu code nếu cần ]
```dart
Future<void> resolve({
  required String familyId,
  required String sosId,
}) async {
  try {
    await _api.resolveSos(familyId: familyId, sosId: sosId);
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    rethrow;
  }
}
```

### 6. Login có thể crash khi profile thiếu field bắt buộc

Vị trí:

- File: `lib/views/auth/login_screen.dart`
- Hàm: login success flow
- Dòng 123-130

[ Mức độ ]
- High

[ Vấn đề ]
- Code dùng `profile.role!` và `profile.parentUid!` bằng force unwrap.

[ Tác động ]
- Nếu document user thiếu `role` hoặc `parentUid`, app crash ngay sau login.
- Đây là runtime bug thực tế khi dữ liệu Firestore không sạch hoặc migration chưa hoàn tất.

[ Nguyên nhân ]
- Ở phía trên code đã có `roleFromString(profile.role ?? 'child')`, nhưng xuống dưới lại bỏ guard và dùng `!`.

[ Cách sửa ]
- Dùng giá trị đã resolve ở trên.
- Validate `parentUid` trước khi start runtime cho child.
- Nếu thiếu dữ liệu, logout mềm hoặc show thông báo “tài khoản chưa cấu hình xong”.

[ Mẫu code nếu cần ]
```dart
final role = roleFromString(profile.role ?? 'child');
final parentId = role == UserRole.child ? (profile.parentUid ?? '').trim() : uid;

if (role == UserRole.child) {
  if (parentId.isEmpty) {
    throw StateError('Child account missing parentUid');
  }
  AuthRuntimeManager.start(
    parentId: parentId,
    displayName: profile.name,
  );
}
```

### 7. Permission onboarding có thể bị skip hoàn toàn nhưng vẫn bị đánh dấu là “đã xong”

Vị trí:

- File: `lib/features/permissions/permission_onboarding_flow.dart`, dòng 136, 219-237, 340, 353, 366, 379, 392, 405, 418
- File: `lib/views/auth/flash_screen.dart`, dòng 40-60

[ Mức độ ]
- High

[ Vấn đề ]
- User có thể bấm skip qua tất cả step, nhưng `FlashScreen` vẫn set `StorageKeys.permissionOnboardingSeenV1 = true`.

[ Tác động ]
- User sẽ không được nhắc lại onboarding nữa.
- Tracking nền, usage access, accessibility, notification có thể không hoạt động nhưng UX lại giả định là user đã hoàn tất setup.
- Đây là lỗi production nghiêm trọng với app dạng tracking.

[ Nguyên nhân ]
- `_handleSkip()` chỉ chuyển step.
- `onFinished` được gọi cả khi user skip hết.
- `FlashScreen._finishPermissionFlow()` luôn đánh dấu “seen”.

[ Cách sửa ]
- Chỉ set `permissionOnboardingSeenV1` khi đạt ngưỡng permission tối thiểu.
- Lưu trạng thái theo từng permission.
- Với quyền critical như location background / notification / usage / accessibility, cần có cơ chế nhắc lại và screen “setup chưa hoàn tất”.

[ Mẫu code nếu cần ]
- Không nên chỉ có một boolean `seen`; nên lưu object trạng thái hoặc tối thiểu là các key riêng theo permission.

### 8. Màn child detail history đang ghi đè state location live của parent

Vị trí:

- File: `lib/viewmodels/location/child_detail_map_vm.dart`, dòng 211-228
- File: `lib/viewmodels/location/parent_location_vm.dart`, dòng 203-223

[ Mức độ ]
- High

[ Vấn đề ]
- ViewModel của màn history gọi `ParentLocationVm.loadLocationHistoryByDay()`, nhưng hàm này lại cập nhật `_childrenTrails` và `_childrenLocations` của state live toàn cục.

[ Tác động ]
- Khi parent mở lịch sử của một bé, marker/vị trí hiện tại ở màn parent map có thể bị đổi thành điểm cuối của lịch sử.
- State live và state historical bị lẫn nhau, rất khó debug.

[ Nguyên nhân ]
- `loadLocationHistoryByDay()` vừa là hàm query dữ liệu, vừa mutate shared state toàn cục.

[ Cách sửa ]
- Tách query history ra khỏi state live.
- `ChildDetailMapVm` nên lấy history từ repository riêng hoặc từ method “pure” không mutate state global.

[ Mẫu code nếu cần ]
```dart
Future<List<LocationData>> getLocationHistoryByDay(
  String childUid,
  DateTime day, {
  int? fromTs,
  int? toTs,
}) async {
  final history = await _locationRepo.getLocationHistoryByDay(
    childUid,
    day,
    fromTs: fromTs,
    toTs: toTs,
  );
  return history.where(_isValidLocation).toList();
}
```

### 9. SOS của parent gần như không dùng được vì `myLocation` không được khởi động

Vị trí:

- File: `lib/viewmodels/location/parent_location_vm.dart`, dòng 77-127
- File: `lib/views/parent/location/parent_location_screen.dart`, dòng 479-489
- Kết quả search: `startMyLocation()` và `getMyLocationOnce()` không thấy được gọi ở nơi nào khác

[ Mức độ ]
- High

[ Vấn đề ]
- Nút SOS của parent phụ thuộc vào `_locationVm.myLocation`, nhưng luồng lấy location của chính parent không được start.

[ Tác động ]
- Parent bấm SOS nhưng nhiều khả năng không có gì xảy ra vì `myLocation == null`.
- UX cực tệ trong tính năng khẩn cấp.

[ Nguyên nhân ]
- `ParentLocationVm` có API `startMyLocation()`/`getMyLocationOnce()`, nhưng màn parent map không gọi.

[ Cách sửa ]
- Khi parent vào màn map, start luôn location của parent.
- Hoặc trước khi gửi SOS thì gọi `getMyLocationOnce()` nếu `myLocation` đang null.
- Nếu vẫn không lấy được vị trí thì phải show snack/error rõ ràng.

[ Mẫu code nếu cần ]
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<ParentLocationVm>().startMyLocation();
  });
}
```

### 10. `ChildLocationScreen` đang rebuild cả màn hình theo từng tick GPS

Vị trí:

- File: `lib/views/child/child_location_screen.dart`
- Hàm: `build()`
- Dòng 224-228, 260-285

[ Mức độ ]
- High

[ Vấn đề ]
- Screen dùng `context.watch<ChildLocationViewModel>()` ở mức root `build()`, trong khi map update đã làm theo listener imperative riêng.

[ Tác động ]
- Mỗi lần location đổi, cả stack UI có thể rebuild: map shell, HUD, banner, controls, SOS button.
- Tốn render không cần thiết, đặc biệt ở màn tracking chạy liên tục.

[ Nguyên nhân ]
- State live location được watch quá rộng.
- Cùng lúc đó `_vmListener` vẫn update map engine trực tiếp.

[ Cách sửa ]
- Dùng `Selector`/`context.select` cho từng phần nhỏ.
- Tách phần map imperative ra khỏi widget tree phụ thuộc vào whole VM.
- Chỉ widget nào thực sự cần `currentLocation` mới subscribe.

[ Mẫu code nếu cần ]
- Không cần mẫu code dài; đây là refactor widget tree theo hướng “small listening surfaces”.

### 11. Overlay SOS bị render/lắng nghe trùng ở child flow

Vị trí:

- File: `lib/widgets/app/app_shell.dart`, dòng 129-134
- File: `lib/views/child/child_location_screen.dart`, dòng 417-426

[ Mức độ ]
- High

[ Vấn đề ]
- `IncomingSosOverlay` đã được mount ở `AppShell`, nhưng `ChildLocationScreen` lại mount thêm một overlay nữa.

[ Tác động ]
- Duplicate Firestore listener cho cùng query SOS.
- Có nguy cơ đổ chuông hai lần, render overlay chồng nhau hoặc state resolve race nhau.

[ Nguyên nhân ]
- Cùng một responsibility nhưng bị gắn ở cả app shell và screen cụ thể.

[ Cách sửa ]
- Chỉ giữ một overlay global.
- Nếu cần layout khác nhau theo tab, truyền config xuống overlay global thay vì mount thêm instance thứ hai.

[ Mẫu code nếu cần ]
- Không cần; xóa overlay thứ hai ở `ChildLocationScreen` là bước đầu đúng nhất.

### 12. Timestamp GPS đang bị đóng dấu sai, và tần suất stream không khớp policy gửi dữ liệu

Vị trí:

- File: `lib/services/location/location_service.dart`
- Hàm: `getLocationStream()`
- Dòng 108-128

[ Mức độ ]
- High

[ Vấn đề ]
- Dữ liệu location từ plugin bị gán `timestamp: DateTime.now()` thay vì timestamp thật của location fix.
- Đồng thời `changeSettings(interval: 10000)` nhưng nhiều logic child tracking ở VM đang cố hoạt động theo nhịp dày hơn.

[ Tác động ]
- Vị trí cũ/cached fix vẫn bị hiểu là “mới”.
- Sai lệch online/offline detection, history order, ETA, safe-route và cảm nhận realtime của parent.
- Tracking logic khó tune vì tầng service và tầng VM đang nói hai ngôn ngữ thời gian khác nhau.

[ Nguyên nhân ]
- Mapping `loc.LocationData -> LocationData` đã bỏ thông tin thời điểm gốc.
- Sampling config đặt `interval: 10000` nhưng các flow phía trên kỳ vọng nhanh hơn.

[ Cách sửa ]
- Ưu tiên dùng timestamp thật từ plugin nếu có.
- Nếu plugin không có timestamp đáng tin, phải đánh dấu rõ là ingestion time và tách khỏi fix time.
- Đồng bộ sampling policy giữa `LocationServiceImpl` và `ChildLocationViewModel`.

[ Mẫu code nếu cần ]
```dart
timestamp: l.time?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
```

### 13. Family chat member stream gây N+1 Firestore reads

Vị trí:

- File: `lib/repositories/chat/family_chat_repository.dart`
- Hàm: `watchMembers()`
- Dòng 39-84, đặc biệt 50-53

[ Mức độ ]
- Medium

[ Vấn đề ]
- Mỗi snapshot của `families/{familyId}/members` lại `get()` từng user trong `users/{uid}` bằng `Future.wait`.

[ Tác động ]
- Tăng số read theo số thành viên.
- UI member list/chat info dễ chậm khi family lớn hơn.
- Read amplification và chi phí Firestore tăng không cần thiết.

[ Nguyên nhân ]
- Dữ liệu hiển thị (`displayName`, `avatarUrl`) không được denormalize hoặc cache.

[ Cách sửa ]
- Denormalize `displayName`, `avatarUrl`, `role` ngay trong doc member.
- Hoặc maintain cache users theo uid, chỉ fetch user nào chưa có.

[ Mẫu code nếu cần ]
- Không cần; đây là refactor model dữ liệu và repository.

### 14. `ZoneStatusVm` đang đọc Firestore thừa trong listener

Vị trí:

- File: `lib/viewmodels/zones/zone_status_vm.dart`
- Hàm: `_listenLastZoneEvent()`
- Dòng 219-229

[ Mức độ ]
- Medium

[ Vấn đề ]
- Trong callback của `q.snapshots()` lại gọi thêm `q.get()`.

[ Tác động ]
- Mỗi update zone lại phát sinh thêm một query Firestore.
- Tăng latency và read cost mà không mang giá trị runtime.

[ Nguyên nhân ]
- `q.get()` chỉ phục vụ debug log số lượng docs.

[ Cách sửa ]
- Bỏ hẳn `q.get()` khỏi listener.
- Nếu cần debug, log trực tiếp từ `snap.docs.length`.

[ Mẫu code nếu cần ]
- Không cần.

### 15. `StatisticsTab` leak `ScrollController` và gọi `setState()` theo scroll

Vị trí:

- File: `lib/views/parent/dashboard/statistics_tab.dart`
- `initState()`: dòng 181-193
- `dispose()`: dòng 218-221

[ Mức độ ]
- Medium

[ Vấn đề ]
- `_chartScrollController` được tạo nhưng không dispose.
- Listener scroll gọi `setState()` liên tục khi `selectedBarIndex != null`.

[ Tác động ]
- Leak controller khi mở/đóng màn nhiều lần.
- Chart có thể jank khi người dùng kéo ngang.

[ Nguyên nhân ]
- Thiếu `_chartScrollController.dispose()` trong `dispose()`.
- State tooltip được cập nhật theo từng tick scroll ở layer widget.

[ Cách sửa ]
- Dispose controller đúng chuẩn.
- Giảm số lần `setState()` bằng debounce/throttle, hoặc chuyển tooltip position sang render logic không phụ thuộc rebuild toàn widget.

[ Mẫu code nếu cần ]
```dart
@override
void dispose() {
  _chartScrollController.dispose();
  widget.vm.removeListener(_onVmChanged);
  super.dispose();
}
```

### 16. Background usage/app sync đang quá nặng, tốn pin và dễ bắn nhiều write lên Firestore

Vị trí:

- File: `android/app/src/main/kotlin/com/example/kid_manager/AccessibilityService.kt`, dòng 31-66
- File: `android/app/src/main/kotlin/com/example/kid_manager/UsageSyncManager.kt`, dòng 60-243 và 245 trở đi

[ Mức độ ]
- High

[ Vấn đề ]
- Accessibility service đang sync usage và installed apps mỗi 60 giây.
- `UsageSyncManager.syncUsageApps()` lại đọc app docs, query usage events, tính tổng, cập nhật nhiều collection/doc trong một lượt.

[ Tác động ]
- Tốn pin đáng kể nếu child device chạy nền liên tục.
- Firestore write/read amplification.
- Dễ bị hệ điều hành siết background, gây behavior không ổn định giữa các máy.

[ Nguyên nhân ]
- Polling timer cố định 60 giây không dựa trên thay đổi thực sự.
- Sync logic làm quá nhiều việc trong mỗi tick.

[ Cách sửa ]
- Chỉ sync khi có thay đổi meaningful hoặc theo batch dài hơn.
- Tách installed apps sync khỏi usage sync.
- Cân nhắc WorkManager/ForegroundService tùy use case thật sự.
- Thêm backoff, network gating và write coalescing.

[ Mẫu code nếu cần ]
- Không cần; đây là refactor native/background architecture.

### 17. Local notification chưa được initialize đầy đủ và ID notification dễ va chạm

Vị trí:

- File: `lib/services/notifications/local_notification_service.dart`
- `init()`: dòng 18-37
- `show()`: dòng 39-65

[ Mức độ ]
- High

[ Vấn đề ]
- Service chỉ tạo Android channel nhưng không gọi `_plugin.initialize(...)`.
- Notification ID dùng `millisecondsSinceEpoch ~/ 1000`, nghĩa là các notification trong cùng 1 giây có thể đè nhau.

[ Tác động ]
- Tap local notification có thể không được route chuẩn.
- Notification đến dồn trong cùng giây có thể mất cái trước.

[ Nguyên nhân ]
- Thiếu khởi tạo plugin callback.
- Chọn ID quá thô.

[ Cách sửa ]
- Initialize plugin với `onDidReceiveNotificationResponse`.
- Dùng ID unique hơn: millisecond đầy đủ hoặc sequence/hashing ổn định.

[ Mẫu code nếu cần ]
```dart
await _plugin.initialize(
  const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ),
  onDidReceiveNotificationResponse: (resp) async {
    // route payload here
  },
);

final id = DateTime.now().millisecondsSinceEpoch;
```

### 18. Search tiếng Việt bị normalize sai vì bảng thay thế đang mojibake

Vị trí:

- File: `lib/services/location/mapbox_place_search_service.dart`
- Hàm: `_normalizeForCompare()`
- Dòng 565 trở đi

[ Mức độ ]
- High

[ Vấn đề ]
- Bảng thay thế ký tự tiếng Việt đang chứa các chuỗi mojibake như `Ã `, `á»`... thay vì ký tự Unicode đúng.

[ Tác động ]
- So khớp accent-insensitive cho tiếng Việt sai lệch.
- Search/re-rank địa điểm tiếng Việt kém ổn định, dễ gây UX “gõ đúng mà kết quả ngu”.

[ Nguyên nhân ]
- File/nguồn text bị lỗi encoding hoặc copy từ nguồn đã hỏng.

[ Cách sửa ]
- Thay bằng bảng normalize Unicode đúng.
- Tốt hơn nữa là dùng thư viện/utility strip diacritics chuẩn thay vì tự duy trì bảng thủ công dài.

[ Mẫu code nếu cần ]
- Không cần; nhưng bắt buộc phải thay toàn bộ bảng ký tự hỏng bằng UTF-8 chuẩn.

### 19. Nội dung push SOS đang bị lỗi encoding ngay ở Cloud Functions

Vị trí:

- File: `functions/src/services/sosPush.ts`
- Dòng 49-55

[ Mức độ ]
- High

[ Vấn đề ]
- Title/body push SOS chứa chuỗi mojibake như `ðŸš¨ NHáº®C Láº I SOS KHáº¨N Cáº¤P`, `Má»™t thÃ nh viÃªn...`

[ Tác động ]
- User production có thể nhận notification tiếng Việt bị bể chữ.
- Trong ngữ cảnh khẩn cấp, thông điệp khó đọc là lỗi nghiêm trọng.

[ Nguyên nhân ]
- Source file hoặc luồng biên tập text không ở encoding UTF-8 chuẩn.

[ Cách sửa ]
- Sửa file sang UTF-8 chuẩn.
- Bổ sung test/snapshot cho notification copy quan trọng.

[ Mẫu code nếu cần ]
```ts
const title =
  attempt > 0 ? "🚨 NHẮC LẠI SOS KHẨN CẤP" : "🚨 SOS KHẨN CẤP";

const body =
  attempt > 0
    ? `${createdByName || "Một thành viên"} vẫn chưa được xác nhận an toàn. Chạm để xem vị trí.`
    : `${createdByName || "Một thành viên"} đang cầu cứu. Chạm để xem vị trí.`;
```

### 20. Child app seeding bị gọi lặp ở splash và sau login

Vị trí:

- File: `lib/views/auth/flash_screen.dart`, dòng 34-48, đặc biệt dòng 38
- File: `lib/views/auth/login_screen.dart`, dòng 125-130
- File: `lib/viewmodels/app_management_vm.dart`, dòng 176-203

[ Mức độ ]
- Medium

[ Vấn đề ]
- `loadAndSeedApp()` được gọi từ splash, sau đó child login flow lại gọi tiếp.

[ Tác động ]
- Quét app cài đặt/sync dữ liệu lặp.
- Tăng thời gian startup và tăng write lên Firebase không cần thiết.

[ Nguyên nhân ]
- Cùng một use case nhưng bị trigger từ hai điểm lifecycle khác nhau.

[ Cách sửa ]
- Chỉ gọi seeding sau khi session child đã ổn định.
- Thêm guard theo session/version/time window để tránh chạy lại trong khoảng ngắn.

[ Mẫu code nếu cần ]
- Không cần.

### 21. `firstWhere()` ở parent map có thể ném exception khi member list đổi giữa chừng

Vị trí:

- File: `lib/views/parent/location/parent_location_screen.dart`
- Hàm: `_openChildInfo()`
- Dòng 317-324

[ Mức độ ]
- Medium

[ Vấn đề ]
- `_userVm.locationMembers.firstWhere((c) => c.uid == childId)` không có `orElse`.

[ Tác động ]
- Nếu child vừa rời family, stream cập nhật chậm hơn click, hoặc danh sách đang refresh, screen có thể crash.

[ Nguyên nhân ]
- Hàm giả định `childId` luôn tồn tại trong collection hiện tại.

[ Cách sửa ]
- Dùng `firstWhereOrNull` hoặc `orElse`.
- Nếu child không còn tồn tại thì abort nhẹ và refresh UI.

[ Mẫu code nếu cần ]
```dart
final child = _userVm.locationMembers.cast<AppUser?>().firstWhere(
  (c) => c?.uid == childId,
  orElse: () => null,
);
if (child == null) return;
```

### 22. Copy/text tiếng Việt chưa rõ, có chỗ sai nghĩa hoặc đang là placeholder

Vị trí:

- File: `lib/l10n/app_vi.arb`
- Dòng 353: `authRememberPassword = "Lưu mật khẩu"`
- Dòng 1767: `permissionOnboardingGuideVideoPlaceholder = "Video hướng dẫn sẽ hiển thị tại đây"`
- Dòng 1802: `childLocationStayedHereLabel = "Ở đây được"`
- Dòng 2240: `safeRouteGuidanceEtaNow = "Đến ngay bây giờ"`

[ Mức độ ]
- Medium

[ Vấn đề ]
- Nhiều text chưa tự nhiên hoặc truyền sai kỳ vọng.

[ Tác động ]
- UX thiếu tin cậy, đặc biệt ở auth và tracking.
- Placeholder copy lọt ra production làm cảm giác app chưa hoàn thiện.

[ Nguyên nhân ]
- Copy chưa được review ở góc nhìn user thật.
- Có sự lệch giữa text và hành vi code thực tế.

[ Cách sửa ]
- `Lưu mật khẩu` nên đổi thành `Ghi nhớ email` nếu app chỉ nhớ email.
- Thay placeholder bằng nội dung thật hoặc ẩn hoàn toàn nếu chưa có asset.
- Viết lại các cụm tracking/safe-route theo ngữ cảnh tự nhiên hơn.

[ Mẫu code nếu cần ]
- Không cần; đây là content review bắt buộc trước production.

### 23. Nút social signup là CTA giả, nhìn bấm được nhưng không có hành vi

Vị trí:

- File: `lib/views/auth/signup_screen.dart`
- Dòng 308-318 và hàm `_socialBtn()` dòng 364-385

[ Mức độ ]
- Medium

[ Vấn đề ]
- UI render 4 nút social/mobile signup nhưng `_socialBtn()` chỉ trả về `Container`, không có `onTap`.

[ Tác động ]
- Người dùng tưởng có social signup nhưng bấm không phản hồi.
- Là lỗi UX rõ ràng trên màn đăng ký.

[ Nguyên nhân ]
- Thiết kế đã lên CTA nhưng chưa wire hành vi hoặc chưa disable state rõ ràng.

[ Cách sửa ]
- Nếu chưa support, bỏ hẳn các nút này hoặc render disabled state có nhãn “Sắp có”.
- Nếu có roadmap, bọc bằng `InkWell`/`GestureDetector` và wiring thật.

[ Mẫu code nếu cần ]
- Không cần.

### 24. Repo không commit Firebase rules/index config, chưa đủ chuẩn production

Vị trí:

- Root project
- Tìm trong repo không thấy các file như `firestore.rules`, `firestore.indexes.json`, `database.rules.json`, `storage.rules`

[ Mức độ ]
- High

[ Vấn đề ]
- Source control hiện không chứa rule/index config của Firebase.

[ Tác động ]
- Không audit được security rule thực tế.
- Deploy khó tái lập giữa môi trường.
- Với app có location, notification inbox, SOS và family data thì đây là rủi ro production lớn.

[ Nguyên nhân ]
- Firebase config đang nằm ngoài repo hoặc chưa được chuẩn hóa theo IaC/source control.

[ Cách sửa ]
- Commit đầy đủ rule/index vào repo.
- Thêm checklist CI/CD cho deploy rules, indexes, functions.
- Review lại toàn bộ quyền đọc/ghi cho `families`, `users`, `notifications`, `sos`, `locations`.

[ Mẫu code nếu cần ]
- Không cần; đây là production readiness requirement.

## Top 10 vấn đề nghiêm trọng nhất

1. `#3` Tap SOS push không điều hướng gì cả.
2. `#1` Dependency graph được tạo trong `build()` làm app state không ổn định.
3. `#2` `ParentLocationVm` bị tạo 2 lần, cleanup/watcher mơ hồ.
4. `#7` Permission onboarding có thể bị skip hết nhưng vẫn đánh dấu hoàn tất.
5. `#9` Parent SOS không có `myLocation`, tính năng khẩn cấp dễ “im lặng”.
6. `#5` `SosViewModel.resolve()` nuốt lỗi, UI hiểu sai trạng thái SOS.
7. `#6` Login có force unwrap dễ crash khi profile thiếu field.
8. `#12` Timestamp location sai và sampling policy lệch với logic tracking.
9. `#16` Android background sync mỗi phút gây rủi ro pin và Firestore cost.
10. `#24` Không có Firebase rules/index config trong repo để audit và deploy an toàn.

## Top 10 cải tiến hiệu năng nên làm trước

1. Sửa `#10`: thu hẹp vùng `watch()` ở `ChildLocationScreen`.
2. Sửa `#16`: giảm polling/background sync từ native layer.
3. Sửa `#13`: bỏ N+1 query ở `FamilyChatRepository.watchMembers()`.
4. Sửa `#14`: bỏ `q.get()` thừa trong `ZoneStatusVm`.
5. Sửa `#15`: dispose `ScrollController` và giảm `setState()` theo scroll.
6. Sửa `#20`: tránh gọi lặp `loadAndSeedApp()`.
7. Sửa `#1`: ổn định dependency graph để tránh recreate services/listeners.
8. Sửa `#11`: bỏ overlay SOS trùng để giảm stream/listener duplication.
9. Sửa `#12`: đồng bộ sampling config location với tracking policy thật.
10. Review lại các listener FCM/SOS để gom về một router chung, tránh listen chồng chéo.

## Top 10 cải tiến UX nên làm trước

1. Sửa `#3`: tap SOS notification phải mở đúng ngữ cảnh khẩn cấp.
2. Sửa `#7`: onboarding permission phải phản ánh đúng trạng thái setup.
3. Sửa `#9`: nút SOS parent phải có feedback rõ khi chưa lấy được vị trí.
4. Sửa `#22`: đổi toàn bộ copy sai nghĩa/placeholder lọt production.
5. Sửa `#23`: bỏ hoặc disable social signup chưa implement.
6. Sửa `#19`: sửa chuỗi SOS mojibake trong push.
7. Sửa `#18`: cải thiện search tiếng Việt có dấu/không dấu.
8. Với notification `zone`/`family_event`, bổ sung deep-link cụ thể thay vì chỉ đổi tab hoặc để TODO.
9. Với login remember option, đổi label thành “Ghi nhớ email” nếu không lưu password thật.
10. Bổ sung trạng thái lỗi có hướng dẫn hành động cho các flow permission, SOS và location.

## Danh sách refactor ưu tiên theo thứ tự nên xử lý

1. Ổn định composition root và provider graph (`#1`, `#2`)
2. Hợp nhất notification/SOS tap routing thành một luồng duy nhất (`#3`, `#4`, `#5`, `#11`, `#17`)
3. Tách rõ state live location khỏi state history (`#8`, `#9`, `#12`)
4. Rà soát lại permission lifecycle và gate production setup (`#7`)
5. Tối ưu child tracking screen để giảm rebuild và side effect trùng (`#10`, `#11`)
6. Tối ưu Firestore read/write patterns (`#13`, `#14`, `#20`, `#24`)
7. Refactor native background sync theo chiến lược tiết kiệm pin (`#16`)
8. Làm sạch toàn bộ localization/copy/encoding (`#18`, `#19`, `#22`, `#23`)
9. Thêm guard chống crash ở các điểm dữ liệu không sạch (`#6`, `#21`)
10. Chuẩn hóa production assets/config: Firebase rules, indexes, notification routing test, localization QA

## Kết luận ngắn

Project có nhiều feature đã lên khung khá rộng: auth, location tracking, safe route, SOS, notification, chat, app management, usage/accessibility sync. Tuy nhiên hiện tại rủi ro lớn nhất không nằm ở “thiếu tính năng”, mà nằm ở chỗ state/runtime flow chưa được gom về các ownership rõ ràng.

Nếu chỉ được chọn một nhánh việc để làm trước, tôi sẽ xử lý theo thứ tự:

1. ổn định provider graph và session-scoped state,
2. sửa toàn bộ SOS/notification open flow,
3. tách live tracking khỏi history state,
4. siết lại background sync và permission gating,
5. làm sạch copy + Firebase production config.
