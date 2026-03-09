import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init() async {
    // debugPrint('STEP INIT START');
    // ✅ Tạo notification channel cho Android 8+
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'default_channel',
        'Default',
        description: 'Default notifications',
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
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'Default notifications',
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
      );

      const details = NotificationDetails(android: androidDetails);

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