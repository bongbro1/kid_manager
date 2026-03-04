import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  blockedApp,
  sos,
  heartbeatLost,
  usageLimitExceeded,
}
extension NotificationTypeX on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.blockedApp:
        return "blocked_app";
      case NotificationType.sos:
        return "sos";
      case NotificationType.heartbeatLost:
        return "heartbeat_lost";
      case NotificationType.usageLimitExceeded:
        return "usage_limit_exceeded";
    }
  }

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.blockedApp,
    );
  }
}

class AppNotification {
  final String id;
  final String senderId;
  final String receiverId;
  final String? familyId;

  final String type;
  final String title;
  final String body;

  final bool isRead;
  final String status;

  final DateTime? createdAt;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.familyId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.status,
    required this.data,
    required this.createdAt,
  });

  factory AppNotification.fromMap(
      String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,

      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      familyId: map['familyId'],

      type: map['type'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',

      isRead: map['isRead'] ?? false,
      status: map['status'] ?? 'pending',

      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,

      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}
