import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../core/storage_keys.dart';
import '../../../services/storage_service.dart';
import '../../../viewmodels/schedule_vm.dart';

import '../../../views/parent/schedule/add_schedule_sheet.dart';
import '../../../widgets/parent/create_schedule_button.dart';
import '../../../widgets/parent/schedule_calendar.dart';
import '../../../widgets/parent/schedule_list.dart';

class ChildScheduleScreen extends StatefulWidget {
  const ChildScheduleScreen({super.key});

  @override
  State<ChildScheduleScreen> createState() => _ChildScheduleScreenState();
}

class _ChildScheduleScreenState extends State<ChildScheduleScreen> {
  bool _didInit = false;

  void _openAddScheduleSheet({
    required BuildContext context,
    required String childId,
    required DateTime selectedDate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddScheduleScreen(
              childId: childId,
              selectedDate: selectedDate,
            ),
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final storage = context.read<StorageService>();
      final userVm = context.read<UserVm>();
      final scheduleVm = context.read<ScheduleViewModel>();

      final childUid = storage.getString(StorageKeys.uid);
      if (childUid == null) return;

      // load profile để lấy parentUid
      await userVm.loadProfile();
      final parentUid = userVm.profile?.parentUid;
      if (parentUid == null || parentUid.isEmpty) return;

      // ✅ owner path luôn là parentUid
      scheduleVm.setScheduleOwnerUid(parentUid);

      // ✅ lịch của childUid này
      await scheduleVm.setChild(childUid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.darkText),
          onPressed: () {},
        ),
        title: const Text(
          'Lịch trình',
          style: AppTextStyles.scheduleAppBarTitle,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const ScheduleCalendar(),
          const SizedBox(height: 16),

          // tránh nháy "Vui lòng chọn bé" trước khi init setChild
          if (scheduleVm.selectedChildId == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            const Expanded(child: ScheduleList()),

          // ✅ Child cũng được thêm lịch
          CreateScheduleButton(
            onTap: () {
              final childId = scheduleVm.selectedChildId;
              if (childId == null) return;

              _openAddScheduleSheet(
                context: context,
                childId: childId,
                selectedDate: scheduleVm.selectedDate,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}