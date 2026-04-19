import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';

class SafeRouteNotificationDetailWidget extends StatelessWidget {
  const SafeRouteNotificationDetailWidget({
    super.key,
    required this.detail,
    this.onOpenTracking,
  });

  final NotificationDetailModel detail;
  final VoidCallback? onOpenTracking;

  Map<String, dynamic> get _data => detail.data;

  String get _status => trackingStatusFromNotificationPayload(
    title: detail.title,
    data: detail.data,
  );

  String get _hazardName => (_data['hazardName'] ?? '').toString().trim();

  String get _childUid =>
      (_data['childUid'] ?? _data['childId'] ?? '').toString().trim();

  double? get _distanceFromRouteMeters =>
      _readDouble(_data['distanceFromRouteMeters']);

  int? get _stationaryDurationMinutes => int.tryParse(
    (_data['stationaryDurationMinutes'] ?? '').toString().trim(),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = resolveTrackingNotificationStyle(
      title: detail.title,
      data: detail.data,
      fallback: detail.notificationType.style,
    );
    final childName = _childName(l10n);
    final routeName = _routeName(l10n);
    final unknownValue = l10n.notificationTrackingUnknownValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusPill(
          label: _statusLabel(l10n),
          icon: style.icon,
          foreground: style.iconColor,
          background: style.bgColor,
          border: style.borderColor,
        ),
        const SizedBox(height: 16),
        Text(
          _headline(l10n),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          detail.content.trim().isNotEmpty
              ? detail.content.trim()
              : _fallbackBody(l10n),
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.child_care_rounded,
                label: l10n.notificationTrackingChildLabel,
                value: childName.isEmpty ? unknownValue : childName,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.route_rounded,
                label: l10n.notificationTrackingRouteLabel,
                value: routeName.isEmpty
                    ? l10n.safeRouteSelectedRouteFallbackName
                    : routeName,
              ),
              if (_distanceFromRouteMeters != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.alt_route_rounded,
                  label: l10n.notificationTrackingDistanceToRouteLabel,
                  value: l10n.safeRouteDistanceLabel(_distanceFromRouteMeters!),
                ),
              ],
              if (_hazardName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.warning_amber_rounded,
                  label: l10n.notificationTrackingHazardLabel,
                  value: _hazardName,
                ),
              ],
              if (_stationaryDurationMinutes != null &&
                  _stationaryDurationMinutes! > 0) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.pause_circle_rounded,
                  label: l10n.notificationTrackingStationaryLabel,
                  value: l10n.parentStatsDurationMinutes(
                    _stationaryDurationMinutes!,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: l10n.notificationTrackingTimeLabel,
                value: detail.formatTimeDisplay(l10n),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.map_rounded, color: Color(0xFF1D4ED8), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.notificationTrackingOpenHint,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _childUid.isEmpty ? null : onOpenTracking,
            icon: const Icon(Icons.navigation_rounded, size: 18),
            label: Text(
              l10n.notificationTrackingOpenButton,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _childName(AppLocalizations l10n) {
    return (_data['childName'] ??
            _data['displayName'] ??
            _data['name'] ??
            l10n.notificationChildFallback)
        .toString()
        .trim();
  }

  String _routeName(AppLocalizations l10n) {
    return (_data['routeName'] ??
            _data['routeTitle'] ??
            l10n.safeRouteSelectedRouteFallbackName)
        .toString()
        .trim();
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (_status) {
      case 'safe_route_deviated':
        return l10n.notificationTrackingStatusOffRoute;
      case 'safe_route_back_on_route':
        return l10n.notificationTrackingStatusBackOnRoute;
      case 'safe_route_returned_to_start':
        return l10n.notificationTrackingStatusReturnedToStart;
      case 'safe_route_stationary':
        return l10n.notificationTrackingStatusStationary;
      case 'safe_route_arrived':
        return l10n.notificationTrackingStatusArrived;
      case 'safe_route_danger_zone':
        return l10n.notificationTrackingStatusDanger;
      default:
        return l10n.notificationTrackingStatusDefault;
    }
  }

  String _headline(AppLocalizations l10n) {
    switch (_status) {
      case 'safe_route_deviated':
        return l10n.notificationTrackingHeadlineOffRoute;
      case 'safe_route_back_on_route':
        return l10n.notificationTrackingHeadlineBackOnRoute;
      case 'safe_route_returned_to_start':
        return l10n.notificationTrackingHeadlineReturnedToStart;
      case 'safe_route_stationary':
        return l10n.notificationTrackingHeadlineStationary;
      case 'safe_route_arrived':
        return l10n.notificationTrackingHeadlineArrived;
      case 'safe_route_danger_zone':
        return l10n.notificationTrackingHeadlineDanger;
      default:
        return detail.title;
    }
  }

  String _fallbackBody(AppLocalizations l10n) {
    final routeName = _routeName(l10n);

    switch (_status) {
      case 'safe_route_deviated':
        return l10n.notificationTrackingFallbackOffRoute(routeName);
      case 'safe_route_back_on_route':
        return l10n.notificationTrackingFallbackBackOnRoute(routeName);
      case 'safe_route_returned_to_start':
        return l10n.notificationTrackingFallbackReturnedToStart(routeName);
      case 'safe_route_stationary':
        return l10n.notificationTrackingFallbackStationary(routeName);
      case 'safe_route_arrived':
        return l10n.notificationTrackingFallbackArrived(routeName);
      case 'safe_route_danger_zone':
        return _hazardName.isEmpty
            ? l10n.notificationTrackingFallbackDangerGeneric
            : l10n.notificationTrackingFallbackDangerWithHazard(
                _hazardName,
                routeName,
              );
      default:
        return detail.content;
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF334155)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
