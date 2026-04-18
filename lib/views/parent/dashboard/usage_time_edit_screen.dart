import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/time_window_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/edit_screen_widgets/edit_screen_widgets.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
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

  List<String> _weekdayLabels(AppLocalizations l10n) {
    return [
      l10n.scheduleWeekdayMon,
      l10n.scheduleWeekdayTue,
      l10n.scheduleWeekdayWed,
      l10n.scheduleWeekdayThu,
      l10n.scheduleWeekdayFri,
      l10n.scheduleWeekdaySat,
      l10n.scheduleWeekdaySun,
    ];
  }

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
      final date = _editingOverrideDate!;
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final textTheme = theme.textTheme;
      final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

      return Column(
        key: const ValueKey('override-view'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _closeOverrideEditor,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      l10n.parentUsageDayRuleModalHint,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(date),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          overrideCard(
            icon: Icons.schedule,
            title: l10n.parentUsageRuleFollowScheduleTitle,
            subtitle: l10n.parentUsageRuleFollowScheduleSubtitle,
            color: scheme.onSurface.withOpacity(0.6),
            value: DayOverrideOption.followSchedule,
            group: _editingOverrideOption,
            onTap: () => setState(() {
              _editingOverrideOption = DayOverrideOption.followSchedule;
            }),
          ),
          const SizedBox(height: 12),
          overrideCard(
            icon: Icons.check_circle,
            title: l10n.parentUsageRuleAllowAllDayTitle,
            subtitle: l10n.parentUsageRuleAllowAllDaySubtitle,
            color: Colors.green,
            value: DayOverrideOption.allowFullDay,
            group: _editingOverrideOption,
            onTap: () => setState(() {
              _editingOverrideOption = DayOverrideOption.allowFullDay;
            }),
          ),
          const SizedBox(height: 12),
          overrideCard(
            icon: Icons.block,
            title: l10n.parentUsageRuleBlockAllDayTitle,
            subtitle: l10n.parentUsageRuleBlockAllDaySubtitle,
            color: scheme.error,
            value: DayOverrideOption.blockFullDay,
            group: _editingOverrideOption,
            onTap: () => setState(() {
              _editingOverrideOption = DayOverrideOption.blockFullDay;
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _saveEditingOverride,
              child: Text(
                l10n.saveButton,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget _buildMainEditorView() {
      return Column(
        key: const ValueKey('main'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),

          Text(
            l10n.parentUsageEditTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            height: 1,
            color: theme.dividerTheme.color ?? scheme.outline,
          ),

          const SizedBox(height: 8),

          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.parentUsageEnableUsage,
                        style: textTheme.titleMedium?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w500,
                          height: 1.38,
                          fontFamily: 'Poppins',
                        ),
                      ),

                      const Spacer(),

                      Switch(
                        value: rule.enabled,
                        onChanged: (v) {
                          setState(() {
                            rule = rule.copyWith(enabled: v);
                          });
                        },

                        /// 👇 màu theo theme
                        activeColor: scheme.onPrimary, // thumb khi ON
                        activeTrackColor: scheme.primary, // track khi ON

                        inactiveThumbColor: scheme.outline, // thumb OFF
                        inactiveTrackColor: scheme.outline.withOpacity(
                          0.3,
                        ), // track OFF

                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: MaterialStatePropertyAll(
                          Colors.transparent,
                        ),
                        splashRadius: 0,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Column(
                    children: [
                      ...List.generate(rule.windows.length, (i) {
                        final w = rule.windows[i];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: timeRangeRow(
                            context: context,
                            window: w,
                            enabled: rule.enabled,
                            onPickStart: () => pickStart(i),
                            onPickEnd: () => pickEnd(i),
                            onDelete: () => removeWindow(i),
                          ),
                        );
                      }),
                      if (rule.enabled)
                        InkWell(
                          onTap: addWindow,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      l10n.parentUsageSelectAllowedDays,
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        height: 1.19,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      final selected = rule.weekdays.contains(day);

                      return Expanded(
                        child: GestureDetector(
                          onTap: rule.enabled
                              ? () {
                                  final next = {...rule.weekdays};
                                  if (selected) {
                                    next.remove(day);
                                  } else {
                                    next.add(day);
                                  }

                                  setState(() {
                                    rule = rule.copyWith(weekdays: next);
                                  });
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 36,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !rule.enabled
                                  ? scheme.surface
                                  : selected
                                  ? scheme.primary
                                  : scheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? scheme.primary
                                    : scheme.outline.withOpacity(0.35),
                              ),
                            ),
                            child: Text(
                              _weekdayLabels(l10n)[index],
                              style: textTheme.bodySmall?.copyWith(
                                color: !rule.enabled
                                    ? scheme.onSurface.withOpacity(0.35)
                                    : selected
                                    ? scheme.onPrimary
                                    : scheme.onSurface.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 27),

                  buildCalendar(
                    context: context,
                    l10n: l10n,
                    month: _gridMonth,
                    headerMonth: _headerMonth,
                    selected: _selectedDate,
                    dotsByDay: _dotsByDay,
                    onMonthChanged: (m) => setState(() {
                      _gridMonth = DateTime(m.year, m.month, 1);
                      _headerMonth = _gridMonth;
                    }),
                    onDayTap: (cellDate) {
                      setState(() {
                        _selectedDate = cellDate;
                        _headerMonth = DateTime(
                          cellDate.year,
                          cellDate.month,
                          1,
                        );

                        final key = toKey(cellDate);
                        final current = overrides[key];

                        _editingOverrideDate = cellDate;
                        _editingOverrideOption = toOption(current);
                      });
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: l10n.cancelButton,
                  height: 50,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.primary,
                  fontSize: 15,
                  lineHeight: 1.38,
                  fontWeight: FontWeight.w700,
                  onPressed: onCancel,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: AppButton(
                  text: l10n.saveButton,
                  height: 50,
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  fontSize: 15,
                  lineHeight: 1.38,
                  fontWeight: FontWeight.w700,
                  onPressed: onSavePressed,
                ),
              ),
            ],
          ),
        ],
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

class DayOverrideView extends StatelessWidget {
  final DateTime date;
  final DayOverrideOption selected;
  final ValueChanged<DayOverrideOption> onChanged;
  final VoidCallback onSave;
  final VoidCallback onBack;

  const DayOverrideView({
    super.key,
    required this.date,
    required this.selected,
    required this.onChanged,
    required this.onSave,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bottomSafe = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        bottomSafe > 0 ? bottomSafe + 10 : 24,
      ),
      child: Column(
        key: const ValueKey('day-override-view'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      l10n.parentUsageDayRuleModalHint,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(date),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          overrideCard(
            icon: Icons.schedule,
            title: l10n.parentUsageRuleFollowScheduleTitle,
            subtitle: l10n.parentUsageRuleFollowScheduleSubtitle,
            color: scheme.onSurface.withOpacity(0.6),
            value: DayOverrideOption.followSchedule,
            group: selected,
            onTap: () => onChanged(DayOverrideOption.followSchedule),
          ),
          const SizedBox(height: 12),
          overrideCard(
            icon: Icons.check_circle,
            title: l10n.parentUsageRuleAllowAllDayTitle,
            subtitle: l10n.parentUsageRuleAllowAllDaySubtitle,
            color: Colors.green,
            value: DayOverrideOption.allowFullDay,
            group: selected,
            onTap: () => onChanged(DayOverrideOption.allowFullDay),
          ),
          const SizedBox(height: 12),
          overrideCard(
            icon: Icons.block,
            title: l10n.parentUsageRuleBlockAllDayTitle,
            subtitle: l10n.parentUsageRuleBlockAllDaySubtitle,
            color: scheme.error,
            value: DayOverrideOption.blockFullDay,
            group: selected,
            onTap: () => onChanged(DayOverrideOption.blockFullDay),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSave,
              child: Text(
                l10n.saveButton,
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
