import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/helpers/app_rule_checker_helper.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/blocked_app_data.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/utils/date_utils.dart';

class ForegroundWatcher {
  static const _stream = EventChannel("watcher_stream");

  static Stream<ForegroundApp> get stream {
    return _stream.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event);

      return ForegroundApp(
        packageName: map["packageName"] ?? "",
        appName: map["appName"] ?? "",
      );
    });
  }
}

class ForegroundApp {
  final String packageName;
  final String appName;

  ForegroundApp({
    required this.packageName,
    required this.appName,
  });
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
  static StreamSubscription<ForegroundApp>? _sub;

  static String? _parentId;
  static String? _displayName;

  static void start({
    required String parentId,
    required String displayName,
  }) {
    _parentId = parentId;
    _displayName = displayName;

    _sub ??= ForegroundWatcher.stream.listen(_onPackageChanged);
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }

  static final Map<String, DateTime> _lastNotified = {};
  static const Duration _cooldown = Duration(seconds: 10);

  static Future<void> _onPackageChanged(ForegroundApp app) async {
    final pkg = app.packageName;
    final appName = app.appName;

    debugPrint("📦 Checking rule for: $appName ($pkg)");

    final result = AppRuleChecker.check(pkg);

    // 👉 Không bị block thì thôi
    if (!result.isBlocked) return;

    final now = DateTime.now();
    final lastTime = _lastNotified[pkg];

    // 👉 chống spam notification
    if (lastTime != null && now.difference(lastTime) < _cooldown) {
      debugPrint("⏳ Skip duplicate notification for $appName");
      return;
    }

    _lastNotified[pkg] = now;

    debugPrint("🚫 Child đang mở app bị CẤM: $appName");

    try {
      /// 🕒 Lấy khung giờ cho phép từ result
      String allowedFrom = "";
      String allowedTo = "";

      final window = result.window;
      if (window != null) {
        allowedFrom = formatMinutes2(window.startMin);
        allowedTo = formatMinutes2(window.endMin);
      }

      final blockedData = BlockedAppData(
        studentName: _displayName ?? "Unknown",
        appName: appName,
        blockedAt: DateFormat("HH:mm:ss").format(now),
        allowedFrom: allowedFrom,
        allowedTo: allowedTo,
      );

      await NotificationService.sendSystem(
        receiverId: _parentId!,
        type: NotificationType.blockedApp.value,
        title: "Ứng dụng bị chặn",
        body: "$_displayName đang mở ứng dụng bị cấm: $appName",
        data: blockedData.toMap(),
      );

      debugPrint("📨 Sent system notification to parent");
    } catch (e) {
      debugPrint("❌ Send notification error: $e");
    }
  }
}
