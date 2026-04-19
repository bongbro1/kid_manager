import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
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
  bool _pendingBind = false;
  bool _disposed = false;
  int _sessionGeneration = 0;
  late final UserVm _userVm;
  late final SessionVM _sessionVm;
  late final AuthVM _authVm;

  @override
  void initState() {
    super.initState();
    _userVm = context.read<UserVm>();
    _sessionVm = context.read<SessionVM>();
    _authVm = context.read<AuthVM>();
    _userVm.addListener(_handleUserVmChanged);
    _sessionVm.addListener(_handleSessionVmChanged);
    _authVm.addListener(_handleAuthVmChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleUserVmChanged();
    });
  }

  @override
  void didUpdateWidget(covariant ChildScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDate != widget.initialDate) {
      _appliedNotificationTarget = false;
      _handleUserVmChanged();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidateSessionTasks();
    _pendingBind = false;
    _userVm.removeListener(_handleUserVmChanged);
    _sessionVm.removeListener(_handleSessionVmChanged);
    _authVm.removeListener(_handleAuthVmChanged);
    super.dispose();
  }

  void _handleSessionVmChanged() {
    if (_sessionVm.status == SessionStatus.authenticated) return;
    _invalidateSessionTasks();
    _pendingBind = false;
  }

  void _handleAuthVmChanged() {
    if (!_authVm.logoutInProgress) return;
    _invalidateSessionTasks();
    _pendingBind = false;
  }

  void _invalidateSessionTasks() {
    _sessionGeneration++;
  }

  bool _isGenerationActive(int generation) {
    if (_disposed || !mounted) return false;
    if (generation != _sessionGeneration) return false;
    if (_authVm.logoutInProgress) return false;
    return _sessionVm.status == SessionStatus.authenticated;
  }

  void _handleUserVmChanged() {
    if (!mounted) return;
    _invalidateSessionTasks();

    if (_binding) {
      _pendingBind = true;
      return;
    }

    unawaited(_bindSessionIfNeeded(generation: _sessionGeneration));
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
    required int generation,
  }) async {
    if (!_isGenerationActive(generation)) return;
    if (_appliedNotificationTarget) return;
    if (widget.initialDate == null) return;

    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    await scheduleVm.openFromNotification(
      ownerParentUid: parentUid,
      childId: childUid,
      date: widget.initialDate!,
    );
    if (!_isGenerationActive(generation)) return;

    memoryVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    birthdayVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    await Future.wait([memoryVm.loadMonth(), birthdayVm.loadMonth()]);
    if (!_isGenerationActive(generation)) return;

    _appliedNotificationTarget = true;
  }

  Future<void> _bindSessionIfNeeded({required int generation}) async {
    if (!_isGenerationActive(generation)) return;
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
        if (!_isGenerationActive(generation)) return;
      }

      final parentUid = userVm.profile?.parentUid;
      if (parentUid == null || parentUid.isEmpty) return;

      final familyId =
          userVm.familyId ?? (await userRepo.getUserById(childUid))?.familyId;
      if (!_isGenerationActive(generation)) return;
      if (familyId == null || familyId.isEmpty) return;

      final changed =
          (_lastChildUid != childUid) ||
          (_lastOwnerUid != parentUid) ||
          (_lastFamilyId != familyId);

      final hasBoundOwner = scheduleVm.hasBoundScheduleOwner;
      final boundToSameOwner =
          hasBoundOwner && scheduleVm.scheduleOwnerUid == parentUid;
      final boundToSameChild = scheduleVm.selectedChildId == childUid;
      final alreadyBoundToSameSession = boundToSameOwner && boundToSameChild;

      _lastChildUid = childUid;
      _lastOwnerUid = parentUid;
      _lastFamilyId = familyId;

      if (!changed && alreadyBoundToSameSession) return;

      if (!alreadyBoundToSameSession) {
        scheduleVm.resetForNewSession();
        scheduleVm.setScheduleOwnerUid(parentUid);
        await scheduleVm.setChild(childUid);
        if (!_isGenerationActive(generation)) return;
      } else if (widget.initialDate != null &&
          _isSameDate(scheduleVm.selectedDate, widget.initialDate!)) {
        _appliedNotificationTarget = true;
      }

      memoryVm.setOwnerUid(parentUid);
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
      if (!_isGenerationActive(generation)) return;

      await _applyNotificationTargetIfNeeded(
        parentUid: parentUid,
        childUid: childUid,
        generation: generation,
      );
    } finally {
      _binding = false;

      final shouldRerun = _pendingBind && !_disposed && mounted;
      if (shouldRerun) {
        _pendingBind = false;
        final rerunGeneration = _sessionGeneration;
        if (_isGenerationActive(rerunGeneration)) {
          unawaited(_bindSessionIfNeeded(generation: rerunGeneration));
        }
      }
    }
  }

  Future<void> _reloadSchedulesAfterImport() async {
    if (_disposed || !mounted) return;
    final scheduleVm = context.read<ScheduleViewModel>();

    if (scheduleVm.selectedChildId == null) {
      debugPrint('[CHILD_SCHEDULE_IMPORT] selectedChildId=null -> skip reload');
      return;
    }

    await scheduleVm.loadMonth();
    if (_disposed || !mounted) return;

    await _syncCalendarCompanions();

    debugPrint('[CHILD_SCHEDULE_IMPORT] reload done');
  }

  Future<void> _syncCalendarCompanions({int? generation}) async {
    if (_disposed || !mounted) return;
    if (generation != null && !_isGenerationActive(generation)) return;

    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    memoryVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    birthdayVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    await Future.wait([memoryVm.loadMonth(), birthdayVm.loadMonth()]);
    if (_disposed || !mounted) return;
    if (generation != null && !_isGenerationActive(generation)) return;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduleVm = context.watch<ScheduleViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            icon: Icon(Icons.menu, color: colorScheme.onSurface, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          l10n.scheduleScreenTitle,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
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
