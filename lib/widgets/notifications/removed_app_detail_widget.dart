import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:provider/provider.dart';

class RemovedAppDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const RemovedAppDetailWidget({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationVM>();

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
            childName: childName!,
            appName: appName!,
            removedAt: removedAt,
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
    required String childName,
    required String appName,
    required String removedAt,
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
          _buildInfoRow(Icons.person_outline, "Thiết bị của", childName),
          _buildInfoRow(Icons.apps, "Ứng dụng đã gỡ", appName),
          _buildInfoRow(Icons.delete_outline, "Thời điểm gỡ", removedAt),
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
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Ứng dụng đã bị gỡ khỏi thiết bị. Hãy kiểm tra nếu đây là ứng dụng bị quản lý.",
              style: TextStyle(
                color: Color(0xFF7F1D1D),
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
          backgroundColor: const Color(0xFFDC2626),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          // TODO: mở màn hình quản lý app
        },
        child: const Text(
          "Xem danh sách ứng dụng",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}
