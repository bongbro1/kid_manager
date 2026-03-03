import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';

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

    // ✅ tắt local notif (nếu đang hiện)
    await _fln.cancel(1001);
  }

  Future<void> _registerTokenToServer() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔔 [FCM] current token=${token == null ? "NULL" : "OK"}');
    if (token == null) return;

    await _registerToken(token);

    // refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      debugPrint('🔄 [FCM] token refresh tokenLen=${t.length}');
      try {
        await _registerToken(t);
        debugPrint('✅ [FCM] refresh register OK');
      } catch (e) {
        debugPrint('❌ [FCM] refresh register FAIL: $e');
      }
    });
  }


  Future<void> _registerToken(String token) async {
    final fn = FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).httpsCallable('registerFcmToken');

    try {
      final res = await fn.call({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
      debugPrint('✅ [FCM] registerFcmToken OK: ${res.data}');
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '❌ [FCM] registerFcmToken FAIL code=${e.code} msg=${e.message} details=${e.details}',
      );
      rethrow;
    }
  }

  Future<void> unregisterOnLogout() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final fn = FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).httpsCallable('unregisterFcmToken');

    try {
      await fn.call({'token': token});
      debugPrint('✅ [FCM] unregisterFcmToken OK');
    } catch (e) {
      debugPrint('❌ [FCM] unregisterFcmToken FAIL: $e');
    }
  }

  Future<void> init({
    required void Function(Map<String, dynamic> data) onTapSos,
  }) async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('🟦 SosNotificationService.init() CALLED');
    // Local notifications init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
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

    // Android channel create
    final android = _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_androidChannel);

    // iOS: show notif even in foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          sound: true,
          badge: true,
        );

    // When app in foreground: show local notification (because FCM notif UI may not show)
    FirebaseMessaging.onMessage.listen((msg) {
      _showFromRemoteMessage(msg);
    });
    debugPrint('🟩 SosNotificationService listeners attached');
    // When user taps notification (background->opened)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final data = Map<String, dynamic>.from(msg.data);
      onTapSos(data);
    });

    // When app launched from terminated by tap
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      final data = Map<String, dynamic>.from(initialMsg.data);
      onTapSos(data);
    }

    await _registerTokenToServer();
  }

  Future<void> _resolveFromBackground(Map<String, dynamic> data) async {
    final familyId = data['familyId'];
    final sosId = data['sosId'];

    if (familyId == null || sosId == null) return;

    await FirebaseFirestore.instance
        .doc('families/$familyId/sos/$sosId')
        .update({'status': 'resolved'});
  }

  Future<void> _showFromRemoteMessage(RemoteMessage msg) async {
    debugPrint(
      '🔔 [PUSH] onMessage data=${msg.data} notif=${msg.notification?.title}',
    );
    final data = Map<String, dynamic>.from(msg.data);
    final type = msg.data['type']?.toString();
    debugPrint('🔔 [PUSH] type=$type');
    if (type != 'SOS') return;

    final title = msg.notification?.title ?? '🚨 SOS KHẨN CẤP';
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
      1001, // fixed id ok, or use hash of sosId
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }
}
