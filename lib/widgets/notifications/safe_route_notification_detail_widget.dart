import 'package:flutter/material.dart';
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

  String get _childName =>
      (_data['childName'] ?? _data['displayName'] ?? _data['name'] ?? 'Bé')
          .toString()
          .trim();

  String get _routeName =>
      (_data['routeName'] ?? _data['routeTitle'] ?? 'Tuyến an toàn')
          .toString()
          .trim();

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
    final style = resolveTrackingNotificationStyle(
      title: detail.title,
      data: detail.data,
      fallback: detail.notificationType.style,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusPill(
          label: _statusLabel(),
          icon: style.icon,
          foreground: style.iconColor,
          background: style.bgColor,
          border: style.borderColor,
        ),
        const SizedBox(height: 16),
        Text(
          _headline(),
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
              : _fallbackBody(),
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
                label: 'Bé',
                value: _childName.isEmpty ? 'Không rõ' : _childName,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.route_rounded,
                label: 'Tuyến đường',
                value: _routeName.isEmpty ? 'Tuyến an toàn' : _routeName,
              ),
              if (_distanceFromRouteMeters != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.alt_route_rounded,
                  label: 'Khoảng cách tới tuyến',
                  value: _distanceLabel(_distanceFromRouteMeters!),
                ),
              ],
              if (_hazardName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.warning_amber_rounded,
                  label: 'Vùng nguy hiểm',
                  value: _hazardName,
                ),
              ],
              if (_stationaryDurationMinutes != null &&
                  _stationaryDurationMinutes! > 0) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.pause_circle_rounded,
                  label: 'Đứng yên',
                  value: '${_stationaryDurationMinutes!} phút',
                ),
              ],
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Thời điểm',
                value: detail.timeDisplay,
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
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.map_rounded, color: Color(0xFF1D4ED8), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mở trang theo dõi để xem vị trí hiện tại của bé, tuyến đang bám và toàn bộ trạng thái hành trình trên bản đồ.',
                  style: TextStyle(
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
            label: const Text(
              'Mở theo dõi hành trình',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  String _statusLabel() {
    switch (_status) {
      case 'safe_route_deviated':
        return 'Lệch tuyến';
      case 'safe_route_back_on_route':
        return 'Quay lại tuyến';
      case 'safe_route_returned_to_start':
        return 'Về điểm đầu';
      case 'safe_route_stationary':
        return 'Đứng yên quá lâu';
      case 'safe_route_arrived':
        return 'Đã đến nơi';
      case 'safe_route_danger_zone':
        return 'Nguy hiểm';
      default:
        return 'Safe Route';
    }
  }

  String _headline() {
    switch (_status) {
      case 'safe_route_deviated':
        return 'Bé đang đi lệch khỏi tuyến đã chọn';
      case 'safe_route_back_on_route':
        return 'Bé đã quay lại tuyến an toàn';
      case 'safe_route_returned_to_start':
        return 'Bé đang quay lại gần điểm xuất phát';
      case 'safe_route_stationary':
        return 'Bé đang đứng yên lâu hơn bình thường';
      case 'safe_route_arrived':
        return 'Bé đã đến nơi an toàn';
      case 'safe_route_danger_zone':
        return 'Bé đang đi vào vùng nguy hiểm';
      default:
        return detail.title;
    }
  }

  String _fallbackBody() {
    switch (_status) {
      case 'safe_route_deviated':
        return 'Hệ thống phát hiện bé đã ra ngoài hành lang an toàn của tuyến $_routeName.';
      case 'safe_route_back_on_route':
        return 'Hệ thống ghi nhận bé đã quay lại hành lang an toàn của tuyến $_routeName.';
      case 'safe_route_returned_to_start':
        return 'Bé đang quay lại gần vị trí xuất phát của tuyến $_routeName.';
      case 'safe_route_stationary':
        return 'Bé đã đứng gần cùng một vị trí quá lâu khi đang đi trên $_routeName.';
      case 'safe_route_arrived':
        return 'Bé đã đến điểm đích của $_routeName.';
      case 'safe_route_danger_zone':
        return _hazardName.isEmpty
            ? 'Bé đã đi vào một vùng nguy hiểm trên hành trình hiện tại.'
            : 'Bé đã đi vào $_hazardName khi đang theo tuyến $_routeName.';
      default:
        return detail.content;
    }
  }

  String _distanceLabel(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
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
