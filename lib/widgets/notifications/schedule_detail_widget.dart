import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/app_colors.dart';

import '../../core/storage_keys.dart';
import '../../models/notifications/notification_detail_model.dart';
import '../../services/storage_service.dart';
import '../../viewmodels/schedule/schedule_vm.dart';
import 'package:kid_manager/core/app_route_observer.dart';

class ScheduleDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;

  const ScheduleDetailWidget({
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
      case 'restored':
        return 'Đã khôi phục';
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
      case 'restored':
        return Icons.restore_rounded;
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
      case 'restored':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF475569);
    }
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = detail.data;

    final action = (data['action'] ?? '').toString();
    final childName = (data['childName'] ?? 'Bé').toString();
    final scheduleTitle = (data['scheduleTitle'] ?? '').toString();
    final date = (data['date'] ?? '').toString();
    final startAt = (data['startAt'] ?? '').toString();
    final endAt = (data['endAt'] ?? '').toString();

    final ownerParentUid = (data['ownerParentUid'] ?? '').toString();
    final childId = (data['childId'] ?? '').toString();
    final dateIso = (data['dateIso'] ?? '').toString();

    final isDeleted = action == 'deleted';
    final canOpenSchedule =
        ownerParentUid.isNotEmpty && childId.isNotEmpty && dateIso.isNotEmpty;

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
          icon: Icons.menu_book_rounded,
          label: 'Tên lịch',
          value: scheduleTitle.isEmpty ? 'Không có tiêu đề' : scheduleTitle,
        ),
        const SizedBox(height: 14),

        _infoTile(
          icon: Icons.child_care_rounded,
          label: 'Bé',
          value: childName,
        ),
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
            children: [
              _timeRow(
                icon: Icons.calendar_today_rounded,
                label: 'Ngày',
                value: date,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              _timeRow(
                icon: Icons.access_time_rounded,
                label: 'Thời gian',
                value: '$startAt - $endAt',
              ),
            ],
          ),
        ),

        if (!isDeleted) ...[
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canOpenSchedule
                  ? () async {
                      final targetDate = _parseDate(dateIso);
                      if (targetDate == null) return;

                      final scheduleVm = context.read<ScheduleViewModel>();
                      final storage = context.read<StorageService>();
                      final role = storage.getString(StorageKeys.role);

                      await scheduleVm.openFromNotification(
                        ownerParentUid: ownerParentUid,
                        childId: childId,
                        date: targetDate,
                      );

                      if (!context.mounted) return;

                      Navigator.of(context).popUntil((route) => route.isFirst);
                      activeTabNotifier.value = role == 'child' ? 3 : 4;
                    }
                  : null,
              icon: const Icon(Icons.calendar_today_rounded, size: 18),
              label: const Text(
                'Xem lịch',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.calendarSelection,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
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

  Widget _timeRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        SizedBox(
          width: 74,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}