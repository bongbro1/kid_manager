import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/widgets/notifications/blocked_app_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/zone_details_widgets.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';

class NotificationDetailBody extends StatelessWidget {
  final NotificationDetailModel detail;
  final VoidCallback? onZoneViewMap;
  final VoidCallback? onZonePhone;

  const NotificationDetailBody({
    super.key,
    required this.detail,
    this.onZoneViewMap,
    this.onZonePhone,
  });

  @override
  Widget build(BuildContext context) {
    final type = detail.type.toString().trim().toLowerCase();

    if (type == 'zone') {
      return ZoneDetailWidget(
        detail: detail,
        onViewMap: onZoneViewMap,
        onPhone: onZonePhone,
      );
    }

    if (detail.notificationType == NotificationType.blockedApp) {
      return BlockedAppDetailWidget(detail: detail);
    }

    return Text(
      detail.content,
      style: const TextStyle(color: Color(0xFF0F172A)),
    );
  }
}