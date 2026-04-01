import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class MemoryDayDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const MemoryDayDetailWidget({super.key, required this.detail});

  String _actionText(AppLocalizations l10n, String action) {
    switch (action) {
      case 'created':
        return l10n.notificationsActionCreated;
      case 'updated':
        return l10n.notificationsActionUpdated;
      case 'deleted':
        return l10n.notificationsActionDeleted;
      case 'reminder':
        return l10n.notificationFilterReminder;
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
      case 'reminder':
        return Icons.notifications_active_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'created':
        return const Color(0xFF0D59F2);
      case 'updated':
        return const Color(0xFF7C3AED);
      case 'deleted':
        return const Color(0xFFDC2626);
      case 'reminder':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = detail.data;

    final action = (data['action'] ?? '').toString();
    final memoryDayTitle = (data['memoryDayTitle'] ?? '').toString().trim();
    final date = (data['date'] ?? '').toString();
    final note = (data['note'] ?? '').toString().trim();
    final daysUntil = int.tryParse((data['daysUntil'] ?? '').toString());
    final repeatYearlyRaw = (data['repeatYearly'] ?? '')
        .toString()
        .toLowerCase();

    final repeatYearly = repeatYearlyRaw == 'true';
    final actionColor = _actionColor(action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _actionBadge(
          text: _actionText(l10n, action),
          icon: _actionIcon(action),
          color: actionColor,
        ),
        const SizedBox(height: 18),

        _infoTile(
          icon: Icons.star_border_rounded,
          label: l10n.memoryDayFormTitleLabel,
          value: memoryDayTitle.isEmpty
              ? l10n.notificationsNoTitle
              : memoryDayTitle,
        ),
        const SizedBox(height: 14),

        _infoTile(
          icon: Icons.calendar_today_rounded,
          label: l10n.memoryDayFormDateLabel,
          value: date.isEmpty ? '-' : date,
        ),
        const SizedBox(height: 14),

        _infoTile(
          icon: Icons.repeat_rounded,
          label: l10n.notificationsRepeatLabel,
          value: repeatYearly
              ? l10n.notificationsRepeatYearly
              : l10n.notificationsRepeatNone,
        ),

        if (action == 'reminder' && daysUntil != null) ...[
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.timelapse_rounded,
            label: l10n.memoryDayReminderLabel,
            value: daysUntil == 0
                ? l10n.memoryDayToday
                : l10n.memoryDayDaysLeft(daysUntil),
          ),
        ],

        if (note.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5EAF2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.memoryDayFormNoteLabel,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  note,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionBadge({
    required String text,
    required IconData icon,
    required Color color,
  }) {
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
            style: TextStyle(
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
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
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
}
