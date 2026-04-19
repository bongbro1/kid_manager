import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class BlockedAppDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const BlockedAppDetailWidget({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = detail.data;

    final studentName = (data["studentName"] ?? "").toString();
    final appName = (data["appName"] ?? "").toString();
    final blockedAt = (data["blockedAt"] ?? "").toString();
    final allowedFrom = (data["allowedFrom"] ?? "").toString();
    final allowedTo = (data["allowedTo"] ?? "").toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            context: context,
            displayName: studentName,
            appName: appName,
            blockedAt: blockedAt,
            allowedFrom: allowedFrom,
            allowedTo: allowedTo,
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          _buildWarningBox(context, l10n),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String displayName,
    required String appName,
    required String blockedAt,
    required String allowedFrom,
    required String allowedTo,
    required AppLocalizations l10n,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context,
            Icons.person_outline,
            l10n.notificationsBlockedAccountLabel,
            displayName,
          ),
          _buildInfoRow(
            context,
            Icons.apps,
            l10n.notificationsBlockedAppLabel,
            appName,
          ),
          _buildInfoRow(
            context,
            Icons.access_time,
            l10n.notificationsBlockedTimeLabel,
            blockedAt,
          ),
          if (allowedFrom.isNotEmpty)
            _buildInfoRow(
              context,
              Icons.schedule,
              l10n.notificationsBlockedAllowedWindowLabel,
              "$allowedFrom - $allowedTo",
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: theme.brightness == Brightness.dark
                ? colorScheme.onSurface.withOpacity(0.8)
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.brightness == Brightness.dark
                  ? colorScheme.onSurface.withOpacity(0.9)
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.onError),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.notificationsBlockedWarningMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onError,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          // TODO: Navigate
        },
        child: Text(
          l10n.notificationsBlockedViewConfigButton,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
