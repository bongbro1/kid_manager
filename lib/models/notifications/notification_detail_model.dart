import 'package:kid_manager/l10n/app_localizations.dart';
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

  String formatTimeDisplay(AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) {
      return "${l10n.notificationJustNow} • ${_formatTime(createdAt)}";
    }

    if (diff.inMinutes < 60) {
      return "${l10n.notificationMinutesAgo(diff.inMinutes)} • ${_formatTime(createdAt)}";
    }

    if (diff.inHours < 24) {
      return "${l10n.notificationHoursAgo(diff.inHours)} • ${_formatTime(createdAt)}";
    }

    if (diff.inDays == 1) {
      return "${l10n.notificationDateYesterday} • ${_formatTime(createdAt)}";
    }

    final date =
        "${createdAt.day.toString().padLeft(2, '0')}/"
        "${createdAt.month.toString().padLeft(2, '0')}/"
        "${createdAt.year}";
    return "$date • ${_formatTime(createdAt)}";
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
