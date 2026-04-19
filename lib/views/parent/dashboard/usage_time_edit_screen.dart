import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/time_window_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/edit_screen_widgets/day_override_editor.dart';
import 'package:kid_manager/views/parent/dashboard/edit_screen_widgets/main_usage_editor.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UsageTimeEditScreen extends StatefulWidget {
  final String appId;
  final String childId;
  const UsageTimeEditScreen({
    super.key,
    required this.appId,
    required this.childId,
  });

  @override
  State<UsageTimeEditScreen> createState() => _UsageTimeEditScreenState();
}

class _UsageTimeEditScreenState extends State<UsageTimeEditScreen> {
  late UsageRule rule;
  Map<String, DayOverride> overrides = {};
  bool _isInitializing = true;

  bool unlimited = false;
  int minutes = 60;

  @override
  void initState() {
    super.initState();
    rule = UsageRule.defaults();

    final now = DateTime.now();
    _gridMonth = DateTime(now.year, now.month, 1);
    _headerMonth = _gridMonth;

    _loadRule();
  }

  Future<void> _loadRule() async {
    final vm = context.read<AppManagementVM>();

    final fetched = await vm.loadUsageRule(
      childId: widget.childId,
      packageName: widget.appId,
    );

    if (!mounted) return;

    setState(() {
      rule = fetched ?? UsageRule.defaults();
      overrides = rule.overrides;
      _fillDotsFromOverrides();
      _isInitializing = false;
    });
  }

  late DateTime _gridMonth;
  late DateTime _headerMonth;
  DateTime? _selectedDate;
  DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  final Map<DateTime, DotType> _dotsByDay = {};

  void _fillDotsFromOverrides() {
    _dotsByDay.clear();

    overrides.forEach((dateKey, type) {
      final day = DateTime.parse(dateKey);

      if (type == DayOverride.allowFullDay) {
        _dotsByDay[_d(day)] = DotType.allow;
      } else if (type == DayOverride.blockFullDay) {
        _dotsByDay[_d(day)] = DotType.block;
      }
    });
  }

  void toggleDay(int day) {
    final next = {...rule.weekdays};
    if (next.contains(day)) {
      next.remove(day);
    } else {
      next.add(day);
    }

    setState(() => rule = rule.copyWith(weekdays: next));
  }

  Future<void> onSavePressed() async {
    final vm = context.read<AppManagementVM>();
    final finalRule = rule.copyWith(overrides: overrides);

    if (finalRule.overrides.isNotEmpty) {
      finalRule.overrides.forEach((date, type) {
        debugPrint("   $date -> ${type.name}");
      });
    }

    try {
      await vm.saveUsageRule(
        userId: widget.childId,
        packageName: widget.appId,
        rule: finalRule,
      );

      if (!mounted) return;

      Navigator.pop(context, true); // 👈 pop và trả kết quả
    } catch (e) {
      debugPrint("❌ Save rule error: $e");
    }
  }

  void onCancel() {
    Navigator.of(context).pop(false);
  }

  void addWindow() {
    final l10n = AppLocalizations.of(context);
    final slot = TimeWindowUtils.findAvailableSlot(rule.windows);

    if (slot == null) {
      _showInvalidRangeSnack(l10n.parentUsageNoAvailableSlot);
      return;
    }

    final newWindows = [...rule.windows, slot];

    setState(() {
      rule = rule.copyWith(windows: newWindows);
    });
  }

  void removeWindow(int index) {
    final newWindows = [...rule.windows]..removeAt(index);

    setState(() {
      rule = rule.copyWith(windows: newWindows);
    });
  }

