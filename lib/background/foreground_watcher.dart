import 'package:flutter/services.dart';

class ForegroundWatcher {
  static const _stream = EventChannel("watcher_stream");

  static Stream<String> get stream =>
      _stream.receiveBroadcastStream().map((e) => e as String);
}