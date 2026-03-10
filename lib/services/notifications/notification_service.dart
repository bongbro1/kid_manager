import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/views/notifications/notification_detail_screen.dart';
import 'package:kid_manager/widgets/app/app_sell_config.dart';

class NotificationService {
  static const _channel = MethodChannel('notification_intent');
  static Future<void> init() async {
    debugPrint('🔔 NotificationService.init()');

    FirebaseMessaging.onMessage.listen((m) async {
      debugPrint(
        '🔔 onMessage (FG) id=${m.messageId} data=${m.data} notif=${m.notification?.title}',
      );
      await handleMessageForLocalNotification(m);
    });

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationTap') {
        final payload = call.arguments as String?;
        if (payload != null) {
          final data = jsonDecode(payload);

          await handleTap(data);
        }
      }
    });
  }

  static Future<void> handleTap(Map<String, dynamic> data) async {
    final type = data["type"];
    final notificationId = data['notificationId']?.toString();
    if (notificationId == null || notificationId.isEmpty) {
      debugPrint('🔔 notificationId missing');
      return;
    }

    final repo = NotificationRepository();
    final item = await repo.getItemById(notificationId);
    if (item == null) {
      debugPrint('🔔 notification not found: $notificationId');
      return;
    }

    if (type != "sos") {
      activeTabNotifier.value = AppShellConfig.notificationTabIndex;
      Future.microtask(() {
        final nav = NotificationTabNavigator.key.currentState;
        if (nav == null) return;

        nav.push(
          MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(item: item),
          ),
        );
      });

      return;
    }

    if (type == "sos") {
      final navigator = AppNavigator.navigatorKey.currentState;
      if (navigator != null) {
        debugPrint('🔔 VÀO MÀN SOS');
        // navigator.push(
        //   MaterialPageRoute(
        //     builder: (_) => SosScreen(),
        //   ),
        // );
        return;
      }
    }
  }

  static Future<void> handleMessageForLocalNotification(
    RemoteMessage message,
  ) async {
    // debugPrint('🔔 handleMessageForLocalNotification() data=${message.data}');

    final type = message.data['type']?.toString().toLowerCase() ?? '';

    if (type != 'zone') {
      final title =
          message.notification?.title ??
          message.data['title']?.toString() ??
          'Thông báo';

      final body =
          message.notification?.body ??
          message.data['body']?.toString() ??
          'Bạn có thông báo mới';

      // debugPrint(
      //   '🔔 show normal local notification title="$title" body="$body"',
      // );

      await LocalNotificationService.show(
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );
      return;
    }

    if (message.data["type"] == "test") {
      debugPrint("TEST NOTIFICATION CLICKED");
      return;
    }

    final key = message.data['eventKey']?.toString() ?? 'zone.default';
    final zoneName = message.data['zoneName']?.toString() ?? '';
    final lang = (message.data['lang']?.toString() ?? 'vi').toLowerCase();

    debugPrint('🔔 parsed key=$key zoneName=$zoneName lang=$lang');

    final locale = Locale(lang == 'en' ? 'en' : 'vi');
    final l10n = await AppLocalizations.delegate.load(locale);

    final title = _zoneTitleFromKey(l10n, key);
    final body = zoneName;

    debugPrint('🔔 show zone local notification title="$title" body="$body"');

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  static const _systemSender = 'system';
  static final NotificationRepository _repo = NotificationRepository();

  /// ==============================
  /// 👤 USER → USER
  /// ==============================
  static Future<void> sendUserToUser({
    required String senderId,
    required String receiverId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? familyId,
  }) {
    return _repo.create(
      senderId: senderId,
      receiverId: receiverId,
      type: type,
      title: title,
      body: body,
      data: data,
      familyId: familyId,
    );
  }

  /// ==============================
  /// ⚙️ SYSTEM → USER
  /// ==============================
  static Future<void> sendSystem(NotificationPayload payload) {
    return _repo.create(
      senderId: _systemSender,
      receiverId: payload.receiverId,
      type: payload.type.name,
      title: payload.title,
      body: payload.body,
      data: payload.data,
    );
  }

  /// ==============================
  /// 🚨 CHILD ALERT → PARENT
  /// ==============================
  static Future<void> sendChildAlert({
    required String childId,
    required String parentId,
    required String type,
    required String title,
    required String body,
    String? familyId,
    Map<String, dynamic>? data,
  }) {
    return _repo.create(
      senderId: childId,
      receiverId: parentId,
      type: type,
      title: title,
      body: body,
      data: data,
      familyId: familyId,
    );
  }

  static String _zoneTitleFromKey(AppLocalizations l10n, String key) {
    switch (key) {
      case 'zone.enter.danger.parent':
        return l10n.zone_enter_danger_parent;
      case 'zone.exit.danger.parent':
        return l10n.zone_exit_danger_parent;
      case 'zone.enter.safe.parent':
        return l10n.zone_enter_safe_parent;
      case 'zone.exit.safe.parent':
        return l10n.zone_exit_safe_parent;

      case 'zone.enter.danger.child':
        return l10n.zone_enter_danger_child;
      case 'zone.exit.danger.child':
        return l10n.zone_exit_danger_child;
      case 'zone.enter.safe.child':
        return l10n.zone_enter_safe_child;
      case 'zone.exit.safe.child':
        return l10n.zone_exit_safe_child;

      default:
        return l10n.zone_default;
    }
  }
}
