import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

class PermissionService {
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
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
    } else {
      final status = await Permission.storage.status;
      return status.isGranted;
    }
  }

  Future<bool> requestMicrophonePermission() async {
    debugPrint("🎤 requestMicrophonePermission()");

    final status = await Permission.microphone.request();

    debugPrint("🎤 request result = $status");

    return status.isGranted;
  }

  Future<bool> requestPhotosOrStoragePermission() async {
    debugPrint("🖼 requestPhotosOrStoragePermission()");

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

    debugPrint("🖼 request result = $status");

    return status.isGranted;
  }

  Future<bool> _isAndroid13OrAbove() async {
    final sdk = await DeviceInfoPlugin().androidInfo;
    return sdk.version.sdkInt >= 33;
  }

  /// Internet: không xin runtime. Chỉ khai báo manifest => luôn true.
  bool hasInternetByManifest() => true;

  /// Usage Access (Giám sát thời gian hoạt động app) - Android only
  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
    );
    await intent.launch();
  }

  Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final granted = await UsageStats.checkUsagePermission();
      debugPrint("🔎 checkUsagePermission = $granted");

      return granted ?? false;
    } catch (e) {
      debugPrint("🔥 Usage permission error: $e");
      return false;
    }
  }

  /// Optional: kiểm tra Accessibility (nếu app bạn dùng accessibility để theo dõi)
  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;

    const intent = AndroidIntent(
      action: 'android.settings.ACCESSIBILITY_SETTINGS',
    );
    await intent.launch();
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    final mic = await hasMicrophonePermission();
    final media = await hasPhotosOrStoragePermission();
    final usage = await hasUsagePermission();

    return {'microphone': mic, 'media': media, 'usage': usage};
  }
}
