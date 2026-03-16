import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';
import 'package:kid_manager/services/notifications/zone_i18n.dart';
import 'package:kid_manager/widgets/notifications/birthday_notification_experience.dart';

class NotificationItemView extends StatelessWidget {
  const NotificationItemView({super.key, required this.item, this.onTap});

  final AppNotification item;
  final VoidCallback? onTap;

  String _timeAgo(DateTime? date) {
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';

    // >= 1 ngày → hiển thị giờ phút
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    if (item.notificationType == NotificationType.birthday) {
      return BirthdayNotificationCard(item: item, onTap: onTap);
    }

    final style = item.notificationType == NotificationType.tracking
        ? resolveTrackingNotificationStyle(
            title: item.title,
            data: item.data,
            fallback: item.notificationType.style,
          )
        : item.notificationType.style;
    final titleText = _displayTitle(context, item);

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
              color: Colors.white,
              border: Border.all(color: const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text(
                                _timeAgo(item.createdAt),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF0D59F2),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      /// MESSAGE
                      Text(
                        item.body,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.5,
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
                  color: const Color(0xFF0D59F2),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4C0D59F2),
                      blurRadius: 2,
                      offset: Offset(0, 1),
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
