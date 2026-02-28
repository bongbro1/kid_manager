import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../core/storage_keys.dart';
import '../../../services/storage_service.dart';
import '../../../viewmodels/schedule_vm.dart';

import '../../../views/parent/schedule/add_schedule_sheet.dart';
import '../../../widgets/parent/schedule/create_schedule_button.dart';
import '../../../widgets/parent/schedule/schedule_calendar.dart';
import '../../../widgets/parent/schedule/schedule_list.dart';

class ChildScheduleScreen extends StatefulWidget {
  const ChildScheduleScreen({super.key});

  @override
  State<ChildScheduleScreen> createState() => _ChildScheduleScreenState();
}

class _ChildScheduleScreenState extends State<ChildScheduleScreen> {
  String? _lastChildUid;
  String? _lastOwnerUid;
  bool _binding = false;

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

  Future<void> _bindSessionIfNeeded() async {
    if (_binding) return;
    _binding = true;

    try {
      final storage = context.read<StorageService>();
      final userVm = context.read<UserVm>();
      final scheduleVm = context.read<ScheduleViewModel>();

      final childUid = storage.getString(StorageKeys.uid);
      if (childUid == null) return;

      // Load profile đúng childUid hiện tại (tránh dùng profile cũ)
      if (userVm.profile == null || userVm.profile!.id != childUid) {
        await userVm.loadProfile();
      }

      final parentUid = userVm.profile?.parentUid;
      if (parentUid == null || parentUid.isEmpty) return;

      final changed = (_lastChildUid != childUid) || (_lastOwnerUid != parentUid);

      if (changed) {
        _lastChildUid = childUid;
        _lastOwnerUid = parentUid;

        // Reset state cũ để không dính lịch của child khác
        scheduleVm.monthSchedules = {};
        scheduleVm.schedules = [];
        scheduleVm.error = null;
        scheduleVm.isLoading = false;
        scheduleVm.selectedChildId = null;

        scheduleVm.setScheduleOwnerUid(parentUid);
        await scheduleVm.setChild(childUid); // setChild sẽ loadMonth()
      }
    } finally {
      _binding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();

    // Mỗi lần build đều check/bind lại session (nhưng có guard _binding + cache)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindSessionIfNeeded();
    });

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

          if (scheduleVm.selectedChildId == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            const Expanded(child: ScheduleList()),

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