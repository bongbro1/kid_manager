import 'package:flutter/material.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/storage_service.dart';

class AppInitVM extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService storage;
  final PermissionService permissionService;

  bool _ready = false;
  bool get ready => _ready;

  bool _checkingPermissions = false;
  bool _openedAccessibilitySettings = false;

  Map<String, bool> _permissions = {};
  Map<String, bool> get permissions => _permissions;

  AppInitVM(this.storage, this.permissionService) {
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> init() async {
    debugPrint('AppInitVM init');
    _setReady(true);
    Future.microtask(checkPermissions);
  }

  Future<void> checkPermissions() async {
    if (_checkingPermissions) return;
    _checkingPermissions = true;

    try {
      final results = await permissionService.checkAllPermissions();
      _permissions = results;
      debugPrint('Permissions=$_permissions');
      notifyListeners();
    } finally {
      _checkingPermissions = false;
    }
  }

  bool get hasAllPermissions => !_permissions.values.contains(false);

  List<String> get missingPermissions => _permissions.entries
      .where((entry) => !entry.value)
      .map((entry) => entry.key)
      .toList();

  Future<void> requestMissingPermissions() async {
    if (_permissions['notifications'] == false) {
      await permissionService.requestNotificationPermission();
      await checkPermissions();
    }

    if (_permissions['location'] == false) {
      await permissionService.requestForegroundLocationPermission();
      await checkPermissions();
    }

    if (_permissions['backgroundLocation'] == false) {
      await permissionService.requestBackgroundLocationPermission();
      await checkPermissions();
    }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checkingPermissions) {
      _openedAccessibilitySettings = false;
      Future.delayed(const Duration(milliseconds: 400), checkPermissions);
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
