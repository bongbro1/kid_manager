import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';

class NotificationService {
  static const _systemSender = 'system';
  static final NotificationRepository _repo = NotificationRepository();

  static Future<void> init() async {
    debugPrint('🔔 NotificationService.init()');

    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint(
        '🔔 onMessage (FG) id=${message.messageId} data=${message.data} notif=${message.notification?.title}',
      );
      await handleMessageForLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
        '🔔 onMessageOpenedApp id=${message.messageId} data=${message.data}',
      );
      handleNotificationTap(message);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint(
        '🔔 getInitialMessage id=${initial.messageId} data=${initial.data}',
      );
      handleNotificationTap(initial);
    }
  }

  static Future<void> handleMessageForLocalNotification(
      RemoteMessage message,
      ) async {
    debugPrint('🔔 handleMessageForLocalNotification() data=${message.data}');

    final type = message.data['type']?.toString().toLowerCase() ?? '';

    if (type == 'zone') {
      await _showZoneNotification(message);
      return;
    }

    if (type == 'family_chat') {
      await _showFamilyChatNotification(message);
      return;
    }

    if (type == 'family_event') {
      await _showFamilyEventNotification(message);
      return;
    }

    await _showDefaultNotification(message);
  }

  static void handleNotificationTap(RemoteMessage message) {
    final type = message.data['type']?.toString().toLowerCase() ?? '';
    final familyId = message.data['familyId']?.toString();
    final route = message.data['route']?.toString();
    final messageId = message.data['messageId']?.toString();
    final eventId = message.data['eventId']?.toString();

    debugPrint(
      '🔔 handleNotificationTap() type=$type route=$route familyId=$familyId messageId=$messageId eventId=$eventId',
    );

    if (type == 'family_chat') {
      // TODO:
      // navigatorKey.currentState?.pushNamed(
      //   '/family-group-chat',
      //   arguments: {'familyId': familyId, 'messageId': messageId},
      // );
      return;
    }

    if (type == 'family_event') {
      // TODO:
      // navigatorKey.currentState?.pushNamed(
      //   '/family-event-detail',
      //   arguments: {'familyId': familyId, 'eventId': eventId},
      // );
      return;
    }

    if (type == 'zone') {
      // TODO: route den man hinh phu hop neu can
      return;
    }

    // TODO: default route neu can
  }

  static Future<void> _showDefaultNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            'Thông báo';

    final body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            'Bạn có thông báo mới';

    debugPrint(
      '🔔 show default local notification title="$title" body="$body"',
    );

    await LocalNotificationService.show(title: title, body: body);
  }

  static Future<void> _showFamilyChatNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            'Tin nhắn gia đình';

    final body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            'Bạn có tin nhắn mới';

    debugPrint(
      '🔔 show family chat local notification title="$title" body="$body"',
    );

    await LocalNotificationService.show(title: title, body: body);
  }

  static Future<void> _showFamilyEventNotification(
      RemoteMessage message,
      ) async {
    final title =
        message.notification?.title ??
            message.data['title']?.toString() ??
            'Sự kiện gia đình';

    final body =
        message.notification?.body ??
            message.data['body']?.toString() ??
            'Gia đình bạn có sự kiện mới';

    debugPrint(
      '🔔 show family event local notification title="$title" body="$body"',
    );

    await LocalNotificationService.show(title: title, body: body);
  }

  static Future<void> _showZoneNotification(RemoteMessage message) async {
    final key = message.data['eventKey']?.toString() ?? 'zone.default';
    final zoneName = message.data['zoneName']?.toString() ?? '';
    final lang = (message.data['lang']?.toString() ?? 'vi').toLowerCase();

    debugPrint('🔔 parsed zone key=$key zoneName=$zoneName lang=$lang');

    final locale = Locale(lang == 'en' ? 'en' : 'vi');
    final l10n = await AppLocalizations.delegate.load(locale);

    final title = _zoneTitleFromKey(l10n, key);
    final body = zoneName;

    debugPrint(
      '🔔 show zone local notification title="$title" body="$body"',
    );

    await LocalNotificationService.show(title: title, body: body);
  }

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

  static Future<void> sendFamilyEventToMembers({
    required String senderId,
    required List<String> receiverIds,
    required String title,
    required String body,
    required String familyId,
    String type = 'family_event',
    Map<String, dynamic>? data,
  }) async {
    final futures = receiverIds
        .where((uid) => uid != senderId)
        .map(
          (uid) => _repo.create(
        senderId: senderId,
        receiverId: uid,
        type: type,
        title: title,
        body: body,
        data: {
          ...?data,
          'type': type,
          'familyId': familyId,
        },
        familyId: familyId,
      ),
    );

    await Future.wait(futures);
  }

  static Future<void> sendSystemFamilyEvent({
    required List<String> receiverIds,
    required String title,
    required String body,
    required String familyId,
    String type = 'family_event',
    Map<String, dynamic>? data,
  }) async {
    final futures = receiverIds.map(
          (uid) => _repo.create(
        senderId: _systemSender,
        receiverId: uid,
        type: type,
        title: title,
        body: body,
        data: {
          ...?data,
          'type': type,
          'familyId': familyId,
        },
        familyId: familyId,
      ),
    );

    await Future.wait(futures);
  }

  static Future<void> sendFamilyChatToMembers({
    required String senderId,
    required List<String> receiverIds,
    required String senderName,
    required String messageText,
    required String familyId,
    required String messageId,
    Map<String, dynamic>? data,
  }) async {
    debugPrint(
      '[NotificationService] sendFamilyChatToMembers called '
          'senderId=$senderId familyId=$familyId messageId=$messageId '
          'receiverIds=$receiverIds text="$messageText"',
    );

    final targets = receiverIds.where((uid) => uid != senderId).toList();

    debugPrint(
      '[NotificationService] filtered targets=$targets '
          '(excluded senderId=$senderId)',
    );

    if (targets.isEmpty) {
      debugPrint('[NotificationService] no targets to notify');
      return;
    }

    try {
      final futures = targets.map((uid) async {
        final payload = {
          ...?data,
          'type': 'family_chat',
          'familyId': familyId,
          'messageId': messageId,
          'route': 'family_group_chat',
          'senderUid': senderId,
        };

        debugPrint(
          '[NotificationService] creating notification '
              'receiverId=$uid title="$senderName" body="$messageText" data=$payload',
        );

        await _repo.create(
          senderId: senderId,
          receiverId: uid,
          type: 'family_chat',
          title: senderName,
          body: messageText,
          data: payload,
          familyId: familyId,
        );

        debugPrint(
          '[NotificationService] create success receiverId=$uid',
        );
      });

      await Future.wait(futures);

      debugPrint(
        '[NotificationService] sendFamilyChatToMembers done '
            'count=${targets.length}',
      );
    } catch (e, st) {
      debugPrint('[NotificationService] sendFamilyChatToMembers error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
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