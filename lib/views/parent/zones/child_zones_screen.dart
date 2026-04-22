import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/features/subscription/subscription_quota_gate.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/viewmodels/zones/parent_zones_vm.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

import 'edit_zone_screen.dart';

class ChildZonesScreen extends StatelessWidget {
  final String childId;
  const ChildZonesScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentZonesVm(
        ZoneRepository(),
        context.read<ProfileRepository>(),
        context.read<AccessControlService>(),
      )..bind(childId),
      child: _ChildZonesBody(childId: childId),
    );
  }
}

enum _ZoneBusyAction { creating, editing, deleting }

class _ChildZonesBody extends StatefulWidget {
  final String childId;
  const _ChildZonesBody({required this.childId});

  @override
  State<_ChildZonesBody> createState() => _ChildZonesBodyState();
}

class _ChildZonesBodyState extends State<_ChildZonesBody> {
  _ZoneBusyAction? _busyAction;
  String? _busyZoneId;

  String get childId => widget.childId;

  bool get _isBusy => _busyAction != null;

  void _startBusy(_ZoneBusyAction action, {String? zoneId}) {
    if (!mounted) return;
    setState(() {
      _busyAction = action;
      _busyZoneId = zoneId;
    });
  }

  void _stopBusy() {
    if (!mounted) return;
    setState(() {
      _busyAction = null;
      _busyZoneId = null;
    });
  }

  String _busyMessage(BuildContext context) {
    final isVi =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';

    switch (_busyAction) {
      case _ZoneBusyAction.creating:
        return isVi ? 'Đang thêm vùng...' : 'Creating zone...';
      case _ZoneBusyAction.editing:
        return isVi ? 'Đang cập nhật vùng...' : 'Updating zone...';
      case _ZoneBusyAction.deleting:
        return isVi ? 'Đang xóa vùng...' : 'Deleting zone...';
      case null:
        return isVi ? 'Đang xử lý...' : 'Processing...';
    }
  }

  // ==================== Dialog Methods ====================

  Future<void> _showNotice({
    required BuildContext context,
    required DialogType type,
    String? title,
    String? message,
  }) async {
    if (!context.mounted) return;

    final config = DialogConfig.from(type);
    final titleText = (title ?? '').trim();
    final messageText = (message ?? '').trim();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    Timer? autoDismissTimer;

    try {
      autoDismissTimer = Timer(const Duration(seconds: 2), () {
        if (!rootNavigator.mounted || !rootNavigator.canPop()) {
          return;
        }
        rootNavigator.pop();
      });

      await showGeneralDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        barrierLabel: l10n.accessibilityNoticeBarrierLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 310),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      decoration: BoxDecoration(
                        color: locationPanelColor(scheme),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          config.iconBuilder(),
                          const SizedBox(height: 18),
                          Text(
                            titleText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: Theme.of(
                                context,
                              ).appTypography.screenTitle.fontSize!,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (messageText.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              messageText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: Theme.of(
                                  context,
                                ).appTypography.body.fontSize!,
                                height: 1.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          );

          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      autoDismissTimer?.cancel();
    }
  }

  Future<bool> _showDeleteConfirm(BuildContext context, GeoZone zone) async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: locationPanelColor(scheme),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.zonesDeleteConfirmTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: Theme.of(
                    context,
                  ).appTypography.screenTitle.fontSize!,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.zonesDeleteConfirmMessage,
              style: TextStyle(
                fontSize: Theme.of(context).appTypography.itemTitle.fontSize!,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: locationPanelMutedColor(scheme),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: locationPanelBorderColor(scheme)),
              ),
              child: Text(
                '"${zone.name}"',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Theme.of(context).appTypography.body.fontSize!,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.cancelButton,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.zonesDeleteButton,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // ==================== Handler Methods ====================

  Future<void> _handleCreateZone(
    BuildContext context,
    List<GeoZone> zones,
  ) async {
    final l10n = AppLocalizations.of(context);

    final res = await Navigator.push<GeoZone>(
      context,
      AppPageTransitions.route(
        builder: (_) =>
            EditZoneScreen(childId: childId, zone: null, existingZones: zones),
      ),
    );

    if (res == null || !context.mounted) return;

    Object? actionError;
    _startBusy(_ZoneBusyAction.creating);
    try {
      await context.read<ParentZonesVm>().save(childId, res);
    } catch (error) {
      actionError = error;
    } finally {
      _stopBusy();
    }

    if (!context.mounted) return;
    context.read<ParentZonesVm>().clearError();

    if (actionError == null) {
      await _showNotice(
        context: context,
        type: DialogType.success,
        title: l10n.zonesCreateSuccessTitle,
        message: l10n.zonesCreateSuccessMessage(res.name),
      );
      return;
    }

    final quota = SubscriptionQuotaGate.resolve(actionError);
    if (quota?.feature == SubscriptionQuotaFeature.zone) {
      await SubscriptionQuotaGate.showVipUpgradeDialog(context, quota: quota!);
      return;
    }

    await _showNotice(
      context: context,
      type: DialogType.error,
      title: l10n.zonesFailedTitle,
      message: l10n.zonesCreateFailedMessage,
    );
  }

  Future<void> _handleEditZone(
    BuildContext context,
    GeoZone zone,
    List<GeoZone> zones,
  ) async {
    final l10n = AppLocalizations.of(context);

    final edited = await Navigator.push<GeoZone>(
      context,
      AppPageTransitions.route(
        builder: (_) =>
            EditZoneScreen(childId: childId, zone: zone, existingZones: zones),
      ),
    );
    if (edited == null || !context.mounted) return;

    Object? actionError;
    _startBusy(_ZoneBusyAction.editing, zoneId: zone.id);
    try {
      await context.read<ParentZonesVm>().save(childId, edited);
    } catch (error) {
      actionError = error;
    } finally {
      _stopBusy();
    }

    if (!context.mounted) return;
    context.read<ParentZonesVm>().clearError();

    if (actionError == null) {
      await _showNotice(
        context: context,
        type: DialogType.success,
        title: l10n.zonesEditSuccessTitle,
        message: l10n.zonesEditSuccessMessage,
      );
      return;
    }

    await _showNotice(
      context: context,
      type: DialogType.error,
      title: l10n.zonesFailedTitle,
      message: l10n.zonesEditFailedMessage,
    );
  }

  Future<void> _handleDeleteZone(BuildContext context, GeoZone zone) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _showDeleteConfirm(context, zone);
    if (!confirmed || !context.mounted) return;

    Object? actionError;
    _startBusy(_ZoneBusyAction.deleting, zoneId: zone.id);
    try {
      await context.read<ParentZonesVm>().delete(childId, zone.id);
    } catch (error) {
      actionError = error;
    } finally {
      _stopBusy();
    }

    if (!context.mounted) return;
    context.read<ParentZonesVm>().clearError();

    if (actionError == null) {
      await _showNotice(
        context: context,
        type: DialogType.success,
        title: l10n.zonesDeleteSuccessTitle,
        message: l10n.zonesDeleteSuccessMessage,
      );
      return;
    }

    await _showNotice(
      context: context,
      type: DialogType.error,
      title: l10n.zonesFailedTitle,
      message: l10n.zonesDeleteFailedMessage,
    );
  }

