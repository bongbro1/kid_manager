import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class NotificationPermissionScreen extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final bool busy;

  const NotificationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onOpenSettings,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const Spacer(),
          const Icon(
            Icons.notifications_active_rounded,
            size: 96,
            color: Color(0xFFE53935),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.permissionNotificationTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.permissionNotificationSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.permissionNotificationRecommendation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onAllow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.permissionNotificationAllowButton),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onOpenSettings,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.permissionOpenSettingsButton),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
