import 'dart:convert';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class SosNotificationService {
  SosNotificationService._();
  static final instance = SosNotificationService._();
  bool _initialized = false;
  bool _canResolveSos = false;

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sos_channel_v2';
  static const int _notificationId = 1001;

  bool _isSosData(Map<String, dynamic> data) {
    return (data['type']?.toString() ?? '').toLowerCase() == 'sos';
  }

  Future<AppLocalizations> _loadL10n([String? lang]) {
    final normalized =
        (lang ?? PlatformDispatcher.instance.locale.languageCode).toLowerCase();
    return AppLocalizations.delegate.load(
      Locale(normalized.startsWith('en') ? 'en' : 'vi'),
    );
  }

  Future<AndroidNotificationChannel> _buildAndroidChannel([String? lang]) async {
    final l10n = await _loadL10n(lang);
    return AndroidNotificationChannel(
      _channelId,
      l10n.sosChannelName,
      description: l10n.sosChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('sos'),
    );
  }

  Future<void> _resolveFromAction(Map<String, dynamic> data) async {
    if (!_canResolveSos) return;

    final familyId = data['familyId']?.toString();
    final sosId = data['sosId']?.toString();
    if (familyId == null || sosId == null) return;

    final fn = FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).httpsCallable('resolveSos');

    await fn.call({'familyId': familyId, 'sosId': sosId});
    await clearActiveAlert();
  }

  Future<void> clearActiveAlert() async {
    await _fln.cancel(_notificationId);
  }

  Future<void> init({
    required void Function(Map<String, dynamic> data) onTapSos,
    required UserRole role,
  }) async {
    _canResolveSos = role.isAdultManager;

    if (_initialized) return;
    _initialized = true;
    debugPrint('SosNotificationService.init()');

    final l10n = await _loadL10n();
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
              l10n.incomingSosConfirmButton,
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

        if (!_isSosData(data)) return;
        onTapSos(data);
      },
    );

    final android = _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(await _buildAndroidChannel());

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
      if (!_isSosData(data)) return;
      onTapSos(data);
    });

    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      final data = Map<String, dynamic>.from(initialMsg.data);
      if (!_isSosData(data)) return;
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

    final l10n = await _loadL10n(data['lang']?.toString());
    final androidChannel = await _buildAndroidChannel(data['lang']?.toString());
    final title = msg.notification?.title ?? l10n.sosFallbackTitle;
    final body = msg.notification?.body ?? l10n.sosFallbackBody;

    final androidDetails = AndroidNotificationDetails(
      androidChannel.id,
      androidChannel.name,
      channelDescription: androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('sos'),
      visibility: NotificationVisibility.public,
      actions: _canResolveSos
          ? [
              AndroidNotificationAction(
                'RESOLVE_SOS',
                l10n.incomingSosConfirmButton,
                showsUserInterface: false,
              ),
            ]
          : const <AndroidNotificationAction>[],
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      categoryIdentifier: 'sos_category',
      sound: 'sos.caf',
      presentAlert: true,
    );

    await _fln.show(
      _notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }
}
