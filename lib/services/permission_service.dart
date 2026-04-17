import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/background/native_watcher_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

class PermissionService {
  static const List<String> appEntryPermissionKeys = <String>[
    'notifications',
    'location',
    'backgroundLocation',
    'media',
  ];

  static const List<String> supervisionPermissionKeys = <String>[
    'usage',
    'batteryOptimizationDisabled',
  ];

  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestNotificationPermission() async {
    return Permission.notification.request();
  }

  Future<void> openNotificationSettings() async {
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<bool> hasForegroundLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestForegroundLocationPermission() async {
    return Permission.locationWhenInUse.request();
  }

  Future<bool> hasBackgroundLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt < 29) {
        return hasForegroundLocationPermission();
      }
    }

    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  Future<PermissionStatus> requestBackgroundLocationPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionStatus.granted;
    }

    if (Platform.isAndroid) {
      final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdkInt < 29) {
        return requestForegroundLocationPermission();
      }
    }

    final foregroundGranted = await hasForegroundLocationPermission();
    if (!foregroundGranted) {
      return PermissionStatus.denied;
    }

    return Permission.locationAlways.request();
  }

  Future<void> openLocationSettings() async {
    await openAppSettings();
  }

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }

  Future<bool> hasPhotosOrStoragePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted || status.isLimited;
    }

    final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.photos.status;
      return status.isGranted;
    }

    final status = await Permission.storage.status;
    return status.isGranted;
  }

  Future<bool> requestPhotosOrStoragePermission() async {
    debugPrint('requestPhotosOrStoragePermission()');

    PermissionStatus status;

    if (Platform.isAndroid) {
      if (await _isAndroid13OrAbove()) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    debugPrint('requestPhotosOrStoragePermission result=$status');
    return status.isGranted || status.isLimited;
  }

  Future<bool> _isAndroid13OrAbove() async {
    final sdk = await DeviceInfoPlugin().androidInfo;
    return sdk.version.sdkInt >= 33;
  }

  bool hasInternetByManifest() => true;

  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
    );
    await intent.launch();
  }

  Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final granted = await UsageStats.checkUsagePermission();
      debugPrint('checkUsagePermission=$granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('Usage permission error: $e');
      return false;
    }
  }

  Future<void> openBatteryOptimizationSettings() async {
    await NativeWatcherService.requestIgnoreBatteryOptimizations();
  }

  Future<bool> hasBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;

    try {
      final disabled =
          await NativeWatcherService.isIgnoringBatteryOptimizations();
      debugPrint('Battery optimization disabled=$disabled');
      return disabled;
    } catch (e) {
      debugPrint('Battery optimization check error: $e');
      return false;
    }
  }

  Future<Map<String, bool>> checkAllPermissions({
    bool includeSupervisionPermissions = true,
  }) async {
    final location = await hasForegroundLocationPermission();
    final notifications = await hasNotificationPermission();
    final backgroundLocation = await hasBackgroundLocationPermission();
    final media = await hasPhotosOrStoragePermission();
    final permissions = <String, bool>{
      'notifications': notifications,
      'location': location,
      'backgroundLocation': backgroundLocation,
      'media': media,
    };

    if (includeSupervisionPermissions) {
      final usage = await hasUsagePermission();
      final battery = await hasBatteryOptimizationDisabled();

      permissions.addAll({
        'usage': usage,
        'batteryOptimizationDisabled': battery,
      });
    }

    return permissions;
  }

  Future<Map<String, bool>> checkAppEntryPermissions() {
    return checkAllPermissions(includeSupervisionPermissions: false);
  }

  Future<Map<String, bool>> checkChildSupervisionPermissions() async {
    final usage = await hasUsagePermission();
    final battery = await hasBatteryOptimizationDisabled();

    return {
      'usage': usage,
      'batteryOptimizationDisabled': battery,
    };
  }
}
