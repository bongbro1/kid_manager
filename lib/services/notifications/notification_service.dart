import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';

class NotificationService {
  static Future<void> init() async {
    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  static void _handleForeground(RemoteMessage message) {
    final notification = message.notification;

    if (notification != null) {
      LocalNotificationService.show(
        title: notification.title ?? "Thông báo",
        body: notification.body ?? "",
      );
    }
  }

  static final NotificationRepository _repo = NotificationRepository();

  static const _systemSender = 'system';

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
  static Future<void> sendSystem({
    required String receiverId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return _repo.create(
      senderId: _systemSender,
      receiverId: receiverId,
      type: type,
      title: title,
      body: body,
      data: data,
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
}
