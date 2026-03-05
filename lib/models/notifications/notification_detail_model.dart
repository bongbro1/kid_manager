import 'package:kid_manager/models/notifications/app_notification.dart';

class NotificationDetailModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  final String type;

  NotificationDetailModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.data,
    required this.type,
  });

  /// 🔥 Build từ AppNotification (chuẩn kiến trúc)
  factory NotificationDetailModel.fromAppNotification(
    AppNotification notification,
  ) {
    return NotificationDetailModel(
      id: notification.id,
      title: notification.title,
      content: notification.body,
      createdAt: notification.createdAt ?? DateTime.now(),
      data: notification.data,
      type: notification.type,
    );
  }

  /// 🕒 Format thời gian chuẩn hơn
  String get timeDisplay {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    String relative;

    if (diff.inMinutes < 1) {
      relative = "Vừa xong";
    } else if (diff.inMinutes < 60) {
      relative = "${diff.inMinutes} phút trước";
    } else if (diff.inHours < 24) {
      relative = "${diff.inHours} giờ trước";
    } else if (diff.inDays == 1) {
      relative = "Hôm qua";
    } else if (diff.inDays < 7) {
      relative = "${diff.inDays} ngày trước";
    } else {
      relative =
          "${createdAt.day.toString().padLeft(2, '0')}/"
          "${createdAt.month.toString().padLeft(2, '0')}/"
          "${createdAt.year}";
    }

    return "$relative • ${_formatTime(createdAt)}";
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  NotificationType get notificationType {
    return NotificationTypeX.fromString(type);
  }
}
