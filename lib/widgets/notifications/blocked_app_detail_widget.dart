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
            displayName: studentName,
            appName: appName,
            blockedAt: blockedAt,
            allowedFrom: allowedFrom,
            allowedTo: allowedTo,
            l10n: l10n,
          ),
          const SizedBox(height: 20),
          _buildWarningBox(l10n),
          const SizedBox(height: 30),
          _buildActionButton(context, l10n),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String displayName,
    required String appName,
    required String blockedAt,
    required String allowedFrom,
    required String allowedTo,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.person_outline,
            l10n.notificationsBlockedAccountLabel,
            displayName,
          ),
          _buildInfoRow(Icons.apps, l10n.notificationsBlockedAppLabel, appName),
          _buildInfoRow(
            Icons.access_time,
            l10n.notificationsBlockedTimeLabel,
            blockedAt,
          ),
          if(allowedFrom != "")
            _buildInfoRow(
              Icons.schedule,
              l10n.notificationsBlockedAllowedWindowLabel,
              "$allowedFrom - $allowedTo",
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.notificationsBlockedWarningMessage,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
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
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }
}
