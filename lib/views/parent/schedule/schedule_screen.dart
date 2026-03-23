import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
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

  late final UserVm _userVm;
  late final ScheduleSessionResolver _sessionResolver;

  @override
  void initState() {
    super.initState();
    _userVm = context.read<UserVm>();
    _sessionResolver = ScheduleSessionResolver(
      storage: context.read<StorageService>(),
      userVm: _userVm,
    );
    _userVm.addListener(_handleUserVmChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleUserVmChanged();
    });
  }

  @override
  void dispose() {
    _userVm.removeListener(_handleUserVmChanged);
    super.dispose();
  }

  void _handleUserVmChanged() {
    if (!mounted) return;
    _bootstrapScheduleState();
  }

  Future<void> _bootstrapScheduleState() async {
    if (_bootstrapping) return;
    _bootstrapping = true;

    try {
      await _bindParentSessionIfNeeded();
      await _maybeAutoSelectFirstChild();
    } finally {
      _bootstrapping = false;
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

  Future<void> _applyNotificationTargetIfNeeded() async {
    if (_appliedNotificationTarget) return;
    if (widget.initialChildId == null ||
        widget.initialDate == null ||
        widget.initialOwnerParentUid == null) {
      return;
    }

    _appliedNotificationTarget = true;

    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    await scheduleVm.openFromNotification(
      ownerParentUid: widget.initialOwnerParentUid!,
      childId: widget.initialChildId!,
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

  void _clearBoundScheduleStateIfNeeded() {
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

  Future<void> _bindParentSessionIfNeeded() async {
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

      // Guardian shares the same schedule screen as parent, but reads data
      // through the resolved ownerParentUid from the session resolver.
      final isParentLikeRole =
          session != null &&
          !session.isChildMode &&
          (session.role == 'parent' || session.role == 'guardian');

      if (!isParentLikeRole) {
        _clearBoundScheduleStateIfNeeded();
        return;
      }

      final familyId = session.familyId;
      if (familyId == null || familyId.isEmpty) {
        _clearBoundScheduleStateIfNeeded();
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
      await _applyNotificationTargetIfNeeded();
    } finally {
      _binding = false;
    }
  }

  Future<void> _maybeAutoSelectFirstChild() async {
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
      await _syncCalendarCompanions();
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
      radius: 18,
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
    final scheme = Theme.of(context).colorScheme;

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
            icon: Icon(Icons.menu, color: scheme.onSurface),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          l10n.scheduleScreenTitle,
          style: AppTextStyles.scheduleAppBarTitle.copyWith(
            color: scheme.onSurface,
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
    await _syncCalendarCompanions();

    debugPrint('[SCHEDULE_IMPORT] reload done');
  }

  Future<void> _syncCalendarCompanions() async {
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
  }
}
