import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';

String trackingStatusFromNotificationPayload({
  required String title,
  required Map<String, dynamic> data,
}) {
  final byTitle = _statusFromTrackingKey(title);
  if (byTitle.isNotEmpty) return byTitle;

  final byEventKey = _statusFromTrackingKey(
    (data['eventKey'] ?? '').toString(),
  );
  if (byEventKey.isNotEmpty) return byEventKey;

  return (data['status'] ?? '').toString().trim().toLowerCase();
}

NotificationStyle resolveTrackingNotificationStyle({
  required String title,
  required Map<String, dynamic> data,
  NotificationStyle? fallback,
}) {
  final status = trackingStatusFromNotificationPayload(
    title: title,
    data: data,
  );
  return trackingStyleFromStatus(status, fallback: fallback);
}

NotificationStyle trackingStyleFromStatus(
  String status, {
  NotificationStyle? fallback,
}) {
  switch (status) {
    case 'location_service_off':
      return const NotificationStyle(
        icon: Icons.location_off_rounded,
        bgColor: Color(0xFFFFF1F2),
        borderColor: Color(0xFFFECDD3),
        iconColor: Color(0xFFDC2626),
      );
    case 'location_permission_denied':
      return const NotificationStyle(
        icon: Icons.lock_rounded,
        bgColor: Color(0xFFFFF1F2),
        borderColor: Color(0xFFFECDD3),
        iconColor: Color(0xFFDC2626),
      );
    case 'background_disabled':
      return const NotificationStyle(
        icon: Icons.do_not_disturb_on_rounded,
        bgColor: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        iconColor: Color(0xFFD97706),
      );
    case 'location_stale':
      return const NotificationStyle(
        icon: Icons.schedule_rounded,
        bgColor: Color(0xFFFFF7ED),
        borderColor: Color(0xFFFED7AA),
        iconColor: Color(0xFFEA580C),
      );
    case 'safe_route_deviated':
      return const NotificationStyle(
        icon: Icons.alt_route_rounded,
        bgColor: Color(0xFFFFF7ED),
        borderColor: Color(0xFFFED7AA),
        iconColor: Color(0xFFEA580C),
      );
    case 'safe_route_back_on_route':
      return const NotificationStyle(
        icon: Icons.route_rounded,
        bgColor: Color(0xFFF0FDF4),
        borderColor: Color(0xFFBBF7D0),
        iconColor: Color(0xFF16A34A),
      );
    case 'safe_route_returned_to_start':
      return const NotificationStyle(
        icon: Icons.trip_origin_rounded,
        bgColor: Color(0xFFEEF2FF),
        borderColor: Color(0xFFC7D2FE),
        iconColor: Color(0xFF4F46E5),
      );
    case 'safe_route_stationary':
      return const NotificationStyle(
        icon: Icons.pause_circle_rounded,
        bgColor: Color(0xFFFFFBEB),
        borderColor: Color(0xFFFDE68A),
        iconColor: Color(0xFFD97706),
      );
    case 'safe_route_arrived':
      return const NotificationStyle(
        icon: Icons.check_circle_rounded,
        bgColor: Color(0xFFF0FDF4),
        borderColor: Color(0xFFBBF7D0),
        iconColor: Color(0xFF16A34A),
      );
    case 'safe_route_danger_zone':
      return const NotificationStyle(
        icon: Icons.warning_amber_rounded,
        bgColor: Color(0xFFFFF1F2),
        borderColor: Color(0xFFFECDD3),
        iconColor: Color(0xFFDC2626),
      );
    case 'ok':
      return const NotificationStyle(
        icon: Icons.verified_rounded,
        bgColor: Color(0xFFF0FDF4),
        borderColor: Color(0xFFBBF7D0),
        iconColor: Color(0xFF16A34A),
      );
    default:
      return fallback ??
          const NotificationStyle(
            icon: Icons.warning_amber_rounded,
            bgColor: Color(0xFFFFF7ED),
            borderColor: Color(0xFFFED7AA),
            iconColor: Color(0xFFEA580C),
          );
  }
}

String _statusFromTrackingKey(String key) {
  final normalized = key.trim().toLowerCase();
  if (!normalized.startsWith('tracking.')) return '';

  final parts = normalized.split('.');
  if (parts.length < 3) return '';

  return parts[1];
}
