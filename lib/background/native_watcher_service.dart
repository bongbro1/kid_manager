import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

class ForegroundWatcher {
  static const EventChannel _stream = EventChannel("watcher_stream");

  static Stream<ForegroundApp> get stream {
    return _stream.receiveBroadcastStream().map((event) {
      final map = Map<dynamic, dynamic>.from(event as Map);

      return ForegroundApp(
        packageName: map["packageName"]?.toString() ?? "",
        appName: map["appName"]?.toString() ?? "",
      );
    });
  }
}

class ForegroundApp {
  final String packageName;
  final String appName;

  ForegroundApp({required this.packageName, required this.appName});
}

class NativeBlockedRule {
  final String packageName;
  final bool enabled;
  final List<Map<String, dynamic>> windows;
  final List<int> weekdays;
  final Map<String, String> overrides;

  NativeBlockedRule({
    required this.packageName,
    required this.enabled,
    required this.windows,
    required this.weekdays,
    required this.overrides,
  });

  factory NativeBlockedRule.fromUsageRule({
    required String packageName,
    required UsageRule rule,
  }) {
    return NativeBlockedRule(
      packageName: packageName,
      enabled: rule.enabled,
      windows: rule.windows
          .map((w) => {"startMin": w.startMin, "endMin": w.endMin})
          .toList(),
      weekdays: rule.weekdays.toList(),
      overrides: rule.overrides.map((k, v) => MapEntry(k, v.name)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "packageName": packageName,
      "enabled": enabled,
      "windows": windows,
      "weekdays": weekdays,
      "overrides": overrides,
    };
  }
}

class NativeWatcherService {
  NativeWatcherService._();

  static const MethodChannel _channel = MethodChannel('watcher_config');
  static const MethodChannel _chanelAccessibility = MethodChannel('accessibility');

  static bool _configured = false;

  /// Lưu config để AccessibilityService dùng
  static Future<bool> saveWatcherConfig({
    required String userId,
    String? parentId,
    String? childName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('saveWatcherConfig', {
        'userId': userId,
        'parentId': parentId,
        'childName': childName,
      });

      final ok = result ?? false;
      if (ok) {
        _configured = true;
      }

      return ok;
    } on PlatformException catch (e) {
      debugPrint(
        'NativeWatcherService.saveWatcherConfig PlatformException: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('NativeWatcherService.saveWatcherConfig error: $e');
      return false;
    }
  }

  /// Kiểm tra Accessibility đã bật chưa
  static Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _chanelAccessibility.invokeMethod<bool>(
        'isAccessibilityEnabled',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('NativeWatcherService.isAccessibilityEnabled error: $e');
      return false;
    }
  }

  
  static Future<void> openAccessibilitySettings() async {
    await _chanelAccessibility.invokeMethod("openAccessibilitySettings");
  }

  static bool get isConfigured => _configured;
}

// class NativeScheduleUsageService {
//   NativeScheduleUsageService._();

//   static const MethodChannel _channel = MethodChannel('schedule_usage_channel');

//   static Future<void> startUsageWorker(String userId) async {
//     try {
//       await _channel.invokeMethod("startUsageWorker", {"userId": userId});
//     } on PlatformException catch (e) {
//       debugPrint(
//         "NativeScheduleUsageService.startUsageWorker error: ${e.message}",
//       );
//     } catch (e) {
//       debugPrint("NativeScheduleUsageService.startUsageWorker error: $e");
//     }
//   }
// }
