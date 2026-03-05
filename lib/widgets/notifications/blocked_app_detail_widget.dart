import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class BlockedAppDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const BlockedAppDetailWidget({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
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
          ),
          const SizedBox(height: 20),
          _buildWarningBox(),
          const SizedBox(height: 30),
          _buildActionButton(context),
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
          _buildInfoRow(Icons.person_outline, "Tài khoản", displayName),
          _buildInfoRow(Icons.apps, "Ứng dụng", appName),
          _buildInfoRow(Icons.access_time, "Thời điểm", blockedAt),
          _buildInfoRow(Icons.schedule, "Khung giờ cho phép", "$allowedFrom - $allowedTo"),
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

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Ứng dụng đã bị chặn tự động bởi hệ thống.",
              style: TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
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
        child: const Text(
          "Xem cấu hình thời gian",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}