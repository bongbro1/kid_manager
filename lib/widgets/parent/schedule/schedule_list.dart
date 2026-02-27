  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';

  import '../../../../../core/app_text_styles.dart';
  import '../../../../../models/schedule.dart';
  import '../../../../../utils/schedule_utils.dart';
  import '../../../../../viewmodels/schedule_vm.dart';
  import '../../../views/parent/schedule/edit_schedule_sheet.dart';

  class ScheduleList extends StatelessWidget {
    const ScheduleList({super.key});

    @override
    Widget build(BuildContext context) {
      final vm = context.watch<ScheduleViewModel>();

      if (vm.selectedChildId == null) {
        return const Center(child: Text('Vui lòng chọn bé', style: AppTextStyles.body));
      }

      if (vm.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (vm.error != null) {
        return Center(child: Text(vm.error!));
      }

      if (vm.schedules.isEmpty) {
        return const Center(
          child: Text('Không có lịch trong ngày', style: AppTextStyles.body),
        );
      }

      return Builder(
        builder: (screenContext) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: vm.schedules.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ScheduleItem(
                schedule: vm.schedules[i],
                screenContext: screenContext, // ✅ context ổn định
              ),
            ),
          );
        },
      );
    }
  }

  class ScheduleItem extends StatelessWidget {
    final Schedule schedule;
    final BuildContext screenContext;

    const ScheduleItem({
      super.key,
      required this.schedule,
      required this.screenContext,
    });

    @override
    Widget build(BuildContext context) {
      String two(int n) => n.toString().padLeft(2, '0');

      final duration =
          '${two(schedule.startAt.hour)}:${two(schedule.startAt.minute)}-'
          '${two(schedule.endAt.hour)}:${two(schedule.endAt.minute)}';

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _periodColor(schedule.period),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(duration, style: AppTextStyles.scheduleItemTimeRange),
                const Spacer(),
                _ActionIcon(
                  asset: 'assets/images/edit.png',
                  width: 18,
                  height: 18,
                  onTap: () => _openEditSheet(context),
                ),
                const SizedBox(width: 10),
                _ActionIcon(
                  asset: 'assets/images/ic_delete.png',
                  onTap: () => _deleteSchedule(screenContext),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(schedule.title, style: AppTextStyles.scheduleItemTitle),
            if ((schedule.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(schedule.description!, style: AppTextStyles.scheduleItemTime),
            ],
          ],
        ),
      );
    }

    Future<void> _openEditSheet(BuildContext context) {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: EditScheduleScreen(schedule: schedule),
          ),
        ),
      );
    }

    Future<void> _deleteSchedule(BuildContext context) async {
      final vm = context.read<ScheduleViewModel>();

      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Xóa lịch trình'),
          content: const Text('Bạn có chắc muốn xóa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Xóa',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      try {
        await vm.deleteSchedule(schedule.id);

        if (!context.mounted) return;

        await showScheduleSuccess(context, 'Bạn đã xóa thành công');
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xóa thất bại: $e')),
        );
      }
    }
  }

  class _ActionIcon extends StatelessWidget {
    final String asset;
    final double width;
    final double height;
    final VoidCallback onTap;

    const _ActionIcon({
      required this.asset,
      required this.onTap,
      this.width = 22,
      this.height = 22,
    });

    @override
    Widget build(BuildContext context) {
      return GestureDetector(
        onTap: onTap,
        child: Image.asset(asset, width: width, height: height),
      );
    }
  }

  Color _periodColor(SchedulePeriod p) {
  switch (p) {
    case SchedulePeriod.morning:
      return const Color(0xFF8B5CF6); // tím
    case SchedulePeriod.afternoon:
      return const Color(0xFF00B383); // xanh lá
    case SchedulePeriod.evening:
      return const Color(0xFF3B82F6); // xanh dương
  }
}
