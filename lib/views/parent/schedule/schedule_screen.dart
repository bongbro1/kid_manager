import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/models/app_user.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
import '../../../viewmodels/user_vm.dart';
import '../../../views/parent/schedule/add_schedule_sheet.dart';
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

    await scheduleVm.openFromNotification(
      ownerParentUid: widget.initialOwnerParentUid!,
      childId: widget.initialChildId!,
      date: widget.initialDate!,
    );

    memoryVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    await memoryVm.loadMonth();
  }

  Future<void> _bindParentSessionIfNeeded() async {
    if (_binding) return;
    _binding = true;

    try {
      final storage = context.read<StorageService>();
      final userVm = context.read<UserVm>();
      final scheduleVm = context.read<ScheduleViewModel>();
      final memoryVm = context.read<MemoryDayViewModel>();

      final parentUid = storage.getString(StorageKeys.uid);
      final role = storage.getString(StorageKeys.role);

      // Chỉ bind ở màn parent
      if (parentUid == null || role != 'parent') return;

      final changed = _lastParentUid != parentUid;

      if (changed) {
        _lastParentUid = parentUid;

        // ✅ RESET state cũ
        scheduleVm.resetForNewSession();
        memoryVm.resetForNewSession();

        // Bind owner
        scheduleVm.setScheduleOwnerUid(parentUid);
        memoryVm.setOwnerUid(parentUid);

        // Load children list
        userVm.watchChildren(parentUid);

        // Đồng bộ calendar state ban đầu cho memory day
        memoryVm.bindCalendarState(
          focusedMonth: scheduleVm.focusedMonth,
          selectedDate: scheduleVm.selectedDate,
        );

        // Load memory month hiện tại
        await memoryVm.loadMonth();
        await _applyNotificationTargetIfNeeded();
      }
    } finally {
      _binding = false;
    }
  }

  Widget _buildSelectedChildAvatar(List<AppUser> children, String? selectedId) {
    if (children.isEmpty) {
      return const CircleAvatar(radius: 18, child: Text('?'));
    }

    final AppUser selected = selectedId == null
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
      onForegroundImageError: (_, _) {},
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
    final List<AppUser> children = userVm.children;

    // ✅ mỗi lần build đều bind lại theo session (có guard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindParentSessionIfNeeded();
    });

    // ✅ Auto select bé đầu tiên nếu chưa chọn bé
    if (widget.initialChildId == null &&
        scheduleVm.selectedChildId == null &&
        children.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        scheduleVm.setChild(
          children.first.uid,
        ); // setChild sẽ reset về today + loadMonth
        _syncMemoryWithSchedule();
      });
    }

    return Scaffold(
      drawer: ScheduleMenuDrawer(
        selectedChildId: scheduleVm.selectedChildId,
        lockChildSelection: false,
        onImportSuccess: _reloadSchedulesAfterImport,
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.darkText),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          l10n.scheduleScreenTitle,
          style: AppTextStyles.scheduleAppBarTitle,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: children.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(l10n.scheduleNoChild),
                    ),
                  )
                : PopupMenuButton<String>(
                    onSelected: (childUid) {
                      scheduleVm.setChild(childUid);
                      _syncMemoryWithSchedule();
                    },
                    itemBuilder: (_) => children.map((c) {
                      final avatar = (c.avatarUrl ?? '').trim();

                      return PopupMenuItem(
                        value: c.uid,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              foregroundImage: avatar.isNotEmpty
                                  ? NetworkImage(avatar)
                                  : null,
                              onForegroundImageError: (_, _) {},
                              child: Text(
                                _nameInitial(c),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(c.displayName ?? c.email ?? c.uid),
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

  /// ✅ chỉ reload tháng đang xem + child đang chọn (KHÔNG reset today)
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

    // nếu bạn muốn đồng bộ memory day dot theo month schedule (tuỳ app),
    // thì gọi sync luôn (an toàn)
    await _syncMemoryWithSchedule();

    debugPrint('[SCHEDULE_IMPORT] reload done');
  }

  // String _initialOf(List<AppUser> children, String? selectedId) {
  //   if (children.isEmpty) return '?';

  //   final AppUser selected = selectedId == null
  //       ? children.first
  //       : children.firstWhere(
  //           (c) => c.uid == selectedId,
  //           orElse: () => children.first,
  //         );

  //   final name = (selected.displayName ?? selected.email ?? '').trim();
  //   if (name.isEmpty) return 'B';
  //   return name[0].toUpperCase();
  // }

  Future<void> _syncMemoryWithSchedule() async {
    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();

    memoryVm.bindCalendarState(
      focusedMonth: scheduleVm.focusedMonth,
      selectedDate: scheduleVm.selectedDate,
    );
    await memoryVm.loadMonth();
  }
}
