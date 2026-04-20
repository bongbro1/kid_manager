import 'dart:io';

import 'package:flutter/services.dart';

class AndroidSosAlertBridge {
  AndroidSosAlertBridge._();

  static const String channelId = 'sos_channel_v3';
  static const MethodChannel _channel = MethodChannel('sos_alerts');

  static bool get isSupported => Platform.isAndroid;

  static Future<bool> hasNotificationPolicyAccess() async {
    if (!isSupported) return false;

    try {
      return await _channel.invokeMethod<bool>('hasNotificationPolicyAccess') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> canUseFullScreenIntent() async {
    if (!isSupported) return true;

    try {
      return await _channel.invokeMethod<bool>('canUseFullScreenIntent') ??
          true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> ensureNotificationChannel({
    required String channelName,
    required String channelDescription,
  }) async {
    if (!isSupported) return;

    await _channel.invokeMethod<void>('ensureSosNotificationChannel', {
      'channelId': channelId,
      'channelName': channelName,
      'channelDescription': channelDescription,
      'soundResName': 'sos',
    });
  }

  static Future<void> prepareBestEffortAudioEscalation() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('prepareSosAudioEscalation');
    } catch (_) {}
  }

  static Future<void> restoreBestEffortAudioEscalation() async {
    if (!isSupported) return;

    try {
      await _channel.invokeMethod<void>('restoreSosAudioEscalation');
    } catch (_) {}
  }

  static Future<void> openNotificationPolicyAccessSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openNotificationPolicyAccessSettings');
  }

  static Future<void> openFullScreenIntentSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openFullScreenIntentSettings');
  }

  static Future<void> openChannelSettings() async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('openSosChannelSettings', {
      'channelId': channelId,
    });
  }
}
