import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/viewmodels/zones/parent_zones_vm.dart';

import 'edit_zone_screen.dart';

class ChildZonesScreen extends StatelessWidget {
  final String childId;
  const ChildZonesScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParentZonesVm(ZoneRepository())..bind(childId),
      child: _ChildZonesBody(childId: childId),
    );
  }
}

class _ChildZonesBody extends StatelessWidget {
  final String childId;
  const _ChildZonesBody({required this.childId});

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

    await showGeneralDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: 'notice',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
            Navigator.of(dialogContext, rootNavigator: true).pop();
          }
        });

        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 310,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (messageText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        messageText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
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
  }

  Future<bool> _showDeleteConfirm(BuildContext context, GeoZone zone) async {
    final l10n = AppLocalizations.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
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
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                '"${zone.name}"',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.black87,
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
              style: const TextStyle(color: Colors.grey),
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
      MaterialPageRoute(
        builder: (_) =>
            EditZoneScreen(childId: childId, zone: null, existingZones: zones),
      ),
    );

    if (res == null || !context.mounted) return;

    try {
      await context.read<ParentZonesVm>().save(childId, res);

      if (!context.mounted) return;
      await _showNotice(
        context: context,
        type: DialogType.success,
        title: l10n.zonesCreateSuccessTitle,
        message: l10n.zonesCreateSuccessMessage(res.name),
      );
    } catch (_) {
      if (!context.mounted) return;
      await _showNotice(
        context: context,
        type: DialogType.error,
        title: l10n.zonesFailedTitle,
        message: l10n.zonesCreateFailedMessage,
      );
    }
  }

  Future<void> _handleEditZone(
    BuildContext context,
    GeoZone zone,
    List<GeoZone> zones,
  ) async {
    final l10n = AppLocalizations.of(context);

    final edited = await Navigator.push<GeoZone>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditZoneScreen(childId: childId, zone: zone, existingZones: zones),
      ),
    );
    if (edited == null || !context.mounted) return;

    try {
      debugPrint('before save');
      await context.read<ParentZonesVm>().save(childId, edited);

      if (!context.mounted) return;
      await _showNotice(
        context: context,
        type: DialogType.success,
        title: l10n.zonesEditSuccessTitle,
        message: l10n.zonesEditSuccessMessage,
      );
    } catch (_) {
      if (!context.mounted) return;
      await _showNotice(
        context: context,
        type: DialogType.error,
        title: l10n.zonesFailedTitle,
        message: l10n.zonesEditFailedMessage,
      );
    }
  }

  Future<void> _handleDeleteZone(BuildContext context, GeoZone zone) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _showDeleteConfirm(context, zone);
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<ParentZonesVm>().delete(childId, zone.id);

      if (!context.mounted) return;
      await _showNotice(
        context: context,
        type: DialogType.success,
        title: l10n.zonesDeleteSuccessTitle,
        message: l10n.zonesDeleteSuccessMessage,
      );
    } catch (_) {
      if (!context.mounted) return;
      await _showNotice(
        context: context,
        type: DialogType.error,
        title: l10n.zonesFailedTitle,
        message: l10n.zonesDeleteFailedMessage,
      );
    }
  }

  // ==================== Build Methods ====================

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_outlined,
              size: 48,
              color: Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.zonesEmptyTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.zonesEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
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

  Widget _buildZoneCard(
    BuildContext context,
    int index,
    GeoZone zone,
    ParentZonesVm vm,
  ) {
    final l10n = AppLocalizations.of(context);
    final isDanger = zone.type == ZoneType.danger;
    final color = isDanger ? Colors.red : Colors.green;
    final icon = isDanger ? Icons.warning_amber_rounded : Icons.home_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: zone.enabled ? color.withOpacity(0.3) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(zone.enabled ? 0.08 : 0.02),
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
                color: color.withOpacity(0.12),
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
                    style: const TextStyle(
                      fontSize: 16,
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
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _zoneTypeLabel(l10n, zone.type),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${zone.radiusM.toStringAsFixed(0)}m',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
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
                onChanged: (v) => vm.toggleEnabled(childId, zone, v),
                activeColor: color,
              ),
            ),
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                offset: const Offset(-20, 0),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: "edit",
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: Colors.blue.shade600,
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
                    if (!context.mounted) return;
                    debugPrint('selected = $v');
                    if (v == "edit") {
                      debugPrint('go to edit');
                      await _handleEditZone(context, zone, vm.zones);
                    } else if (v == "delete") {
                      debugPrint('go to delete');
                      await _handleDeleteZone(context, zone);
                    }
                  });
                },
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey.shade600,
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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          l10n.zonesScreenTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _handleCreateZone(context, context.read<ParentZonesVm>().zones),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.zonesAddButton),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      body: Consumer<ParentZonesVm>(
        builder: (context, vm, _) {
          if (vm.loading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            );
          }

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
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                  ),
                ],
              ),
            );
          }

          final zones = vm.zones;

          if (zones.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: zones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildZoneCard(context, i, zones[i], vm),
          );
        },
      ),
    );
  }
}
