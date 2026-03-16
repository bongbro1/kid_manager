import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/services/notifications/zone_i18n.dart';
import 'package:kid_manager/views/chat/family_group_chat_screen.dart';
import 'package:kid_manager/views/notifications/notification_detail_screen.dart';
import 'package:kid_manager/widgets/app/app_sell_config.dart';

// TODO: import đúng màn hình này nếu project đang dùng
// import 'package:kid_manager/views/family/family_group_chat_screen.dart';

class NotificationService {
  static bool _initialized = false;
  static String? _lastHandledNotificationId;

  NotificationService._();

  static const String _systemSender = 'system';
  static const MethodChannel _channel = MethodChannel('notification_intent');
  static final NotificationRepository _repo = NotificationRepository();

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('🔔 NotificationService.init()');

    FirebaseMessaging.onMessage.listen((m) async {
      debugPrint(
        '🔔 onMessage (FG) id=${m.messageId} data=${m.data} notif=${m.notification?.title}',
      );
      await handleMessageForLocalNotification(m);
    });

    // App đang background, user bấm push system notification
    FirebaseMessaging.onMessageOpenedApp.listen((m) async {
      debugPrint('🔔 onMessageOpenedApp id=${m.messageId} data=${m.data}');
      await handleTap(Map<String, dynamic>.from(m.data));
    });

