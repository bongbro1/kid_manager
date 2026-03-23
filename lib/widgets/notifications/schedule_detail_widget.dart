import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../models/notifications/notification_detail_model.dart';
import '../../viewmodels/schedule/schedule_vm.dart';
import 'package:kid_manager/core/app_route_observer.dart';

class ScheduleDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const ScheduleDetailWidget({super.key, required this.detail});

  String _actionText(AppLocalizations l10n, String action) {
    switch (action) {
      case 'created':
        return l10n.notificationsActionCreated;
      case 'updated':
        return l10n.notificationsActionUpdated;
      case 'deleted':
        return l10n.notificationsActionDeleted;
      case 'restored':
        return l10n.notificationsActionRestored;
      default:
        return l10n.notificationsActionChanged;
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline_rounded;
      case 'updated':
        return Icons.edit_calendar_rounded;
      case 'deleted':
        return Icons.delete_outline_rounded;
      case 'restored':
        return Icons.restore_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _actionColor(BuildContext context, String action) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (action) {
      case 'created':
        return colorScheme.primary;
      case 'updated':
        return Colors.deepPurple;
      case 'deleted':
        return colorScheme.error;
      case 'restored':
        return Colors.green;
      default:
        return colorScheme.onSurface.withOpacity(0.7);
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final data = detail.data;

    final action = (data['action'] ?? '').toString();
    final childName =
        (data['childName'] ?? l10n.notificationsDefaultChildName).toString();
    final scheduleTitle = (data['scheduleTitle'] ?? '').toString();
    final date = (data['date'] ?? '').toString();
    final startAt = (data['startAt'] ?? '').toString();
    final endAt = (data['endAt'] ?? '').toString();

    final ownerParentUid = (data['ownerParentUid'] ?? '').toString();
    final childId = (data['childId'] ?? '').toString();
    final dateIso = (data['dateIso'] ?? '').toString();

    final isDeleted = action == 'deleted';
    final canOpenSchedule =
        ownerParentUid.isNotEmpty && childId.isNotEmpty && dateIso.isNotEmpty;

    final actionColor = _actionColor(context, action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _actionBadge(
          context: context,
          text: _actionText(l10n, action),
          icon: _actionIcon(action),
          color: actionColor,
        ),
        const SizedBox(height: 18),

        _infoTile(
          context: context,
          icon: Icons.menu_book_rounded,
          label: l10n.notificationsScheduleTitleLabel,
          value: scheduleTitle.isEmpty
              ? l10n.notificationsNoTitle
              : scheduleTitle,
        ),
        const SizedBox(height: 14),

        _infoTile(
          context: context,
          icon: Icons.child_care_rounded,
          label: l10n.notificationsChildNameLabel,
          value: childName,
        ),
        const SizedBox(height: 18),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.35),
            ),
          ),
          child: Column(
            children: [
              _timeRow(
                context: context,
                icon: Icons.calendar_today_rounded,
                label: l10n.notificationsDateLabel,
                value: date,
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: colorScheme.outline.withOpacity(0.25),
              ),
              const SizedBox(height: 12),
              _timeRow(
                context: context,
                icon: Icons.access_time_rounded,
                label: l10n.notificationsTimeLabel,
                value: '$startAt - $endAt',
              ),
            ],
          ),
        ),

        if (!isDeleted) ...[
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canOpenSchedule
                  ? () async {
                      final targetDate = _parseDate(dateIso);
                      if (targetDate == null) return;

                      final scheduleVm = context.read<ScheduleViewModel>();

                      await scheduleVm.openFromNotification(
                        ownerParentUid: ownerParentUid,
                        childId: childId,
                        date: targetDate,
                      );

                      if (!context.mounted) return;

                      Navigator.of(context).popUntil((route) => route.isFirst);
                      activeTabNotifier.value = scheduleTabIndexNotifier.value;
                    }
                  : null,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: Text(
                l10n.notificationsViewScheduleButton,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                disabledBackgroundColor: colorScheme.outline.withOpacity(0.25),
                disabledForegroundColor: colorScheme.onSurface.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionBadge({
    required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.65),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.onSurface.withOpacity(0.65),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}