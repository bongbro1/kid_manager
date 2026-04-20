import 'package:kid_manager/models/notifications/app_notification.dart';

class NotificationPayload {
  final String receiverId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  const NotificationPayload({
    required this.receiverId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      "receiverId": receiverId,
      "type": type.name,
      "title": title,
      "body": body,
      "data": data,
    };
  }
}
