import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';
import '../../../core/storage_keys.dart';
import '../../../services/storage_service.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
import '../../../views/parent/schedule/add_schedule_sheet.dart';
import '../../../widgets/parent/schedule/create_schedule_button.dart';
import '../../../widgets/parent/schedule/schedule_calendar.dart';
import '../../../widgets/parent/schedule/schedule_list.dart';
import '../../../widgets/parent/schedule/schedule_menu_drawer.dart';

class ChildScheduleScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ChildScheduleScreen({super.key, this.initialDate});

  @override
  State<ChildScheduleScreen> createState() => _ChildScheduleScreenState();
}

class _ChildScheduleScreenState extends State<ChildScheduleScreen> {
  String? _lastChildUid;
  String? _lastOwnerUid;
  String? _lastFamilyId;
  bool _binding = false;
  bool _appliedNotificationTarget = false;

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

  Future<void> _applyNotificationTargetIfNeeded({
    required String parentUid,
    required String childUid,
  }) async {
    if (_appliedNotificationTarget) return;
    if (widget.initialDate == null) return;

    _appliedNotificationTarget = true;

    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    await scheduleVm.openFromNotification(
      ownerParentUid: parentUid,
      childId: childUid,
      date: widget.initialDate!,
    );

    memoryVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    birthdayVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    await Future.wait([memoryVm.loadMonth(), birthdayVm.loadMonth()]);
  }

  Future<void> _bindSessionIfNeeded() async {
    if (_binding) return;
    _binding = true;

    try {
      final storage = context.read<StorageService>();
      final userRepo = context.read<UserRepository>();
      final userVm = context.read<UserVm>();
      final scheduleVm = context.read<ScheduleViewModel>();
      final memoryVm = context.read<MemoryDayViewModel>();
      final birthdayVm = context.read<BirthdayViewModel>();

      final childUid =
          storage.getString(StorageKeys.uid) ??
          FirebaseAuth.instance.currentUser?.uid;
      if (childUid == null) return;

      // load profile đúng child hiện tại
      if (userVm.profile == null || userVm.profile!.id != childUid) {
        await userVm.loadProfile(uid: childUid, caller: 'ChildScheduleScreen');
      }

      final parentUid = userVm.profile?.parentUid;
      if (parentUid == null || parentUid.isEmpty) return;
      final familyId =
          userVm.familyId ?? (await userRepo.getUserById(childUid))?.familyId;
      if (familyId == null || familyId.isEmpty) return;

      final changed =
          (_lastChildUid != childUid) ||
          (_lastOwnerUid != parentUid) ||
          (_lastFamilyId != familyId);

      if (changed) {
        _lastChildUid = childUid;
        _lastOwnerUid = parentUid;
        _lastFamilyId = familyId;

        // ======================
        // RESET SCHEDULE (giữ nguyên logic của bạn)
        // ======================
        scheduleVm.resetForNewSession();
        scheduleVm.setScheduleOwnerUid(parentUid);
        await scheduleVm.setChild(childUid);

        // ======================
        // RESET + BIND MEMORY DAY (FIX CHÍNH)
        // ======================
        memoryVm.resetForNewSession();
        memoryVm.setOwnerUid(parentUid);
        birthdayVm.resetForNewSession();
        birthdayVm.setFamilyId(familyId);

        memoryVm.bindCalendarState(
          focusedMonth: scheduleVm.focusedMonth,
          selectedDate: scheduleVm.selectedDate,
        );
        birthdayVm.bindCalendarState(
          focusedMonth: scheduleVm.focusedMonth,
          selectedDate: scheduleVm.selectedDate,
        );

        await Future.wait([memoryVm.loadMonth(), birthdayVm.loadMonth()]);
        await _applyNotificationTargetIfNeeded(
          parentUid: parentUid,
          childUid: childUid,
        );
      }
    } finally {
      _binding = false;
    }
  }

  Future<void> _reloadSchedulesAfterImport() async {
    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    if (scheduleVm.selectedChildId == null) {
      debugPrint('[CHILD_SCHEDULE_IMPORT] selectedChildId=null -> skip reload');
      return;
    }

    await scheduleVm.loadMonth();

    memoryVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    birthdayVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    await Future.wait([memoryVm.loadMonth(), birthdayVm.loadMonth()]);

    debugPrint('[CHILD_SCHEDULE_IMPORT] reload done');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduleVm = context.watch<ScheduleViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindSessionIfNeeded();
    });

    return Scaffold(
      drawer: ScheduleMenuDrawer(
        selectedChildId: scheduleVm.selectedChildId,
        lockChildSelection: true,
        onImportSuccess: _reloadSchedulesAfterImport,
      ),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: colorScheme.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          l10n.scheduleScreenTitle,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const ScheduleCalendar(),
          const SizedBox(height: 16),

          if (scheduleVm.selectedChildId == null)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              ),
            )
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
