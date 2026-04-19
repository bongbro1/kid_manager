import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/models/user/user_types.dart';

class ScheduleImportDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const ScheduleImportDetailWidget({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = detail.data;

    final childName = (data['childName'] ?? l10n.notificationsDefaultChildName)
        .toString()
        .trim();
    final importCount = (data['importCount'] ?? '').toString().trim();
    final actorRole = tryParseUserRole(data['actorRole']);
    final actorDisplayName =
        ((data['actorDisplayName'] ?? data['actorChildName']) ?? '')
            .toString()
            .trim();

    final actorText = switch (actorRole) {
      UserRole.parent => l10n.notificationsActorParent,
      UserRole.guardian =>
        actorDisplayName.isEmpty
            ? l10n.notificationsActorParent
            : actorDisplayName,
      UserRole.child =>
        actorDisplayName.isEmpty
            ? l10n.notificationsActorChild
            : actorDisplayName,
      null =>
        actorDisplayName.isEmpty
            ? l10n.notificationsActorChild
            : actorDisplayName,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile(
          context: context,
          icon: Icons.person_outline_rounded,
          label: l10n.notificationsImportOperatorLabel,
          value: actorText,
        ),
        const SizedBox(height: 14),
        _infoTile(
          context: context,
          icon: Icons.child_care_rounded,
          label: l10n.notificationsChildLabel,
          value: childName.isEmpty
              ? l10n.notificationsDefaultChildName
              : childName,
        ),
        const SizedBox(height: 14),
        _infoTile(
          context: context,
          icon: Icons.playlist_add_check_circle_rounded,
          label: l10n.notificationsImportAddedCountLabel,
          value: importCount.isEmpty ? '0' : importCount,
        ),
      ],
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
}
