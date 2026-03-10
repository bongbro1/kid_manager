import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class ScheduleImportDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const ScheduleImportDetailWidget({
    super.key,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final data = detail.data;

    final childName = (data['childName'] ?? 'Bé').toString().trim();
    final importCount = (data['importCount'] ?? '').toString().trim();
    final actorRole = (data['actorRole'] ?? '').toString().toLowerCase();
    final actorChildName = (data['actorChildName'] ?? '').toString().trim();

    final actorText = actorRole == 'parent'
        ? 'Ba/Mẹ'
        : (actorChildName.isEmpty ? 'Con' : actorChildName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile(
          icon: Icons.person_outline_rounded,
          label: 'Người thao tác',
          value: actorText,
        ),
        const SizedBox(height: 14),
        _infoTile(
          icon: Icons.child_care_rounded,
          label: 'Bé',
          value: childName.isEmpty ? 'Bé' : childName,
        ),
        const SizedBox(height: 14),
        _infoTile(
          icon: Icons.playlist_add_check_circle_rounded,
          label: 'Số lịch đã thêm',
          value: importCount.isEmpty ? '0' : importCount,
        ),
      ],
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
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF475569),
          ),
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