import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SosNotificationService {
  SosNotificationService._();
  static final instance = SosNotificationService._();
  bool _initialized = false;

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'sos_channel_v2',
    'SOS Alerts',
    description: 'Emergency SOS alerts',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('sos'),
  );

  Future<void> _resolveFromAction(Map<String, dynamic> data) async {
    final familyId = data['familyId']?.toString();
    final sosId = data['sosId']?.toString();
    if (familyId == null || sosId == null) return;

    final fn = FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).httpsCallable('resolveSos');

    await fn.call({'familyId': familyId, 'sosId': sosId});
    await _fln.cancel(1001);
  }

  Future<void> init({
    required void Function(Map<String, dynamic> data) onTapSos,
  }) async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('SosNotificationService.init()');

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'sos_category',
          actions: [
            DarwinNotificationAction.plain(
              'RESOLVE_SOS',
              'XÁC NHẬN',
              options: {DarwinNotificationActionOption.authenticationRequired},
            ),
          ],
        ),
      ],
    );

    await _fln.initialize(
      InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) async {
        final payload = resp.payload;
        if (payload == null) return;

        final data = jsonDecode(payload) as Map<String, dynamic>;

        if (resp.actionId == 'RESOLVE_SOS') {
          await _resolveFromAction(data);
          return;
        }

        onTapSos(data);
      },
    );

    final android = _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_androidChannel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      sound: true,
      badge: true,
    );

    FirebaseMessaging.onMessage.listen((msg) {
      _showFromRemoteMessage(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = Map<String, dynamic>.from(msg.data);
      onTapSos(data);
    });

    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      final data = Map<String, dynamic>.from(initialMsg.data);
      onTapSos(data);
    }
  }

  Future<void> _showFromRemoteMessage(RemoteMessage msg) async {
    debugPrint(
      '[SOS PUSH] onMessage data=${msg.data} notif=${msg.notification?.title}',
    );

    final data = Map<String, dynamic>.from(msg.data);
    final type = msg.data['type']?.toString();
    if (type != 'SOS') return;

    final title = msg.notification?.title ?? 'SOS KHẨN CẤP';
    final body = msg.notification?.body ?? 'Có thành viên đang cầu cứu.';

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('sos'),
      visibility: NotificationVisibility.public,
      actions: const [
        AndroidNotificationAction(
          'RESOLVE_SOS',
          'XÁC NHẬN',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      categoryIdentifier: 'sos_category',
      sound: 'sos.caf',
      presentAlert: true,
    );

    await _fln.show(
      1001,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }
}
