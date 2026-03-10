import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class MemoryDayDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const MemoryDayDetailWidget({
    super.key,
    required this.detail,
  });

  String _actionText(String action) {
    switch (action) {
      case 'created':
        return 'Đã thêm';
      case 'updated':
        return 'Đã chỉnh sửa';
      case 'deleted':
        return 'Đã xóa';
      default:
        return 'Đã thay đổi';
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
      default:
        return const Color(0xFF475569);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = detail.data;

    final action = (data['action'] ?? '').toString();
    final memoryDayTitle = (data['memoryDayTitle'] ?? '').toString().trim();
    final date = (data['date'] ?? '').toString();
    final note = (data['note'] ?? '').toString().trim();
    final repeatYearlyRaw = (data['repeatYearly'] ?? '').toString().toLowerCase();

    final repeatYearly = repeatYearlyRaw == 'true';
    final actionColor = _actionColor(action);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _actionBadge(
          text: _actionText(action),
          icon: _actionIcon(action),
          color: actionColor,
        ),
        const SizedBox(height: 18),

        _infoTile(
          icon: Icons.star_border_rounded,
          label: 'Tiêu đề',
          value: memoryDayTitle.isEmpty ? 'Không có tiêu đề' : memoryDayTitle,
        ),
        const SizedBox(height: 14),

        _infoTile(
          icon: Icons.calendar_today_rounded,
          label: 'Ngày',
          value: date.isEmpty ? '-' : date,
        ),
        const SizedBox(height: 14),

        _infoTile(
          icon: Icons.repeat_rounded,
          label: 'Lặp lại',
          value: repeatYearly ? 'Hằng năm' : 'Không lặp lại',
        ),

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
                const Row(
                  children: [
                    Icon(
                      Icons.notes_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ghi chú',
                      style: TextStyle(
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