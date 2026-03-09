import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/storage_keys.dart';
import '../../models/notifications/notification_detail_model.dart';
import '../../services/storage_service.dart';
import '../../viewmodels/schedule_vm.dart';
import '../../views/child/schedule/child_schedule_screen.dart';
import '../../views/parent/schedule/schedule_screen.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Hành động', _actionText(action)),
        const SizedBox(height: 10),
        _row('Bé', childName),
        const SizedBox(height: 10),
        _row('Tên lịch', scheduleTitle.isEmpty ? 'Không có tiêu đề' : scheduleTitle),
        const SizedBox(height: 10),
        _row('Ngày', date),
        const SizedBox(height: 10),
        _row('Thời gian', '$startAt - $endAt'),
        const SizedBox(height: 18),
        if (!isDeleted)
        Align(
          alignment: Alignment.centerRight,
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

                  // Dọn stack của tab Notification về root để tránh quay lại bị kẹt detail
                  Navigator.of(context).popUntil((route) => route.isFirst);

                  // Chuyển tab thật sự sang Schedule
                  activeTabNotifier.value = role == 'child' ? 3 : 4;
                }
              : null,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: const Text('Xem lịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D59F2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}