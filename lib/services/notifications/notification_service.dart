import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/views/notifications/notification_detail_screen.dart';

class NotificationService {
  static bool _initialized = false;
  static String? _lastHandledNotificationId;
  static const _channel = MethodChannel('notification_intent');

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
      debugPrint(
        '🔔 onMessageOpenedApp id=${m.messageId} data=${m.data}',
      );
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

  static Future<void> handleTap(Map<String, dynamic> data) async {
    final type = data["type"]?.toString();
    final notificationId = data['notificationId']?.toString();

    debugPrint('🔔 handleTap type=$type notificationId=$notificationId data=$data');

    if (notificationId == null || notificationId.isEmpty) {
      debugPrint('🔔 notificationId missing');
      return;
    }

    if (_lastHandledNotificationId == notificationId) {
      debugPrint('🔔 duplicate tap ignored: $notificationId');
      return;
    }
    _lastHandledNotificationId = notificationId;

    final repo = NotificationRepository();
    final item = await repo.getItemById(notificationId);
    if (item == null) {
      debugPrint('🔔 notification not found: $notificationId');
      return;
    }

    final navigator = AppNavigator.navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('🔔 navigator not ready');
      return;
    }

    if (type != "sos") {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => NotificationDetailScreen(item: item),
        ),
      );
      return;
    }

    if (type == "sos") {
      debugPrint('🔔 VÀO MÀN SOS');
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

    if (type != 'zone') {
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