    // App bị kill hẳn, user bấm push để mở app
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '🔔 getInitialMessage id=${initialMessage.messageId} data=${initialMessage.data}',
      );

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await handleTap(Map<String, dynamic>.from(initialMessage.data));
      });
    }

    // Local notification tap / native channel cũ
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationTap') {
        final payload = call.arguments as String?;
        if (payload != null) {
          final data = jsonDecode(payload);
          await handleTap(Map<String, dynamic>.from(data));
        }
      }
    });
  }

  static Future<void> handleInitialMessage() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '🔔 handleInitialMessage id=${initialMessage.messageId} data=${initialMessage.data}',
      );
      await handleTap(initialMessage.data);
    }
  }

  static Future<void> handleTap(Map<String, dynamic> data) async {
    final rawType = data["type"]?.toString();
    final type = (rawType ?? '').toLowerCase();
    final notificationId = data['notificationId']?.toString();
    final familyId = data['familyId']?.toString();
    final messageId = data['messageId']?.toString();
    final eventId = data['eventId']?.toString();
    final route = data['route']?.toString();

    debugPrint(
      '🔔 handleTap type=$rawType normalizedType=$type notificationId=$notificationId familyId=$familyId messageId=$messageId eventId=$eventId route=$route',
    );

    if (type == 'test') {
      debugPrint('🔔 TEST NOTIFICATION CLICKED');
      return;
    }

    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('🔔 Navigator is null, cannot navigate');
      return;
    }

    if (type == 'sos') {
      debugPrint('🔔 Navigate to SOS screen');
      // TODO: push SOS screen here
      return;
    }

    if (type == 'family_chat' || route == 'family_group_chat') {
      if (familyId == null || familyId.isEmpty) {
        debugPrint('🔔 family_chat tapped but familyId missing');
        return;
      }

      // TODO: mở lại khi đã import FamilyGroupChatScreen
      navigator.push(
        MaterialPageRoute(
          builder: (_) => FamilyGroupChatScreen(
            initialFamilyId: familyId,
            initialMessageId: messageId,
          ),
        ),
      );
      return;
    }

    if (type == 'family_event') {
      debugPrint('🔔 family_event tapped eventId=$eventId');
      // TODO: navigate event detail
      return;
    }

    if (type == 'zone') {
      debugPrint('🔔 zone notification tapped -> open notifications tab');
      activeTabNotifier.value = notificationTabIndexNotifier.value;
      return;
    }

    if (notificationId == null || notificationId.isEmpty) {
      debugPrint('🔔 notificationId missing, skip detail navigation');
      return;
    }

    if (_lastHandledNotificationId == notificationId) {
      debugPrint('🔔 duplicate tap ignored: $notificationId');
      return;
    }
    _lastHandledNotificationId = notificationId;

    final item = await _repo.getItemById(notificationId);
    if (item == null) {
      debugPrint('🔔 notification not found: $notificationId');
      return;
    }

    if (type != "sos") {
      activeTabNotifier.value = notificationTabIndexNotifier.value;
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
  }

  static Future<void> handleMessageForLocalNotification(
    RemoteMessage message,
  ) async {
    final data = message.data;
    final type = data['type']?.toString().toLowerCase() ?? '';

    // Guard riêng cho schedule + memory_day
    if (type == 'schedule' || type == 'memory_day') {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final actorUid = data['actorUid']?.toString();
      final actorRole = data['actorRole']?.toString().toLowerCase();
      final childId = data['childId']?.toString();
      final ownerParentUid = data['ownerParentUid']?.toString();

      if (currentUid == null || currentUid.isEmpty) {
        debugPrint('🔕 [$type] skip: no current user');
        return;
      }

      // self notification
      if (actorUid != null && actorUid == currentUid) {
        debugPrint(
          '🔕 [$type] skip self notification: currentUid=$currentUid actorUid=$actorUid',
        );
        return;
      }

      String? expectedReceiverId;

      if (actorRole == 'child') {
        expectedReceiverId = ownerParentUid;
      } else if (actorRole == 'parent') {
        expectedReceiverId = childId;
      } else {
        expectedReceiverId = ownerParentUid;
      }

      if (expectedReceiverId == null || expectedReceiverId.isEmpty) {
        debugPrint('🔕 [$type] skip: expectedReceiverId is null/empty');
        return;
      }

      if (expectedReceiverId != currentUid) {
        debugPrint(
          '🔕 [$type] skip wrong receiver: currentUid=$currentUid expectedReceiverId=$expectedReceiverId actorUid=$actorUid',
        );
        return;
      }

      final title =
          message.notification?.title ??
          data['title']?.toString() ??
          'Thông báo';

      final body =
          message.notification?.body ??
          data['body']?.toString() ??
          'Bạn có thông báo mới';

      await LocalNotificationService.show(
        title: title,
        body: body,
        payload: jsonEncode(data),
      );
      return;
    }

    if (type == 'sos') {
      debugPrint('[sos] skip duplicate local notification in NotificationService');
      return;
    }

    if (type == 'zone') {
      await _showZoneNotification(message);
      return;
    }

    if (type == 'tracking' || type == 'tracking_status') {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final toUid = data['toUid']?.toString();

      if (currentUid == null || currentUid.isEmpty) {
        debugPrint('[$type] skip: no current user');
        return;
      }

      if (toUid != null && toUid.isNotEmpty && toUid != currentUid) {
        debugPrint(
          '[$type] skip wrong receiver: currentUid=$currentUid toUid=$toUid',
        );
        return;
      }

      await _showTrackingNotification(message);
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

    if (type == 'test') {
      debugPrint('🔔 TEST NOTIFICATION RECEIVED');
      await _showDefaultNotification(message);
      return;
    }

    await _showDefaultNotification(message);
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

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
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

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
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

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  static String _normalizeTrackingKey(String rawKey) {
    final key = rawKey.trim().toLowerCase();
    if (key.endsWith('.title') || key.endsWith('.body')) {
      final cut = key.lastIndexOf('.');
      if (cut > 0) {
        return key.substring(0, cut);
      }
    }
    return key;
  }

  static Future<void> _showTrackingNotification(RemoteMessage message) async {
    final data = message.data;
    final lang = (data['lang']?.toString() ?? 'vi').toLowerCase();
    final locale = Locale(lang.startsWith('en') ? 'en' : 'vi');
    final l10n = await AppLocalizations.delegate.load(locale);

    final rawTitle =
        message.notification?.title ??
        data['title']?.toString() ??
        data['eventKey']?.toString() ??
        l10n.tracking_default_title;

    final eventKey = _normalizeTrackingKey(
      (data['eventKey'] ?? rawTitle).toString(),
    );

    var title = rawTitle;
    if (rawTitle.startsWith('tracking.')) {
      title = trackingTitleFromKey(l10n, _normalizeTrackingKey(rawTitle));
    } else if (eventKey.startsWith('tracking.')) {
      title = trackingTitleFromKey(l10n, eventKey);
    }

    if (title.startsWith('tracking.')) {
      title = l10n.tracking_default_title;
    }

    final fallbackBody = lang.startsWith('en')
        ? 'Tracking status has changed.'
        : 'Trang thai dinh vi da thay doi.';

    var body =
        message.notification?.body ??
        data['body']?.toString() ??
        data['message']?.toString() ??
        '';

    if (body.startsWith('tracking.')) {
      body = (data['message']?.toString() ?? '').trim();
    }
    if (body.isEmpty) body = fallbackBody;

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
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

    debugPrint('🔔 show zone local notification title="$title" body="$body"');

    await LocalNotificationService.show(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

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
            data: {...?data, 'type': type, 'familyId': familyId},
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
        data: {...?data, 'type': type, 'familyId': familyId},
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

        debugPrint('[NotificationService] create success receiverId=$uid');
      });

      await Future.wait(futures);

      debugPrint(
        '[NotificationService] sendFamilyChatToMembers done count=${targets.length}',
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
