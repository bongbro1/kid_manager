import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
import '../../../viewmodels/session/session_vm.dart';
import '../../../viewmodels/user_vm.dart';
import '../../../views/parent/schedule/add_schedule_sheet.dart';
import '../../../views/parent/schedule/schedule_session_resolver.dart';
import '../../../widgets/parent/schedule/create_schedule_button.dart';
import '../../../widgets/parent/schedule/schedule_calendar.dart';
import '../../../widgets/parent/schedule/schedule_list.dart';
import '../../../widgets/parent/schedule/schedule_menu_drawer.dart';

class ScheduleScreen extends StatefulWidget {
  final String? initialChildId;
  final DateTime? initialDate;
  final String? initialOwnerParentUid;

  const ScheduleScreen({
    super.key,
    this.initialChildId,
    this.initialDate,
    this.initialOwnerParentUid,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? _lastParentUid;
  String? _lastFamilyId;
  bool _binding = false;
  bool _bootstrapping = false;
  bool _selectingDefaultChild = false;
  bool _appliedNotificationTarget = false;
  bool _pendingBootstrap = false;
  bool _disposed = false;
  int _bootstrapGeneration = 0;

  late final UserVm _userVm;
  late final SessionVM _sessionVm;
  late final AuthVM _authVm;
  late final ScheduleSessionResolver _sessionResolver;

  @override
  void initState() {
    super.initState();
    _userVm = context.read<UserVm>();
    _sessionVm = context.read<SessionVM>();
    _authVm = context.read<AuthVM>();
    _sessionResolver = ScheduleSessionResolver(
      storage: context.read<StorageService>(),
      userVm: _userVm,
    );
    _userVm.addListener(_handleUserVmChanged);
    _sessionVm.addListener(_handleSessionVmChanged);
    _authVm.addListener(_handleAuthVmChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleUserVmChanged();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _invalidateBootstrapTasks();
    _pendingBootstrap = false;
    _userVm.removeListener(_handleUserVmChanged);
    _sessionVm.removeListener(_handleSessionVmChanged);
    _authVm.removeListener(_handleAuthVmChanged);
    super.dispose();
  }

  void _handleSessionVmChanged() {
    if (_sessionVm.status == SessionStatus.authenticated) {
      return;
    }
    _invalidateBootstrapTasks();
    _pendingBootstrap = false;
  }

  void _handleAuthVmChanged() {
    if (!_authVm.logoutInProgress) return;
    _invalidateBootstrapTasks();
    _pendingBootstrap = false;
  }

  void _invalidateBootstrapTasks() {
    _bootstrapGeneration++;
  }

  bool _isGenerationActive(int generation) {
    if (_disposed || !mounted) return false;
    if (generation != _bootstrapGeneration) return false;
    if (_authVm.logoutInProgress) return false;
    return _sessionVm.status == SessionStatus.authenticated;
  }

  void _handleUserVmChanged() {
    if (!mounted) return;
    _invalidateBootstrapTasks();

    if (_bootstrapping) {
      _pendingBootstrap = true;
      return;
    }

    _bootstrapScheduleState(generation: _bootstrapGeneration);
  }

  Future<void> _bootstrapScheduleState({required int generation}) async {
    if (!_isGenerationActive(generation)) return;
    if (_bootstrapping) return;
    _bootstrapping = true;

    try {
      await _bindParentSessionIfNeeded(generation: generation);
      if (!_isGenerationActive(generation)) return;

      await _maybeAutoSelectFirstChild(generation: generation);
    } finally {
      _bootstrapping = false;

      final shouldRerun = _pendingBootstrap && !_disposed && mounted;
      if (shouldRerun) {
        _pendingBootstrap = false;
        final rerunGeneration = _bootstrapGeneration;
        if (_isGenerationActive(rerunGeneration)) {
          unawaited(_bootstrapScheduleState(generation: rerunGeneration));
        }
      }
    }
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
    required int generation,
  }) async {
    if (!_isGenerationActive(generation)) return;
    if (_appliedNotificationTarget) return;
    if (widget.initialChildId == null ||
        widget.initialDate == null ||
        widget.initialOwnerParentUid == null) {
      return;
    }

    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    await scheduleVm.openFromNotification(
      ownerParentUid: widget.initialOwnerParentUid!,
      childId: widget.initialChildId!,
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

  void _clearBoundScheduleStateIfNeeded({required int generation}) {
    if (!_isGenerationActive(generation)) return;
    final scheduleVm = context.read<ScheduleViewModel>();
    final shouldClear =
        _lastParentUid != null ||
        _lastFamilyId != null ||
        scheduleVm.hasBoundScheduleOwner ||
        scheduleVm.selectedChildId != null;

    if (!shouldClear) return;

    _lastParentUid = null;
    _lastFamilyId = null;

    scheduleVm.resetForNewSession();
    context.read<MemoryDayViewModel>().resetForNewSession();
    context.read<BirthdayViewModel>().resetForNewSession();
  }

  Future<void> _bindParentSessionIfNeeded({required int generation}) async {
    if (!_isGenerationActive(generation)) return;
    if (_binding) return;
    _binding = true;

    try {
      final scheduleVm = context.read<ScheduleViewModel>();
      final memoryVm = context.read<MemoryDayViewModel>();
      final birthdayVm = context.read<BirthdayViewModel>();

      final session = await _sessionResolver.resolve(
        initialChildId: widget.initialChildId,
        watchChildrenForParent: true,
      );
      if (!_isGenerationActive(generation)) return;

      // Guardian shares the same schedule screen as parent, but reads data
      // through the resolved ownerParentUid from the session resolver.
      final isParentLikeRole =
          session != null &&
          !session.isChildMode &&
          (session.role == UserRole.parent ||
              session.role == UserRole.guardian);

      if (!isParentLikeRole) {
        _clearBoundScheduleStateIfNeeded(generation: generation);
        return;
      }

      final familyId = session.familyId;
      if (familyId == null || familyId.isEmpty) {
        _clearBoundScheduleStateIfNeeded(generation: generation);
        return;
      }

      final changed =
          _lastParentUid != session.ownerParentUid || _lastFamilyId != familyId;
      if (!changed) return;

      _lastParentUid = session.ownerParentUid;
      _lastFamilyId = familyId;

      scheduleVm.resetForNewSession();
      memoryVm.resetForNewSession();
      birthdayVm.resetForNewSession();

      scheduleVm.setScheduleOwnerUid(session.ownerParentUid);
      memoryVm.setOwnerUid(session.ownerParentUid);
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

      await _applyNotificationTargetIfNeeded(generation: generation);
    } finally {
      _binding = false;
    }
  }

  Future<void> _maybeAutoSelectFirstChild({required int generation}) async {
    if (!_isGenerationActive(generation)) return;
    if (_selectingDefaultChild) return;
    if (widget.initialChildId != null) return;

    final scheduleVm = context.read<ScheduleViewModel>();
    if (!scheduleVm.hasBoundScheduleOwner ||
        _lastParentUid == null ||
        _lastFamilyId == null) {
      return;
    }
    if (scheduleVm.selectedChildId != null) return;

    final defaultChildId = ScheduleSessionResolver.resolveDefaultChildId(
      initialChildId: null,
      children: context.read<UserVm>().children,
    );

    if (defaultChildId == null || defaultChildId.isEmpty) return;

    _selectingDefaultChild = true;

    try {
      await scheduleVm.setChild(defaultChildId);
      if (!_isGenerationActive(generation)) return;

      await _syncCalendarCompanions(generation: generation);
    } finally {
      _selectingDefaultChild = false;
    }
  }

  Widget _buildSelectedChildAvatar(List<AppUser> children, String? selectedId) {
    if (children.isEmpty) {
      return const CircleAvatar(radius: 18, child: Text('?'));
    }

    final selected = selectedId == null
        ? children.first
        : children.firstWhere(
            (c) => c.uid == selectedId,
            orElse: () => children.first,
          );

    final avatar = (selected.avatarUrl ?? '').trim();
    final fallbackText = _nameInitial(selected);

    return CircleAvatar(
      radius: 16,
      foregroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
      onForegroundImageError: avatar.isNotEmpty ? (_, _) {} : null,
      child: Text(
        fallbackText,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  String _nameInitial(AppUser user) {
    final name = (user.displayName ?? user.email ?? '').trim();
    if (name.isEmpty) return 'B';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();
    final userVm = context.watch<UserVm>();
    final l10n = AppLocalizations.of(context);
    final children = userVm.children;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      drawer: ScheduleMenuDrawer(
        selectedChildId: scheduleVm.selectedChildId,
        lockChildSelection: false,
        onImportSuccess: _reloadSchedulesAfterImport,
      ),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: scheme.onSurface, size: 26),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          l10n.scheduleScreenTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: children.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        l10n.scheduleNoChild,
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  )
                : PopupMenuButton<String>(
                    color: scheme.surface,
                    onSelected: (childUid) {
                      scheduleVm.setChild(childUid);
                      _syncCalendarCompanions();
                    },
                    itemBuilder: (_) => children.map((c) {
                      final avatar = (c.avatarUrl ?? '').trim();

                      return PopupMenuItem<String>(
                        value: c.uid,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              foregroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              onForegroundImageError: avatar.isNotEmpty
                                  ? (_, _) {}
                                  : null,
                              backgroundColor: scheme.primary.withOpacity(0.12),
                              child: Text(
                                _nameInitial(c),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.displayName ?? c.email ?? c.uid,
                                style: TextStyle(color: scheme.onSurface),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    child: _buildSelectedChildAvatar(
                      children,
                      scheduleVm.selectedChildId,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          const ScheduleCalendar(),
          const SizedBox(height: 16),
          const Expanded(child: ScheduleList()),
          const SizedBox(height: 16),
          CreateScheduleButton(
            onTap: () {
              final selectedChildId = scheduleVm.selectedChildId;
              if (selectedChildId == null) return;

              _openAddScheduleSheet(
                context: context,
                childId: selectedChildId,
                selectedDate: scheduleVm.selectedDate,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _reloadSchedulesAfterImport() async {
    final scheduleVm = context.read<ScheduleViewModel>();

    if (scheduleVm.selectedChildId == null) {
      debugPrint('[SCHEDULE_IMPORT] selectedChildId=null -> skip reload');
      return;
    }

    debugPrint(
      '[SCHEDULE_IMPORT] before loadMonth: child=${scheduleVm.selectedChildId} '
      'focusedMonth=${scheduleVm.focusedMonth} selectedDate=${scheduleVm.selectedDate}',
    );

    await scheduleVm.loadMonth();
    if (!mounted || _disposed) return;

    await _syncCalendarCompanions();

    debugPrint('[SCHEDULE_IMPORT] reload done');
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
}
