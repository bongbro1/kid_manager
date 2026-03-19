import 'package:flutter/material.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/storage_service.dart';

class AppInitVM extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService storage;
  final PermissionService permissionService;

  bool _ready = false;
  bool get ready => _ready;

  bool _checkingPermissions = false;

  Map<String, bool> _permissions = {};
  Map<String, bool> get permissions => _permissions;
  bool _openedAccessibilitySettings = false;

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
  }

  /// Permission check (song song)
  Future<void> checkPermissions() async {
    if (_checkingPermissions) return;
    _checkingPermissions = true;

    final results = await permissionService.checkAllPermissions();

    _permissions = results;

    debugPrint("📋 Permissions = $_permissions");

    notifyListeners();
    _checkingPermissions = false;
  }

  bool get hasAllPermissions => !_permissions.values.contains(false);

  List<String> get missingPermissions =>
      _permissions.entries.where((e) => !e.value).map((e) => e.key).toList();

  /// Request missing permissions
  Future<void> requestMissingPermissions() async {
    if (_permissions['media'] == false) {
      await permissionService.requestPhotosOrStoragePermission();
      await checkPermissions();
    }

    if (_permissions['usage'] == false) {
      await permissionService.openUsageAccessSettings();
      return;
    }

    if (_permissions['batteryOptimizationDisabled'] == false) {
      await permissionService.openBatteryOptimizationSettings();
      return;
    }

    if (_permissions['accessibility'] == false) {
      if (!_openedAccessibilitySettings) {
        _openedAccessibilitySettings = true;

        await permissionService.openAccessibilitySettings();
      }

      return;
    }
  }

  /// Khi quay lại từ Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checkingPermissions) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _initBackground();
      });
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
