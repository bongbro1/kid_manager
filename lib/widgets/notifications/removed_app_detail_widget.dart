import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class RemovedAppDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const RemovedAppDetailWidget({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = detail.data;

    final childName = (data["childName"] ?? "").toString();
    final appName = (data["appName"] ?? "").toString();
    final removedAt = (data["removedAt"] ?? "").toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            childName: childName,
            appName: appName,
            removedAt: removedAt,
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
    required String childName,
    required String appName,
    required String removedAt,
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
            l10n.notificationsRemovedDeviceOfLabel,
            childName,
          ),
          _buildInfoRow(Icons.apps, l10n.notificationsRemovedAppLabel, appName),
          _buildInfoRow(
            Icons.delete_outline,
            l10n.notificationsRemovedAtLabel,
            removedAt,
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
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.notificationsRemovedWarningMessage,
              style: const TextStyle(
                color: Color(0xFF7F1D1D),
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
          backgroundColor: const Color(0xFFDC2626),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          // TODO: mở màn hình quản lý app
        },
        child: Text(
          l10n.notificationsRemovedViewAppsButton,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
