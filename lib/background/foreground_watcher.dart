import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/app_rule_checker_helper.dart';
import 'package:kid_manager/models/app_notification.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';

class ForegroundWatcher {
  static const _stream = EventChannel("watcher_stream");

  static Stream<String> get stream {
    return _stream.receiveBroadcastStream().map((event) {
      final pkg = event.toString();
      // debugPrint("📱 Foreground from native: $pkg");
      return pkg;
    });
  }
}

class WatcherService {
  static const _channel = MethodChannel("watcher");

  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;

    _started = true;
    await _channel.invokeMethod("startWatcher");
  }

  static Future<void> stop() async {
    await _channel.invokeMethod("stopWatcher");
  }
}

class RealtimeAppMonitor {
  static StreamSubscription<String>? _sub;
  static String? _parentId;

  static void start({required String parentId}) {
    _parentId = parentId;

    _sub ??= ForegroundWatcher.stream.listen(_onPackageChanged);
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }

  static final Map<String, DateTime> _lastNotified = {};
  static const Duration _cooldown = Duration(seconds: 10);

  static Future<void> _onPackageChanged(String pkg) async {
    debugPrint("📦 Checking rule for: $pkg");

    if (!AppRuleChecker.isBlocked(pkg)) {
      debugPrint("✅ Allowed: $pkg");
      return;
    }

    final now = DateTime.now();
    final lastTime = _lastNotified[pkg];

    if (lastTime != null && now.difference(lastTime) < _cooldown) {
      debugPrint("⏳ Skip duplicate notification for $pkg");
      return;
    }

    _lastNotified[pkg] = now;

    debugPrint("🚫 Child đang mở app bị CẤM: $pkg");

    try {
      await NotificationService.sendSystem(
        receiverId: _parentId!,
        type: NotificationType.blockedApp.value,
        title: "Ứng dụng bị chặn",
        body: "Trẻ đang mở ứng dụng bị cấm: $pkg",
      );

      debugPrint("📨 Sent system notification to parent");
    } catch (e) {
      debugPrint("❌ Send notification error: $e");
    }
  }
}
