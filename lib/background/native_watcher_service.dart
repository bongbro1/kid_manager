import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

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
          .map((w) => {'startMin': w.startMin, 'endMin': w.endMin})
          .toList(),
      weekdays: rule.weekdays.toList(),
      overrides: rule.overrides.map((k, v) => MapEntry(k, v.name)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'enabled': enabled,
      'windows': windows,
      'weekdays': weekdays,
      'overrides': overrides,
    };
  }
}

class NativeWatcherService {
  NativeWatcherService._();

  static const MethodChannel _channel = MethodChannel('watcher_config');
  static const MethodChannel _batteryChannel = MethodChannel(
    'battery_optimization',
  );

  static bool _configured = false;

  static Future<bool> saveWatcherConfig({
    String? userId,
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

  static Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final result = await _batteryChannel.invokeMethod<bool>(
        'isIgnoringBatteryOptimizations',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Battery optimization check error: $e');
      return false;
    }
  }

  static Future<bool> hasUsageAccessPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'hasUsageAccessPermission',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Usage access permission check error: $e');
      return false;
    }
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      debugPrint('Battery optimization request error: $e');
    }
  }

  static bool get isConfigured => _configured;
}
