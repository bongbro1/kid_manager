import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/widgets/notifications/blocked_app_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/zone_details_widgets.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';

class NotificationDetailBody extends StatelessWidget {
  final NotificationDetailModel detail;
  const NotificationDetailBody({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final type = (detail.type).toString().trim();

    // ✅ zone: backend có thể gửi "ZONE" hoặc "zone"
    if (type.toUpperCase() == 'ZONE' || type.toLowerCase() == 'zone') {
      return ZoneDetailWidget(detail: detail);
    }

    // ✅ blocked_app
    if (detail.notificationType == NotificationType.blockedApp) {
      return BlockedAppDetailWidget(detail: detail);
    }

    // ✅ fallback
    return Text(
      detail.content,
      style: const TextStyle(color: Color(0xFF0F172A)),
    );
  }
}