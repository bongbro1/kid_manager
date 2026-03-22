import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<AppLocalizations> _loadL10n([String? lang]) {
    final normalized =
        (lang ?? PlatformDispatcher.instance.locale.languageCode).toLowerCase();
    return AppLocalizations.delegate.load(
      Locale(normalized.startsWith('en') ? 'en' : 'vi'),
    );
  }

  static Future<void> init() async {
    // debugPrint('STEP INIT START');
    // ✅ Tạo notification channel cho Android 8+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final l10n = await _loadL10n();

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        'default_channel',
        l10n.notificationsLocalChannelName,
        description: l10n.notificationsLocalChannelDescription,
        importance: Importance.max,
      ),
    );

    // debugPrint('STEP INIT DONE');
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    // debugPrint("========== LOCAL NOTIFICATION DEBUG ==========");
    // debugPrint("TIME: ${DateTime.now()}");
    // debugPrint("TITLE: $title");
    // debugPrint("BODY: $body");
    // debugPrint("PAYLOAD: $payload");

    try {
      final l10n = await _loadL10n();
      final androidDetails = AndroidNotificationDetails(
        'default_channel',
        l10n.notificationsLocalChannelName,
        channelDescription: l10n.notificationsLocalChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
      );

      final details = NotificationDetails(android: androidDetails);

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e, s) {
      debugPrint("LOCAL NOTIFICATION ERROR: $e");
      debugPrint("$s");
    }

    debugPrint("==============================================");
  }
}



// LocalNotificationService.show()
//         ↓
// User tap notification
//         ↓
// onDidReceiveNotificationResponse
//         ↓
// _storePayload(payload)
