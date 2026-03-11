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

  static const MethodChannel _channel = MethodChannel('watcher');

  static bool _started = false;

  static Future<bool> isWatcherRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWatcherRunning');
      return result ?? false;
    } catch (e) {
      debugPrint('NativeWatcherService.isWatcherRunning error: $e');
      return false;
    }
  }

  static Future<bool> startWatcher({
    required String userId,
    String? parentId,
    String? childName,
  }) async {
    if (_started) return true;

    try {
      final result = await _channel.invokeMethod<bool>('startWatcher', {
        'userId': userId,
        'parentId': parentId,
        'childName': childName,
      });

      final ok = result ?? false;
      if (ok) {
        _started = true;
      }
      return ok;
    } on PlatformException catch (e) {
      debugPrint(
        'NativeWatcherService.startWatcher PlatformException: ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('NativeWatcherService.startWatcher error: $e');
      return false;
    }
  }

  static Future<bool> stopWatcher() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopWatcher');
      _started = false;
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint(
        'NativeWatcherService.stopWatcher PlatformException: ${e.message}',
      );
      _started = false;
      return false;
    } catch (e) {
      debugPrint('NativeWatcherService.stopWatcher error: $e');
      _started = false;
      return false;
    }
  }

  static bool get isStarted => _started;
}