  Future<void> pickStart(int i) async {
    final l10n = AppLocalizations.of(context);
    final w = rule.windows[i];

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: w.startMin ~/ 60, minute: w.startMin % 60),
    );

    if (picked == null) return;

    final newStart = picked.hour * 60 + picked.minute;

    if (newStart >= w.endMin) {
      _showInvalidRangeSnack(l10n.parentUsageStartBeforeEnd);
      return;
    }

    final newWindow = TimeWindow(startMin: newStart, endMin: w.endMin);

    if (_isOverlapping(newWindow, i)) {
      _showInvalidRangeSnack(l10n.parentUsageOverlapTimeRange);
      return;
    }

    setState(() {
      final newWindows = [...rule.windows];
      newWindows[i] = newWindow;
      rule = rule.copyWith(windows: newWindows);
    });
  }

  Future<void> pickEnd(int i) async {
    final l10n = AppLocalizations.of(context);
    final w = rule.windows[i];

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: w.endMin ~/ 60, minute: w.endMin % 60),
    );

    if (picked == null) return;

    final newEnd = picked.hour * 60 + picked.minute;

    if (newEnd <= w.startMin) {
      _showInvalidRangeSnack(l10n.parentUsageEndAfterStart);
      return;
    }

    final newWindow = TimeWindow(startMin: w.startMin, endMin: newEnd);

    if (_isOverlapping(newWindow, i)) {
      _showInvalidRangeSnack(l10n.parentUsageOverlapTimeRange);
      return;
    }

    setState(() {
      final newWindows = [...rule.windows];
      newWindows[i] = newWindow;
      rule = rule.copyWith(windows: newWindows);
    });
  }

  bool _isOverlapping(TimeWindow newWindow, int ignoreIndex) {
    for (int i = 0; i < rule.windows.length; i++) {
      if (i == ignoreIndex) continue;

      final w = rule.windows[i];

      final overlap =
          newWindow.startMin < w.endMin && newWindow.endMin > w.startMin;

      if (overlap) return true;
    }
    return false;
  }

  void _showInvalidRangeSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  DateTime? _editingOverrideDate;
  DayOverrideOption _editingOverrideOption = DayOverrideOption.followSchedule;

  bool get _isPickingDayOverride => _editingOverrideDate != null;

  void _saveEditingOverride() {
    final cellDate = _editingOverrideDate;
    if (cellDate == null) return;

    final key = toKey(cellDate);
    final newOverride = fromOption(_editingOverrideOption);

    setState(() {
      if (newOverride == null) {
        overrides.remove(key);
      } else {
        overrides[key] = newOverride;
      }

      _fillDotsFromOverrides();
      _editingOverrideDate = null;
      _editingOverrideOption = DayOverrideOption.followSchedule;
    });
  }

  void _closeOverrideEditor() {
    setState(() {
      _editingOverrideDate = null;
      _editingOverrideOption = DayOverrideOption.followSchedule;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppManagementVM>();
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget _buildOverrideView() {
      return DayOverrideEditor(
        date: _editingOverrideDate!,
        selectedOption: _editingOverrideOption,
        onOptionChanged: (value) {
          setState(() {
            _editingOverrideOption = value;
          });
        },
        onBack: _closeOverrideEditor,
        onSave: _saveEditingOverride,
      );
    }

    Widget _buildMainEditorView() {
      return MainUsageEditor(
        rule: rule,
        screenHeight: screenHeight,
        gridMonth: _gridMonth,
        headerMonth: _headerMonth,
        selectedDate: _selectedDate,
        dotsByDay: _dotsByDay,

        onCancel: onCancel,
        onSave: onSavePressed,

        onToggleEnabled: (v) {
          setState(() {
            rule = rule.copyWith(enabled: v);
          });
        },

        onAddWindow: addWindow,
        onRemoveWindow: (i) => removeWindow(i),
        onPickStart: (i) => pickStart(i),
        onPickEnd: (i) => pickEnd(i),

        onWeekdaysChanged: (next) {
          setState(() {
            rule = rule.copyWith(weekdays: next);
          });
        },

        onMonthChanged: (m) {
          setState(() {
            _gridMonth = DateTime(m.year, m.month, 1);
            _headerMonth = _gridMonth;
          });
        },

        onDayTap: (cellDate) {
          setState(() {
            _selectedDate = cellDate;
            _headerMonth = DateTime(cellDate.year, cellDate.month, 1);

            final key = toKey(cellDate);
            final current = overrides[key];

            _editingOverrideDate = cellDate;
            _editingOverrideOption = toOption(current);
          });
        },
      );
    }

    return Stack(
      children: [
        AppOverlaySheet(
          height: screenHeight * 0.85,
          showHandle: true,
          onClose: onCancel,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Skeletonizer(
              enabled: _isInitializing,
              child: _editingOverrideDate != null
                  ? _buildOverrideView()
                  : _buildMainEditorView(),
            ),
          ),
        ),

        if (vm.loading) const LoadingOverlay(),
      ],
    );
  }
}
