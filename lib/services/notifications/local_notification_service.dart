import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class LocalNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const String generalChannelId = 'general_notifications';
  static const String chatChannelId = 'chat_messages';

  static Future<AppLocalizations> _loadL10n([String? lang]) {
    final normalized = (lang ?? PlatformDispatcher.instance.locale.languageCode)
        .toLowerCase();
    return AppLocalizations.delegate.load(
      Locale(normalized.startsWith('en') ? 'en' : 'vi'),
    );
  }

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // 👇 phần cũ của bạn
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final l10n = await _loadL10n();

    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        generalChannelId,
        l10n.notificationsLocalChannelName,
        description: l10n.notificationsLocalChannelDescription,
        importance: Importance.max,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        chatChannelId,
        'Chat Messages',
        description: 'Family group chat notifications',
        importance: Importance.max,
      ),
    );

    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    String channelId = generalChannelId,
  }) async {
    try {
      final l10n = await _loadL10n();

      final isChat = channelId == chatChannelId;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        isChat ? 'Chat Messages' : l10n.notificationsLocalChannelName,
        channelDescription: isChat
            ? 'Family group chat notifications'
            : l10n.notificationsLocalChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: isChat
            ? AndroidNotificationCategory.message
            : AndroidNotificationCategory.recommendation,
      );

      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      debugPrint(
        '[LocalNotificationService] show channelId=$channelId title="$title" body="$body"',
      );

      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e, s) {
      debugPrint('LOCAL NOTIFICATION ERROR: $e');
      debugPrint('$s');
    }
  }
}
