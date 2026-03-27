import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/location/map_focus_bus.dart';
import 'package:kid_manager/features/safe_route/presentation/pages/tracking_page.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_access.dart';
import 'package:kid_manager/helpers/phone/phone_helps.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';
import 'package:kid_manager/services/notifications/zone_i18n.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/notifications/notification_detail_body.dart';
import 'package:kid_manager/widgets/notifications/notification_text_resolver.dart';
import 'package:provider/provider.dart';

class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.item});

  final AppNotification item;

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
    final l10n = AppLocalizations.of(context);
    final rawTitle = detail.title.trim();

    if (rawTitle.startsWith('tracking.')) {
      return trackingTitleFromKey(l10n, rawTitle);
    }

    if (detail.notificationType == NotificationType.schedule ||
        detail.notificationType == NotificationType.memoryDay ||
        detail.notificationType == NotificationType.importExcel) {
      final resolved = resolveNotificationTitle(
        l10n: l10n,
        type: detail.notificationType,
        data: detail.data,
        fallbackTitle: detail.title,
      );
      if (resolved.isNotEmpty) {
        return resolved;
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
                l10n.notificationChildFallback)
            .toString();

    if (zoneType == 'danger' && action == 'enter') {
      return l10n.notificationZoneEnteredDangerTitle(childName);
    }
    if (zoneType == 'safe' && action == 'exit') {
      return l10n.notificationZoneExitedSafeTitle(childName);
    }
    if (zoneType == 'danger' && action == 'exit') {
      return l10n.notificationZoneExitedDangerTitle(childName);
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
  SafeRouteAccessResult? _resolveKnownSafeRouteAccess(String childId) {
    final userVm = context.read<UserVm>();
    final actor = userVm.me;
    if (actor == null) {
      return null;
    }

    for (final member in <AppUser>[
      ...userVm.locationMembers,
      ...userVm.children,
      ...userVm.familyMembers,
    ]) {
      if (member.uid != childId) {
        continue;
      }

      return evaluateSafeRouteAccess(
        accessControl: context.read<AccessControlService>(),
        actor: actor,
        child: member,
        requireManageChild: true,
        requireViewLocation: true,
      );
    }

    return null;
  }

  Future<void> _handleOpenSafeRouteTracking(NotificationDetailModel detail) async {
    final childId = (detail.data['childUid'] ?? detail.data['childId'] ?? '')
        .toString()
        .trim();

    if (childId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).notificationTrackingDetailNotFound,
          ),
        ),
      );
      return;
    }

    final access = await loadSafeRouteAccess(
      childId: childId,
      profileRepository: context.read<ProfileRepository>(),
      accessControl: context.read<AccessControlService>(),
      requireManageChild: true,
      requireViewLocation: true,
    );
    if (!access.isAllowed) {
      if (!mounted) return;
      final issue = access.issue;
      final message = issue == null
          ? AppLocalizations.of(context).safeRouteErrorLoginAgain
          : resolveSafeRouteAccessMessage(AppLocalizations.of(context), issue);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
      for (final member in <dynamic>[
        ...userVm.locationMembers,
        ...userVm.children,
        ...userVm.familyMembers,
      ]) {
        if (member.uid == childId) {
          final avatarUrl = member.avatarUrl?.trim() ?? '';
          return avatarUrl.isEmpty ? null : avatarUrl;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _handleZonePhone(NotificationDetailModel detail) async {
    final l10n = AppLocalizations.of(context);
    final childId = (detail.data['childUid'] ?? '').toString().trim();
    final childName =
        (detail.data['childName'] ??
                detail.data['displayName'] ??
                detail.data['name'] ??
                l10n.notificationChildFallback)
            .toString();

    if (childId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationChildInfoNotFound)),
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
    final l10n = AppLocalizations.of(context);
    final childUid = (detail.data['childUid'] ?? '').toString().trim();
    final lat = _readDouble(detail.data['lat'] ?? detail.data['latitude']);
    final lng = _readDouble(detail.data['lng'] ?? detail.data['longitude']);
    final zoneId = (detail.data['zoneId'] ?? '').toString().trim();
    final zoneName = (detail.data['zoneName'] ?? '').toString().trim();

    if (childUid.isEmpty && (lat == null || lng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notificationMapLocationNotFound)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<NotificationVM>();
    final detail = vm.notificationDetail;
    final knownSafeRouteAccess = detail == null ||
            detail.notificationType != NotificationType.tracking
        ? null
        : _resolveKnownSafeRouteAccess(
            (detail.data['childUid'] ?? detail.data['childId'] ?? '')
                .toString()
                .trim(),
          );
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (detail == null) return LoadingOverlay();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: true,
        title: Text(
          l10n.notificationDetailTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            height: 1.56,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      children: [
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
                        Text(
                          _buildDisplayTitle(detail),
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: theme.brightness == Brightness.dark
                                  ? colorScheme.onSurface.withOpacity(0.7)
                                  : colorScheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              detail.formatTimeDisplay(l10n),
                              style: textTheme.bodyMedium?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? colorScheme.onSurface.withOpacity(0.8)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.15),
                      ),
                      boxShadow: theme.brightness == Brightness.light
                          ? const [
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
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Text(
                            l10n.notificationDetailSectionTitle,
                            style: textTheme.labelMedium?.copyWith(
                              color: theme.brightness == Brightness.dark
                                  ? colorScheme.onSurface
                                  : colorScheme.outline,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        NotificationDetailBody(
                          detail: detail,
                          onZoneViewMap:
                              detail.notificationType == NotificationType.zone
                                  ? () => _openZoneOnMainMap(detail)
                                  : null,
                          onZonePhone:
                              detail.notificationType == NotificationType.zone
                                  ? () => _handleZonePhone(detail)
                                  : null,
                          onOpenSafeRouteTracking:
                              detail.notificationType == NotificationType.tracking &&
                                      (knownSafeRouteAccess == null ||
                                          knownSafeRouteAccess.isAllowed)
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