  // ==================== Build Methods ====================

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: locationPanelHighlightColor(scheme),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 48,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.zonesEmptyTitle,
            style: TextStyle(
              fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.zonesEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Theme.of(context).appTypography.body.fontSize!,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _zoneTypeLabel(AppLocalizations l10n, ZoneType type) {
    return type == ZoneType.danger ? l10n.zonesTypeDanger : l10n.zonesTypeSafe;
  }

  Widget _buildBusyOverlay(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withValues(alpha: 0.18),
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: locationPanelColor(scheme),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
                const SizedBox(height: 14),
                Text(
                  _busyMessage(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Theme.of(
                      context,
                    ).appTypography.itemTitle.fontSize!,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneCard(
    BuildContext context,
    int index,
    GeoZone zone,
    ParentZonesVm vm,
  ) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDanger = zone.type == ZoneType.danger;
    final isDeletingThisZone =
        _busyAction == _ZoneBusyAction.deleting && _busyZoneId == zone.id;
    final color = isDanger ? Colors.red : Colors.green;
    final icon = isDanger ? Icons.warning_amber_rounded : Icons.home_rounded;

    return Container(
      decoration: BoxDecoration(
        color: locationPanelColor(scheme),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: zone.enabled
              ? color.withValues(alpha: 0.3)
              : locationPanelBorderColor(scheme),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: zone.enabled ? 0.08 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Theme.of(context).appTypography.title.fontSize!,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _zoneTypeLabel(l10n, zone.type),
                          style: TextStyle(
                            color: color,
                            fontSize: Theme.of(
                              context,
                            ).appTypography.meta.fontSize!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${zone.radiusM.toStringAsFixed(0)}m',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: Theme.of(
                            context,
                          ).appTypography.supporting.fontSize!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: zone.enabled,
                onChanged: _isBusy
                    ? null
                    : (v) => vm.toggleEnabled(childId, zone, v),
                activeThumbColor: color,
              ),
            ),
            SizedBox(
              width: 40,
              child: isDeletingThisZone
                  ? Padding(
                      padding: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : PopupMenuButton<String>(
                      enabled: !_isBusy,
                      offset: const Offset(-20, 0),
                      itemBuilder: (_) => [
                        PopupMenuItem<String>(
                          value: "edit",
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.zonesEditMenu),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: "delete",
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(l10n.zonesDeleteMenu),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (v) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (!context.mounted || _isBusy) return;
                          if (v == "edit") {
                            await _handleEditZone(context, zone, vm.zones);
                          } else if (v == "delete") {
                            await _handleDeleteZone(context, zone);
                          }
                        });
                      },
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 12,
      regular: 16,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: locationPanelColor(scheme),
        foregroundColor: scheme.onSurface,
        title: Text(
          l10n.zonesScreenTitle,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
            letterSpacing: -0.5,
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBusy
            ? null
            : () => _handleCreateZone(
                context,
                context.read<ParentZonesVm>().zones,
              ),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.zonesAddButton),
        elevation: 4,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      body: Consumer<ParentZonesVm>(
        builder: (context, vm, _) {
          final showBusyOverlay =
              vm.loading ||
              (_isBusy && _busyAction != _ZoneBusyAction.deleting);

          if (vm.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.zonesErrorWithMessage(vm.error ?? ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: Theme.of(
                        context,
                      ).appTypography.itemTitle.fontSize!,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final zones = vm.zones;

          if (zones.isEmpty) {
            return Stack(
              children: [
                _buildEmptyState(context),
                if (showBusyOverlay) _buildBusyOverlay(context),
              ],
            );
          }

          return Stack(
            children: [
              ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  100,
                ),
                itemCount: zones.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildZoneCard(context, i, zones[i], vm),
              ),
              if (showBusyOverlay) _buildBusyOverlay(context),
            ],
          );
        },
      ),
    );
  }
}
