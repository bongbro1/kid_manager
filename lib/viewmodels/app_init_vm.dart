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

  String? _uid;
  String? get uid => _uid;
  bool _workersStarted = false;
  bool _isRequestingPermission = false;
  bool _waitingForUsageFromSettings = false;
  bool _checkingUsage = false;

  Map<String, bool> _permissions = {};
  Map<String, bool> get permissions => _permissions;

  AppInitVM(this.storage, this.permissionService) {
    WidgetsBinding.instance.addObserver(this);
    init();
  }
  Future<void> init() async {
    if (_checkingUsage) return;
    _checkingUsage = true;
    debugPrint("🚀 AppInitVM.init called");
    // STEP 1: check trước
    await checkPermissions();

    if (!hasAllPermissions) {
      await requestMissingPermissions();
      await checkPermissions();
      if (!hasAllPermissions) {
        _checkingUsage = false;
        return;
      }
    }

    debugPrint("✅ All permissions OK");

    final uid = storage.getString(StorageKeys.uid);
    final role = storage.getString(StorageKeys.role);

    if (uid == null || role == null) {
      _setReady(false);
      _checkingUsage = false;
      return;
    }

    _startWorkers(uid, role);

    _checkingUsage = false;
  }

  void _startWorkers(String uid, String role) {
    if (_workersStarted) return;

    Future.microtask(() async {
      await startBackgroundAppSync(uid, role);
      await startHeartbeatWorker(uid, role);
      _workersStarted = true;
    });
  }

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

  Future<void> startHeartbeatWorker(String userId, String role) async {
    await Workmanager().registerPeriodicTask(
      "heartbeatUnique",
      deviceHeartbeatTask,
      frequency: const Duration(minutes: 15),
      inputData: {
        "userId": userId,
        "role": role,
        "packageName": "com.example.kid_manager",
      },
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  /// 👉 Mở settings, KHÔNG check ở đây
  Future<void> openUsageSettings() async {
    if (_waitingForUsageFromSettings) return;

    _waitingForUsageFromSettings = true;

    await permissionService.openUsageAccessSettings();
  }

  /// 👉 Khi app quay lại foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForUsageFromSettings) {
      _waitingForUsageFromSettings = false;
      init();
    }
  }

  void _setReady(bool value) {
    if (_ready == value) return;
    _ready = value;
    notifyListeners();
  }

  bool get hasAllPermissions => !_permissions.values.contains(false);

  List<String> get missingPermissions {
    return _permissions.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();
  }

  Future<void> requestMissingPermissions() async {
    if (_isRequestingPermission) {
      return;
    }

    _isRequestingPermission = true;

    try {
      if (_permissions['microphone'] == false) {
        await permissionService.requestMicrophonePermission();
      }

      if (_permissions['media'] == false) {
        await permissionService.requestPhotosOrStoragePermission();
      }

      if (_permissions['usage'] == false) {
        _waitingForUsageFromSettings = true;
        await permissionService.openUsageAccessSettings();
        return;
      }

      if (_permissions['accessibility'] == false) {
        await permissionService.openAccessibilitySettings();
      }
      await checkPermissions();
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> checkPermissions() async {
    final mic = await permissionService.hasMicrophonePermission();
    final media = await permissionService.hasPhotosOrStoragePermission();
    final usage = await permissionService.hasUsagePermission();

    _permissions = {
      'microphone': mic,
      'media': media,
      'usage': usage,
      'accessibility': true,
    };

    debugPrint("📋 Updated permissions = $_permissions");
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
