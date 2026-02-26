import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef SosOpenHandler = void Function({
  required String familyId,
  required String sosId,
  required String childUid,
  double? lat,
  double? lng,
});

class SosPushService {
  SosPushService({
    required FirebaseFunctions functions,
    required FlutterLocalNotificationsPlugin fln,
    required SosOpenHandler onOpenSos,
  })  : _functions = functions,
        _fln = fln,
        _onOpenSos = onOpenSos;

  final FirebaseFunctions _functions;
  final FlutterLocalNotificationsPlugin _fln;
  final SosOpenHandler _onOpenSos;

  static const _androidChannelId = 'sos_channel';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();
    await _createSosChannelIfAndroid();

    final fm = FirebaseMessaging.instance;

    // iOS: permission
    await fm.requestPermission(alert: true, badge: true, sound: true);

    // Token register
    await _registerCurrentToken();

    // Token refresh
    fm.onTokenRefresh.listen((t) async {
      try {
        await _registerToken(t);
      } catch (e) {
        debugPrint('register token failed: $e');
      }
    });

    // Foreground messages -> show local notification for guaranteed sound
    FirebaseMessaging.onMessage.listen((msg) async {
      if (_isSos(msg)) {
        await _showSosLocalNotification(msg);
      }
    });

    // App opened from background by tapping notification
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (_isSos(msg)) _handleOpen(msg);
    });

    // App opened from terminated state
    final initial = await fm.getInitialMessage();
    if (initial != null && _isSos(initial)) {
      _handleOpen(initial);
    }
  }

  Future<void> unregisterOnLogout() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      final callable = _functions.httpsCallable('unregisterFcmToken');
      await callable.call({'token': token});
    } catch (e) {
      debugPrint('unregister token failed: $e');
    }
  }

  // -------------------- local notifications --------------------

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        _handlePayload(payload);
      },
    );
  }

  Future<void> _createSosChannelIfAndroid() async {
    if (!Platform.isAndroid) return;

    // Channel sound is immutable once created (Android 8+),
    // so ensure correct ID & sound from the start.
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      'SOS Alerts',
      description: 'Âm thanh SOS khẩn cấp',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('sos'), // res/raw/sos.mp3
    );

    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
  }

  Future<void> _showSosLocalNotification(RemoteMessage msg) async {
    final data = msg.data;
    final title = msg.notification?.title ?? '🚨 SOS KHẨN CẤP';
    final body = msg.notification?.body ?? 'Có thành viên đang cầu cứu. Chạm để xem.';

    // payload for deep-link
    final familyId = data['familyId'] ?? '';
    final sosId = data['sosId'] ?? '';
    final childUid = data['childUid'] ?? '';
    final lat = data['lat'] ?? '';
    final lng = data['lng'] ?? '';
    final payload = '$familyId|$sosId|$childUid|$lat|$lng';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannelId,
        'SOS Alerts',
        channelDescription: 'Âm thanh SOS khẩn cấp',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('sos'),
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentSound: true,
      ),
    );

    await _fln.show(
      1001, // fixed id to replace if multiple foreground SOS come
      title,
      body,
      details,
      payload: payload,
    );
  }

  // -------------------- token registration --------------------

  Future<void> _registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    final callable = _functions.httpsCallable('registerFcmToken');
    await callable.call({
      'token': token,
      'platform': Platform.isAndroid ? 'android' : 'ios',
    });
  }

  // -------------------- open SOS --------------------

  bool _isSos(RemoteMessage msg) => msg.data['type'] == 'SOS';

  void _handleOpen(RemoteMessage msg) {
    final data = msg.data;
    final familyId = (data['familyId'] ?? '').toString();
    final sosId = (data['sosId'] ?? '').toString();
    final childUid = (data['childUid'] ?? '').toString();

    final lat = double.tryParse((data['lat'] ?? '').toString());
    final lng = double.tryParse((data['lng'] ?? '').toString());

    if (familyId.isEmpty || sosId.isEmpty || childUid.isEmpty) return;

    _onOpenSos(
      familyId: familyId,
      sosId: sosId,
      childUid: childUid,
      lat: lat,
      lng: lng,
    );
  }

  void _handlePayload(String payload) {
    final parts = payload.split('|');
    if (parts.length < 3) return;

    final familyId = parts[0];
    final sosId = parts[1];
    final childUid = parts[2];
    final lat = parts.length > 3 ? double.tryParse(parts[3]) : null;
    final lng = parts.length > 4 ? double.tryParse(parts[4]) : null;

    if (familyId.isEmpty || sosId.isEmpty || childUid.isEmpty) return;

    _onOpenSos(
      familyId: familyId,
      sosId: sosId,
      childUid: childUid,
      lat: lat,
      lng: lng,
    );
  }
}