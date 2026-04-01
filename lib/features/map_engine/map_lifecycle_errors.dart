import 'package:flutter/services.dart';

bool isMapLifecycleError(Object error) {
  if (error is PlatformException) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    if (code.contains('channel-error') ||
        code.contains('detached') ||
        message.contains('unable to establish connection on channel') ||
        message.contains('flutterjni was detached') ||
        message.contains('used after being disposed') ||
        message.contains('no such channel')) {
      return true;
    }
  }

  final text = error.toString().toLowerCase();
  return text.contains('mapboxcontroller was used after being disposed') ||
      text.contains('unable to establish connection on channel') ||
      text.contains('flutterjni was detached') ||
      text.contains('platform channel') && text.contains('detached') ||
      text.contains('used after being disposed');
}
