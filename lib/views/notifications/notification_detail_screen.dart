import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/location/map_focus_bus.dart';
import 'package:kid_manager/features/safe_route/presentation/pages/tracking_page.dart';
import 'package:kid_manager/helpers/phone/phone_helps.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';
import 'package:kid_manager/services/notifications/zone_i18n.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/notifications/notification_detail_body.dart';
import 'package:provider/provider.dart';

class NotificationDetailScreen extends StatefulWidget {
  final AppNotification item;

  const NotificationDetailScreen({super.key, required this.item});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<NotificationVM>();
      vm.markAsRead(widget.item);
      vm.loadNotificationDetailItem(widget.item);
    });
  }
  NotificationStyle _resolveTrackingStyle(NotificationDetailModel detail) {
    return resolveTrackingNotificationStyle(
      title: detail.title,
      data: detail.data,
      fallback: detail.notificationType.style,
    );
  }

  Color _resolveTopIconColor(NotificationDetailModel detail) {
    if (detail.notificationType == NotificationType.tracking) {
      return _resolveTrackingStyle(detail).iconColor;
    }

    if (detail.notificationType != NotificationType.zone) {
      return detail.notificationType.style.iconColor;
    }

    final data = detail.data;
    final zoneType = (data['zoneType'] ?? '').toString().toLowerCase();
    final action = (data['action'] ?? '').toString().toLowerCase();

    final isDanger = zoneType == 'danger';
    final isEnter = action == 'enter';

    if (isDanger && isEnter) return const Color(0xFFE53E3E);
    if (isDanger && !isEnter) return const Color(0xFF38A169);
    return const Color(0xFF3182CE);
  }

  Color _resolveTopBgColor(NotificationDetailModel detail) {
    if (detail.notificationType == NotificationType.tracking) {
      return _resolveTrackingStyle(detail).bgColor;
    }

    if (detail.notificationType != NotificationType.zone) {
      return detail.notificationType.style.bgColor;
    }

    final data = detail.data;
    final zoneType = (data['zoneType'] ?? '').toString().toLowerCase();
    final action = (data['action'] ?? '').toString().toLowerCase();

    final isDanger = zoneType == 'danger';
    final isEnter = action == 'enter';

    if (isDanger && isEnter) return const Color(0xFFFFF5F5);
    if (isDanger && !isEnter) return const Color(0xFFF0FFF4);
    return const Color(0xFFEFF6FF);
  }
  String _buildDisplayTitle(NotificationDetailModel detail) {
    final rawTitle = detail.title.trim();
    if (rawTitle.startsWith('tracking.')) {
      return trackingTitleFromKey(AppLocalizations.of(context), rawTitle);
    }

    if (detail.notificationType == NotificationType.schedule) {
      final data = detail.data;
      final action = (data['action'] ?? '').toString();
      final childName = (data['childName'] ?? 'Bé').toString();

      switch (action) {
        case 'created':
          return 'Lịch trình mới của $childName';
        case 'updated':
          return 'Lịch trình của $childName đã thay đổi';
        case 'deleted':
          return 'Lịch trình của $childName đã bị xóa';
        case 'restored':
          return 'Lịch trình của $childName đã được khôi phục';
        default:
          return detail.title;
      }
    }

    final data = detail.data;
    final zoneType = (data['zoneType'] ?? '').toString().toLowerCase();
    final action = (data['action'] ?? '').toString().toLowerCase();
    final childName =
    (data['childName'] ??
        data['displayName'] ??
        data['name'] ??
        data['fullName'] ??
        'Bé')
        .toString();

    if (zoneType == 'danger' && action == 'enter') {
      return '$childName đã vào vùng nguy hiểm';
    }
    if (zoneType == 'safe' && action == 'exit') {
      return '$childName đã rời vùng an toàn';
    }
    if (zoneType == 'danger' && action == 'exit') {
      return '$childName đã rời vùng nguy hiểm';
    }

    return detail.title;
  }

  IconData _resolveTopIcon(NotificationDetailModel detail) {
    if (detail.notificationType == NotificationType.tracking) {
      return _resolveTrackingStyle(detail).icon;
    }

    if (detail.notificationType != NotificationType.zone) {
      return detail.notificationType.style.icon;
    }

    final data = detail.data;
    final zoneType = (data['zoneType'] ?? '').toString().toLowerCase();
    final action = (data['action'] ?? '').toString().toLowerCase();

    final isDanger = zoneType == 'danger';
    final isEnter = action == 'enter';

    if (isDanger && isEnter) return Icons.warning_amber_rounded;
    if (isDanger && !isEnter) return Icons.verified_rounded;
    return Icons.location_on_outlined;
  }


  void _handleZoneViewMap(NotificationDetailModel detail) {
    _openZoneOnMainMap(detail);
  }

  Future<void> _handleOpenSafeRouteTracking(NotificationDetailModel detail) async {
    final childId = (detail.data['childUid'] ?? detail.data['childId'] ?? '')
        .toString()
        .trim();

    if (childId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin hành trình của bé'),
        ),
      );
      return;
    }

    final childAvatarUrl = _resolveChildAvatarUrl(detail, childId);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackingPage(
          childId: childId,
          childAvatarUrl: childAvatarUrl,
        ),
      ),
    );
  }

  String? _resolveChildAvatarUrl(
    NotificationDetailModel detail,
    String childId,
  ) {
    final fromPayload =
        (detail.data['childAvatarUrl'] ?? detail.data['avatarUrl'] ?? '')
            .toString()
            .trim();
    if (fromPayload.isNotEmpty) {
      return fromPayload;
    }

    try {
      final userVm = context.read<UserVm>();
      for (final child in userVm.children) {
        if (child.uid == childId) {
          final avatarUrl = child.avatarUrl?.trim() ?? '';
          return avatarUrl.isEmpty ? null : avatarUrl;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _handleZonePhone(NotificationDetailModel detail) async {
    final childId = (detail.data['childUid'] ?? '').toString().trim();
    final childName = (detail.data['childName'] ??
        detail.data['displayName'] ??
        detail.data['name'] ??
        'Bé')
        .toString();

    if (childId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin của bé')),
      );
      return;
    }

    await handleCallChildByProfile(
      context: context,
      childId: childId,
      childName: childName,
    );
  }

  void _openZoneOnMainMap(NotificationDetailModel detail) {
    final childUid = (detail.data['childUid'] ?? '').toString().trim();
    final lat = _readDouble(detail.data['lat'] ?? detail.data['latitude']);
    final lng = _readDouble(detail.data['lng'] ?? detail.data['longitude']);
    final zoneId = (detail.data['zoneId'] ?? '').toString().trim();
    final zoneName = (detail.data['zoneName'] ?? '').toString().trim();

    if (childUid.isEmpty && (lat == null || lng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong tim thay vi tri de mo ban do'),
        ),
      );
      return;
    }

    mapFocusNotifier.value = MapFocusRequest(
      childUid: childUid.isEmpty ? null : childUid,
      lat: lat,
      lng: lng,
      zoneId: zoneId.isEmpty ? null : zoneId,
      zoneName: zoneName.isEmpty ? null : zoneName,
      openSheet: false,
    );

    activeTabNotifier.value = mapTabIndexNotifier.value;
  }


  String _formatTimeAgo(DateTime? time) {
    if (time == null) return "";

    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} phút trước";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} giờ trước";
    } else {
      return "${diff.inDays} ngày trước";
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationVM>();
    final detail = vm.notificationDetail;
    if (detail == null) return LoadingOverlay();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Chi tiết thông báo",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ===== HEADER BLOCK =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        /// ICON
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _resolveTopBgColor(detail),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            _resolveTopIcon(detail),
                            size: 36,
                            color: _resolveTopIconColor(detail),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TITLE
                        Text(
                          _buildDisplayTitle(detail),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// TIME
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              detail.timeDisplay,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ===== DETAIL CARD =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x07000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: const Text(
                            "CHI TIẾT",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        NotificationDetailBody(detail: detail,
                          onZoneViewMap: detail.notificationType == NotificationType.zone
                              ? () => _openZoneOnMainMap(detail)
                              : null,
                          onZonePhone: detail.notificationType == NotificationType.zone
                              ? () => _handleZonePhone(detail)
                              : null,
                          onOpenSafeRouteTracking:
                              detail.notificationType == NotificationType.tracking
                                  ? () => _handleOpenSafeRouteTracking(detail)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
