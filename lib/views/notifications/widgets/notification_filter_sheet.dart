import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';

class NotificationFilterSheet extends StatelessWidget {
  final NotificationFilter activeFilter;
  final NotificationReadFilter activeReadFilter;
  final ValueChanged<NotificationFilter> onSelected;
  final ValueChanged<NotificationReadFilter> onReadFilterSelected;

  const NotificationFilterSheet({
    super.key,
    required this.activeFilter,
    required this.activeReadFilter,
    required this.onSelected,
    required this.onReadFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final filters = [
      (NotificationFilter.all, l10n.notificationFilterAll, Icons.notifications),
      (
        NotificationFilter.activity,
        l10n.notificationFilterActivity,
        Icons.school,
      ),
      (NotificationFilter.alert, l10n.notificationFilterAlert, Icons.warning),
      (
        NotificationFilter.reminder,
        l10n.notificationFilterReminder,
        Icons.event,
      ),
      (
        NotificationFilter.system,
        l10n.notificationFilterSystem,
        Icons.campaign,
      ),
    ];

    final readFilters = [
      (
        NotificationReadFilter.all,
        l10n.notificationReadFilterAll,
        Icons.inbox_rounded,
      ),
      (
        NotificationReadFilter.unread,
        l10n.notificationReadFilterUnread,
        Icons.mark_email_unread_rounded,
      ),
      (
        NotificationReadFilter.read,
        l10n.notificationReadFilterRead,
        Icons.drafts_rounded,
      ),
    ];

    return AppOverlaySheet(
      showHandle: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),

            Text(
              l10n.notificationFilterTitle,
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.notificationFilterTypeTitle,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...filters.expand((f) {
              final filter = f.$1;
              final label = f.$2;
              final icon = f.$3;
              final isSelected = activeFilter == filter;

              final itemColor = isSelected ? scheme.primary : scheme.onSurface;

              return [
                _NotificationFilterItem(
                  icon: icon,
                  label: label,
                  color: itemColor,
                  isSelected: isSelected,
                  onTap: () => onSelected(filter),
                ),
                const SizedBox(height: 10),
              ];
            }),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.notificationReadFilterTitle,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...readFilters.expand((f) {
              final filter = f.$1;
              final label = f.$2;
              final icon = f.$3;
              final isSelected = activeReadFilter == filter;

              final itemColor = isSelected ? scheme.primary : scheme.onSurface;

              return [
                _NotificationFilterItem(
                  icon: icon,
                  label: label,
                  color: itemColor,
                  isSelected: isSelected,
                  onTap: () => onReadFilterSelected(filter),
                ),
                const SizedBox(height: 10),
              ];
            }),
          ],
        ),
      ),
    );
  }
}

class _NotificationFilterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _NotificationFilterItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: isSelected
          ? scheme.primary.withValues(alpha: 0.08)
          : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.35)
                  : scheme.outline.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, color: scheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
