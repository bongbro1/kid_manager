import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/services/notifications/tracking_location_notification_text.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';
import 'package:kid_manager/widgets/notifications/blocked_app_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/removed_app_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/safe_route_notification_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/tracking_location_status_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/zone_details_widgets.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/widgets/notifications/schedule_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/memory_day_detail_widget.dart';
import 'package:kid_manager/widgets/notifications/schedule_import_detail_widget.dart';

class NotificationDetailBody extends StatelessWidget {
  final NotificationDetailModel detail;
  final VoidCallback? onZoneViewMap;
  final VoidCallback? onZonePhone;
  final VoidCallback? onOpenSafeRouteTracking;

  const NotificationDetailBody({
    super.key,
    required this.detail,
    this.onZoneViewMap,
    this.onZonePhone,
    this.onOpenSafeRouteTracking,
  });

  @override
  Widget build(BuildContext context) {
    final type = detail.type.toString().trim().toLowerCase();
    final trackingStatus = trackingStatusFromNotificationPayload(
      title: detail.title,
      data: detail.data,
    );

    if (type == 'zone') {
      return ZoneDetailWidget(
        detail: detail,
        onViewMap: onZoneViewMap,
        onPhone: onZonePhone,
      );
    }
    if (detail.notificationType == NotificationType.tracking &&
        trackingStatus.startsWith('safe_route_')) {
      return SafeRouteNotificationDetailWidget(
        detail: detail,
        onOpenTracking: onOpenSafeRouteTracking,
      );
    }
    if (isTrackingLocationStatusNotification(
      type: detail.type,
      title: detail.title,
      data: detail.data,
    )) {
      return TrackingLocationStatusDetailWidget(detail: detail);
    }
    if (detail.notificationType == NotificationType.appRemoved) {
      return RemovedAppDetailWidget(detail: detail);
    }

    if (detail.notificationType == NotificationType.blockedApp) {
      return BlockedAppDetailWidget(detail: detail);
    }

    if (detail.notificationType == NotificationType.schedule) {
      return ScheduleDetailWidget(detail: detail);
    }

    if (detail.notificationType == NotificationType.memoryDay) {
      return MemoryDayDetailWidget(detail: detail);
    }

    if (detail.notificationType == NotificationType.importExcel) {
      return ScheduleImportDetailWidget(detail: detail);
    }

    return Text(
      detail.content,
      style: const TextStyle(color: Color(0xFF0F172A)),
    );
  }
}
