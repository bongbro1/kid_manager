import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/views/parent/memory_day/memory_day_screen.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/views/parent/schedule/schedule_import_excel_screen.dart';

import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../viewmodels/schedule_vm.dart';
import '../../../viewmodels/user_vm.dart';
import '../../../views/parent/schedule/add_schedule_sheet.dart';
import '../../../widgets/parent/schedule/create_schedule_button.dart';
import '../../../widgets/parent/schedule/schedule_calendar.dart';
import '../../../widgets/parent/schedule/schedule_list.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String? _lastParentUid;
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
      }
    } finally {
      _binding = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();
    final userVm = context.watch<UserVm>();
    final List<AppUser> children = userVm.children;

    // ✅ mỗi lần build đều bind lại theo session (có guard)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bindParentSessionIfNeeded();
    });

    // ✅ Auto select bé đầu tiên nếu chưa chọn bé
    if (scheduleVm.selectedChildId == null && children.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        scheduleVm.setChild(children.first.uid); // setChild sẽ reset về today + loadMonth
        _syncMemoryWithSchedule();
      });
    }

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const ListTile(
                title: Text(
                  'Menu',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Color(0xFFF4B400)),
                title: const Text('Ngày đáng nhớ'),
                onTap: () {
                  Navigator.pop(context); // đóng drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MemoryDayScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file, color: Color.fromARGB(255, 0, 224, 49)),
                title: const Text('Thêm lịch trình bằng file Excel'),
                onTap: () async {
                  Navigator.pop(context); // đóng drawer

                  final needReload = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScheduleImportExcelScreen()),
                  );

                  // ✅ IMPORT XONG -> RELOAD NGAY
                  if (needReload == true) {
                    debugPrint('[SCHEDULE_IMPORT] needReload=true -> reload schedules');
                    await _reloadSchedulesAfterImport();
                  }
                },
              ),
            ],
          ),
        ),
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
        title: const Text(
          'Lịch trình',
          style: AppTextStyles.scheduleAppBarTitle,
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: children.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('Chưa có bé'),
                    ),
                  )
                : PopupMenuButton<String>(
                    onSelected: (childUid) {
                      scheduleVm.setChild(childUid);
                      _syncMemoryWithSchedule();
                    },
                    itemBuilder: (_) => children
                        .map(
                          (c) => PopupMenuItem(
                            value: c.uid,
                            child: Text(c.displayName ?? c.email ?? c.uid),
                          ),
                        )
                        .toList(),
                    child: CircleAvatar(
                      radius: 18,
                      child: Text(
                        _initialOf(children, scheduleVm.selectedChildId),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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

  String _initialOf(List<AppUser> children, String? selectedId) {
    if (children.isEmpty) return '?';

    final AppUser selected = selectedId == null
        ? children.first
        : children.firstWhere(
            (c) => c.uid == selectedId,
            orElse: () => children.first,
          );

    final name = (selected.displayName ?? selected.email ?? '').trim();
    if (name.isEmpty) return 'B';
    return name[0].toUpperCase();
  }

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