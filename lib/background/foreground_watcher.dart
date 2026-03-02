import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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