import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Map<String, dynamic>? _pendingTapData;

  static Future<void> init() async {
    debugPrint('STEP INIT START');

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint("🔥 NOTIFICATION TAPPED");
        debugPrint("ACTION ID: ${response.actionId}");
        debugPrint("PAYLOAD: ${response.payload}");
        final payload = response.payload;

        debugPrint('🔔 onDidReceiveNotificationResponse payload=$payload');
        debugPrint('STEP TAP 1');

        await _storePayload(payload);

        debugPrint('STEP TAP 2');
      },
    );

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

    // ✅ Handle trường hợp app được mở từ notification khi app bị kill
    final details = await _plugin.getNotificationAppLaunchDetails();
    debugPrint("LAUNCH DETAILS: $details");
    final launchedFromNotification = details?.didNotificationLaunchApp ?? false;

    if (launchedFromNotification) {
      final payload = details?.notificationResponse?.payload;
      debugPrint('🔔 app launched from notification payload=$payload');
      await _storePayload(payload);
    }

    debugPrint('STEP INIT DONE');
  }

  static Future<void> _storePayload(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final raw = jsonDecode(payload);

      if (raw is Map) {
        _pendingTapData = Map<String, dynamic>.from(raw);
      } else {
        _pendingTapData = {"value": raw};
      }

      debugPrint('🔔 pending local notification tap=$_pendingTapData');
    } catch (e) {
      // nếu không phải JSON
      _pendingTapData = {"value": payload};

      debugPrint('🔔 payload is plain string: $payload');
    }
  }

  static Future<void> consumePendingTap() async {
    final data = _pendingTapData;
    if (data == null) return;

    _pendingTapData = null;
    // await handleNotificationTap(data);
  }

  // static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
  //   debugPrint('🔔 handleNotificationTap data=$data');

  //   final notificationId = data['notificationId']?.toString();
  //   if (notificationId == null || notificationId.isEmpty) {
  //     debugPrint('🔔 notificationId missing');
  //     return;
  //   }

  //   final repo = NotificationRepository();
  //   final item = await repo.getItemById(notificationId);
  //   debugPrint("🔎 notification fetch result = $item");

  //   if (item == null) {
  //     debugPrint('🔔 notification not found: $notificationId');
  //     return;
  //   }

  //   for (int i = 0; i < 10; i++) {
  //     final navigator = AppNavigator.navigatorKey.currentState;
  //     if (navigator != null) {
  //       navigator.push(
  //         MaterialPageRoute(
  //           builder: (_) => NotificationDetailScreen(item: item),
  //         ),
  //       );
  //       return;
  //     }
  //     await Future.delayed(const Duration(milliseconds: 100));
  //   }

  //   debugPrint('🔔 navigator still not ready');
  // }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint("========== LOCAL NOTIFICATION DEBUG ==========");
    debugPrint("TIME: ${DateTime.now()}");
    debugPrint("TITLE: $title");
    debugPrint("BODY: $body");
    debugPrint("PAYLOAD: $payload");

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

      debugPrint("NOTIFICATION ID: $id");

      await _plugin.show(id, title, body, details, payload: payload);

      debugPrint("LOCAL NOTIFICATION SHOW SUCCESS");
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