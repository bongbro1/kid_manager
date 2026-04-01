import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class LocalAlarmService {
  LocalAlarmService._();
  static final LocalAlarmService I = LocalAlarmService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String dangerChannelId = 'danger_zone_channel';

  bool _inited = false;

  Future<AppLocalizations> _loadL10n([String? lang]) {
    final normalized =
        (lang ?? PlatformDispatcher.instance.locale.languageCode).toLowerCase();
    return AppLocalizations.delegate.load(
      Locale(normalized.startsWith('en') ? 'en' : 'vi'),
    );
  }

  Future<void> init() async {
    if (_inited) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);

    final l10n = await _loadL10n();
    final androidChannel = AndroidNotificationChannel(
      dangerChannelId,
      l10n.localAlarmDangerChannelName,
      description: l10n.localAlarmDangerChannelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin
    >();
    await androidImpl?.createNotificationChannel(androidChannel);

    _inited = true;
    debugPrint('🔔 LocalAlarmService inited');
  }

  Future<void> showDangerEnter({
    required String zoneName,
  }) async {
    await init();
    final l10n = await _loadL10n();

    final androidDetails = AndroidNotificationDetails(
      dangerChannelId,
      l10n.localAlarmDangerChannelName,
      channelDescription: l10n.localAlarmDangerChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      // ✅ nếu bạn có custom sound: thêm raw resource và set sound ở đây
      // sound: RawResourceAndroidNotificationSound('siren'),
    );

    const iosDetails = DarwinNotificationDetails(presentSound: true);

    await _plugin.show(
      2001,
      l10n.localAlarmDangerEnterTitle,
      l10n.localAlarmDangerEnterBody(zoneName),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> showDangerExit({
    required String zoneName,
  }) async {
    await init();
    final l10n = await _loadL10n();

    final androidDetails = AndroidNotificationDetails(
      dangerChannelId,
      l10n.localAlarmDangerChannelName,
      channelDescription: l10n.localAlarmDangerChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(presentSound: true);

    await _plugin.show(
      2002,
      l10n.localAlarmDangerExitTitle,
      l10n.localAlarmDangerExitBody(zoneName),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}
