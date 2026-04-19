import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/services/notifications/tracking_location_notification_text.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';
import 'package:kid_manager/services/notifications/zone_i18n.dart';
import 'package:kid_manager/widgets/notifications/birthday_notification_experience.dart';
import 'package:kid_manager/widgets/notifications/notification_text_resolver.dart';

class NotificationItemView extends StatelessWidget {
  const NotificationItemView({super.key, required this.item, this.onTap});

  final AppNotification item;
  final VoidCallback? onTap;

  String _timeAgo(BuildContext context, DateTime? date) {
    if (date == null) return '';
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return l10n.notificationJustNow;
    if (diff.inMinutes < 60) {
      return l10n.notificationMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.notificationHoursAgo(diff.inHours);
    }

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (item.notificationType == NotificationType.birthday) {
      return BirthdayNotificationCard(item: item, onTap: onTap);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final style = item.notificationType == NotificationType.tracking
        ? resolveTrackingNotificationStyle(
            title: item.title,
            data: item.data,
            fallback: item.notificationType.style,
          )
        : item.notificationType.style;

    final titleText = _displayTitle(context, item);
    final bodyText = _displayBody(context, item);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border.all(color: colorScheme.outline.withOpacity(0.18)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: theme.brightness == Brightness.light
                  ? const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ICON
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.bgColor,
                    border: Border.all(color: style.borderColor),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(style.icon, color: style.iconColor, size: 22),
                ),
                const SizedBox(width: 12),

                /// CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// TITLE + TIME
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Text(
                              titleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: Theme.of(
                                  context,
                                ).appTypography.itemTitle.fontSize!,
                                height: 1.19,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                _timeAgo(context, item.createdAt),
                                textAlign: TextAlign.right,
                                style: textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: Theme.of(
                                    context,
                                  ).appTypography.meta.fontSize!,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      /// MESSAGE
                      Text(
                        bodyText,
                        maxLines: 1,
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.onSurface.withOpacity(0.9)
                              : colorScheme.onSurfaceVariant,
                          height: 1.17,
                          fontSize: Theme.of(
                            context,
                          ).appTypography.supporting.fontSize!,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.75,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!item.isRead)
            Positioned(
              right: 16,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _displayTitle(BuildContext context, AppNotification item) {
  final l10n = AppLocalizations.of(context);
  if (item.notificationType == NotificationType.schedule ||
      item.notificationType == NotificationType.memoryDay ||
      item.notificationType == NotificationType.importExcel) {
    final resolved = resolveNotificationTitle(
      l10n: l10n,
      type: item.notificationType,
      data: item.data,
      fallbackTitle: item.title,
    );
    if (resolved.isNotEmpty) {
      return resolved;
    }
  }

  final t = item.title.trim();

  if (t.startsWith('zone.')) {
    switch (t) {
      case 'zone.enter.danger.parent':
        return l10n.zone_enter_danger_parent;
      case 'zone.exit.danger.parent':
        return l10n.zone_exit_danger_parent;
      case 'zone.enter.safe.parent':
        return l10n.zone_enter_safe_parent;
      case 'zone.exit.safe.parent':
        return l10n.zone_exit_safe_parent;
      case 'zone.enter.danger.child':
        return l10n.zone_enter_danger_child;
      case 'zone.exit.danger.child':
        return l10n.zone_exit_danger_child;
      case 'zone.enter.safe.child':
        return l10n.zone_enter_safe_child;
      case 'zone.exit.safe.child':
        return l10n.zone_exit_safe_child;
      default:
        return l10n.zone_default;
    }
  }

  if (t.startsWith('tracking.')) {
    return trackingTitleFromKey(l10n, t);
  }

  return t.isEmpty ? l10n.zone_default : t;
}

String _displayBody(BuildContext context, AppNotification item) {
  final l10n = AppLocalizations.of(context);

  if (isTrackingLocationStatusNotification(
    type: item.type,
    title: item.title,
    data: item.data,
  )) {
    return resolveTrackingLocationStatusBody(
      l10n,
      title: item.title,
      fallbackBody: item.body,
      data: item.data,
    );
  }

  if (item.notificationType == NotificationType.schedule ||
      item.notificationType == NotificationType.memoryDay ||
      item.notificationType == NotificationType.importExcel) {
    final resolved = resolveNotificationBody(
      l10n: l10n,
      type: item.notificationType,
      data: item.data,
      fallbackBody: item.body,
    );
    if (resolved.isNotEmpty) {
      return resolved;
    }
  }

  return item.body;
}
