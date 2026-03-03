import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/background/app_rule_checker.dart';
import 'package:kid_manager/background/foreground_watcher.dart';

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

  static void start() {
    _sub ??= ForegroundWatcher.stream.listen((pkg) {
      debugPrint("📦 Checking rule for: $pkg");
      if (AppRuleChecker.isBlocked(pkg)) {
        debugPrint("🚫 Child đang mở app bị CẤM: $pkg");
      } else {
        debugPrint("✅ Allowed: $pkg");
      }
    });
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
