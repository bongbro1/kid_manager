import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/background/foreground_watcher.dart';
import 'package:kid_manager/utils/usage_rule.dart';

class WatcherService {
  static const _channel = MethodChannel("watcher");

  static Future<void> start() async {
    await _channel.invokeMethod("startWatcher");
  }
}

class RealtimeAppMonitor {
  static StreamSubscription<String>? _sub;

  static void start() {
    _sub ??= ForegroundWatcher.stream.listen((pkg) {
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
