import 'package:flutter/material.dart';
import 'package:kid_manager/background/background_worker.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:workmanager/workmanager.dart';

class AppInitVM extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService storage;
  final PermissionService permissionService;

  bool _ready = false;
  bool get ready => _ready;

  bool _workersStarted = false;
  bool _checkingPermissions = false;
  bool _waitingForUsageSettings = false;

  Map<String, bool> _permissions = {};
  Map<String, bool> get permissions => _permissions;

  AppInitVM(this.storage, this.permissionService) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// 🚀 App start
  Future<void> init() async {
    debugPrint("🚀 AppInitVM init");

    /// Render UI ngay
    _setReady(true);

    /// Init background async
    Future.microtask(() async {
      await _initBackground();
    });
  }

  /// Init background logic
  Future<void> _initBackground() async {
    await checkPermissions();

    if (!hasAllPermissions) {
      debugPrint("❌ Missing permissions");
      await requestMissingPermissions();

      await checkPermissions();
      if (!hasAllPermissions) return;
    }

    final uid = storage.getString(StorageKeys.uid);
    final role = storage.getString(StorageKeys.role);

    if (uid == null || role == null) {
      debugPrint("⚠️ No login info");
      return;
    }

    await _startWorkersIfNeeded(uid, role);
  }

  /// Start workers chỉ 1 lần
  Future<void> _startWorkersIfNeeded(String uid, String role) async {
    if (_workersStarted) return;

    final registered = storage.getBool("workersRegistered") ?? false;

    if (registered) {
      debugPrint("⚙️ Workers already registered");
      _workersStarted = true;
      return;
    }

    debugPrint("⚙️ Register workers");

    await startBackgroundAppSync(uid, role);
    await startHeartbeatWorker(uid, role);

    await storage.setBool("workersRegistered", true);

    _workersStarted = true;
  }

  /// Sync installed apps worker
  Future<void> startBackgroundAppSync(String userId, String role) async {
    await Workmanager().registerOneOffTask(
      "syncAppsImmediate",
      syncAppsTask,
      inputData: {"userId": userId, "role": role},
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Workmanager().registerPeriodicTask(
      "syncAppsUnique",
      syncAppsTask,
      frequency: const Duration(minutes: 15),
      inputData: {"userId": userId, "role": role},
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Heartbeat worker
  Future<void> startHeartbeatWorker(String userId, String role) async {
    await Workmanager().registerOneOffTask(
      "heartbeatImmediate",
      deviceHeartbeatTask,
      inputData: {
        "userId": userId,
        "role": role,
        "packageName": "com.example.kid_manager",
      },
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Workmanager().registerPeriodicTask(
      "heartbeatUnique",
      deviceHeartbeatTask,
      frequency: const Duration(minutes: 15),
      inputData: {
        "userId": userId,
        "role": role,
        "packageName": "com.example.kid_manager",
      },
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  /// Permission check (song song)
  Future<void> checkPermissions() async {
    if (_checkingPermissions) return;
    _checkingPermissions = true;

    final results = await Future.wait([
      permissionService.hasMicrophonePermission(),
      permissionService.hasPhotosOrStoragePermission(),
      permissionService.hasUsagePermission(),
    ]);

    _permissions = {
      'microphone': results[0],
      'media': results[1],
      'usage': results[2],
      'accessibility': true,
    };

    debugPrint("📋 Permissions = $_permissions");

    notifyListeners();
    _checkingPermissions = false;
  }

  bool get hasAllPermissions => !_permissions.values.contains(false);

  List<String> get missingPermissions =>
      _permissions.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Request missing permissions
  Future<void> requestMissingPermissions() async {
    if (_permissions['microphone'] == false) {
      await permissionService.requestMicrophonePermission();
    }

    if (_permissions['media'] == false) {
      await permissionService.requestPhotosOrStoragePermission();
    }

    if (_permissions['usage'] == false) {
      _waitingForUsageSettings = true;
      await permissionService.openUsageAccessSettings();
      return;
    }

    if (_permissions['accessibility'] == false) {
      await permissionService.openAccessibilitySettings();
    }

    await checkPermissions();
  }

  /// Khi quay lại từ Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForUsageSettings) {
      _waitingForUsageSettings = false;
      checkPermissions();
    }
  }

  void _setReady(bool value) {
    if (_ready == value) return;
    _ready = value;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
