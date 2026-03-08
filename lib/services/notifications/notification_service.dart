import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';

class NotificationService {
  static Future<void> init() async {
    debugPrint('🔔 NotificationService.init()');

    FirebaseMessaging.onMessage.listen((m) async {
      debugPrint(
        '🔔 onMessage (FG) id=${m.messageId} data=${m.data} notif=${m.notification?.title}',
      );
      await handleMessageForLocalNotification(m);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      debugPrint('🔔 onMessageOpenedApp id=${m.messageId} data=${m.data}');
    });

    // Log cái message khiến app mở từ terminated (nếu có)
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint(
        '🔔 getInitialMessage id=${initial.messageId} data=${initial.data}',
      );
    }
  }

  static Future<void> handleMessageForLocalNotification(
    RemoteMessage message,
  ) async {
    debugPrint('🔔 handleMessageForLocalNotification() data=${message.data}');

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

      debugPrint(
        '🔔 show normal local notification title="$title" body="$body"',
      );

      await LocalNotificationService.show(title: title, body: body);
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

    await LocalNotificationService.show(title: title, body: body);
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
