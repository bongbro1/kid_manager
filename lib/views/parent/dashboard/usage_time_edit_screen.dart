import 'package:flutter/material.dart';
import 'package:kid_manager/utils/time_window_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

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
  final labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  Map<String, DayOverride> overrides = {};

  bool unlimited = false;
  int minutes = 60;

  @override
  void initState() {
    super.initState();
    rule = UsageRule.defaults();
    // debugPrint('INIT rule: ${rule.pretty()}');

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

    if (fetched != null) {
      setState(() {
        rule = fetched;
        overrides = fetched.overrides;
        _fillDotsFromOverrides();
      });
    }
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
    if (next.contains(day))
      next.remove(day);
    else
      next.add(day);

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
    final slot = TimeWindowUtils.findAvailableSlot(rule.windows);

    if (slot == null) {
      _showInvalidRangeSnack("Không còn khoảng thời gian trống");
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
    final w = rule.windows[i];

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: w.startMin ~/ 60, minute: w.startMin % 60),
    );

    if (picked == null) return;

    final newStart = picked.hour * 60 + picked.minute;

    if (newStart >= w.endMin) {
      _showInvalidRangeSnack("Giờ bắt đầu phải nhỏ hơn giờ kết thúc");
      return;
    }

    final newWindow = TimeWindow(startMin: newStart, endMin: w.endMin);

    if (_isOverlapping(newWindow, i)) {
      _showInvalidRangeSnack("Khoảng thời gian bị trùng với mốc khác");
      return;
    }

    setState(() {
      final newWindows = [...rule.windows];
      newWindows[i] = newWindow;
      rule = rule.copyWith(windows: newWindows);
    });
  }

  Future<void> pickEnd(int i) async {
    final w = rule.windows[i];

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: w.endMin ~/ 60, minute: w.endMin % 60),
    );

    if (picked == null) return;

    final newEnd = picked.hour * 60 + picked.minute;

    if (newEnd <= w.startMin) {
      _showInvalidRangeSnack("Giờ kết thúc phải lớn hơn giờ bắt đầu");
      return;
    }

    final newWindow = TimeWindow(startMin: w.startMin, endMin: newEnd);

    if (_isOverlapping(newWindow, i)) {
      _showInvalidRangeSnack("Khoảng thời gian bị trùng với mốc khác");
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppManagementVM>();

    if (vm.loading) {
      return LoadingOverlay();
    }

    return AppOverlaySheet(
      height: 640,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  'Cài đặt thời gian sử dụng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF222B45),
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    height: 1.10,
                  ),
                ),

                const SizedBox(height: 18),
                Container(
                  width: 350,
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        width: 1,
                        strokeAlign: BorderSide.strokeAlignCenter,
                        color: const Color(0xFFEDEDED),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  height: 540, // 👈 ép vùng scroll
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Cho phép sử dụng',
                              style: TextStyle(
                                color: Color(0xFF222B45),
                                fontSize: 16,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                height: 1.38,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: rule.enabled,
                              onChanged: (v) {
                                setState(
                                  () => rule = rule.copyWith(enabled: v),
                                );
                              },

                              activeColor: Colors.white,
                              activeTrackColor: const Color(0xFF2F6BFF),
                              inactiveThumbColor: const Color(0xFF8F9BB3),
                              inactiveTrackColor: const Color(0xFFE4E9F2),

                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              overlayColor: MaterialStateProperty.all(
                                Colors.transparent,
                              ), // ✅ bỏ loang
                              splashRadius: 0, // ✅ bỏ splash
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
                                child: _timeRangeRow(
                                  window: w,
                                  enabled: rule.enabled,
                                  onPickStart: () => pickStart(i),
                                  onPickEnd: () => pickEnd(i),
                                  onDelete: () => removeWindow(i),
                                ),
                              );
                            }),

                            /// ADD BUTTON
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
                                      color: const Color(0xFFE4E9F2),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Icon(Icons.add),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Chọn ngày được phép',
                            style: TextStyle(
                              color: Color(0xFF222B45),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              height: 1.19,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: List.generate(7, (index) {
                            final day = index + 1; // 1 = Monday
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

                                        debugPrint(
                                          "📅 Weekdays changed → ${rule.weekdays}",
                                        );
                                      }
                                    : null,
                                child: Container(
                                  height: 36,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFF2F6BFF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFEDF1F7),
                                    ),
                                  ),
                                  child: Text(
                                    labels[index],
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF8F9BB3),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 27),
                        buildCalendar(
                          month: _gridMonth,
                          headerMonth: _headerMonth,
                          selected: _selectedDate,
                          dotsByDay: _dotsByDay,

                          onMonthChanged: (m) => setState(() {
                            _gridMonth = DateTime(m.year, m.month, 1);
                            _headerMonth = _gridMonth;
                          }),
                          onDayTap: (cellDate) async {
                            setState(() {
                              _selectedDate = cellDate;
                              _headerMonth = DateTime(
                                cellDate.year,
                                cellDate.month,
                                1,
                              );
                            });
                            final key = toKey(cellDate);
                            final current = overrides[key];

                            final result = await showDayOverrideModal(
                              context: context,
                              date: cellDate,
                              current: toOption(current),
                            );

                            if (result == null) return;

                            setState(() {
                              final newOverride = fromOption(result);

                              if (newOverride == null) {
                                overrides.remove(key);
                              } else {
                                overrides[key] = newOverride;
                              }
                              _fillDotsFromOverrides();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                Center(
                  child: Container(
                    width: 30,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6E6E6),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: "Hủy",
                        width: 172,
                        height: 50,
                        backgroundColor: Color(0xFF3A7DFF),
                        fontSize: 16,
                        lineHeight: 1.38,
                        fontWeight: FontWeight.w700,
                        onPressed: onCancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        text: "Lưu",
                        width: 172,
                        height: 50,
                        backgroundColor: Color(0xFF3A7DFF),
                        fontSize: 16,
                        lineHeight: 1.38,
                        fontWeight: FontWeight.w700,
                        onPressed: onSavePressed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeRangeRow({
    required TimeWindow window,
    required bool enabled,
    required VoidCallback onPickStart,
    required VoidCallback onPickEnd,
    required VoidCallback onDelete,
  }) {
    String fmt(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

    Widget timeBox(String text, VoidCallback? onTap) {
      return Expanded(
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? Colors.white : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E9F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: enabled ? const Color(0xFF222B45) : Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.access_time, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: enabled ? onDelete : null,
      child: Row(
        children: [
          timeBox(fmt(window.startMin), onPickStart),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),

          timeBox(fmt(window.endMin), onPickEnd),
        ],
      ),
    );
  }
}

Future<DayOverrideOption?> showDayOverrideModal({
  required BuildContext context,
  required DateTime date,
  required DayOverrideOption current,
}) {
  return showModalBottomSheet<DayOverrideOption>(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    builder: (context) {
      DayOverrideOption selected = current;

      return StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                Column(
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Chọn quy tắc cho ngày này",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Options
                _overrideCard(
                  icon: Icons.schedule,
                  title: "Theo lịch đã đặt",
                  subtitle: "Áp dụng khung giờ hàng tuần",
                  color: Colors.grey,
                  value: DayOverrideOption.followSchedule,
                  group: selected,
                  onTap: () => setState(() {
                    selected = DayOverrideOption.followSchedule;
                  }),
                ),

                const SizedBox(height: 12),

                _overrideCard(
                  icon: Icons.check_circle,
                  title: "Cho phép cả ngày",
                  subtitle: "Có thể sử dụng bất cứ lúc nào",
                  color: Colors.green,
                  value: DayOverrideOption.allowFullDay,
                  group: selected,
                  onTap: () => setState(() {
                    selected = DayOverrideOption.allowFullDay;
                  }),
                ),

                const SizedBox(height: 12),

                _overrideCard(
                  icon: Icons.block,
                  title: "Chặn cả ngày",
                  subtitle: "Không được sử dụng hôm nay",
                  color: Colors.red,
                  value: DayOverrideOption.blockFullDay,
                  group: selected,
                  onTap: () => setState(() {
                    selected = DayOverrideOption.blockFullDay;
                  }),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      debugPrint("🟢 Save tapped with: $selected");
                      Navigator.of(context).pop(selected);
                    },
                    child: const Text("Lưu"),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _overrideCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required DayOverrideOption value,
  required DayOverrideOption group,
  required VoidCallback onTap,
}) {
  final isSelected = value == group;

  return InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: 1.5,
        ),
        color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          if (isSelected) Icon(Icons.check_circle, color: color),
        ],
      ),
    ),
  );
}

Widget _optionTile({
  required String title,
  required DayOverrideOption value,
  required DayOverrideOption group,
  required ValueChanged<DayOverrideOption> onChanged,
}) {
  return RadioListTile<DayOverrideOption>(
    title: Text(title),
    value: value,
    groupValue: group,
    onChanged: (v) => onChanged(v!),
  );
}

String _formatDate(DateTime d) {
  return "${d.day}/${d.month}/${d.year}";
}

Widget buildCalendar({
  required DateTime month,
  required DateTime headerMonth,
  required DateTime? selected,
  required void Function(DateTime newMonth) onMonthChanged,
  required void Function(DateTime day) onDayTap,
  required Map<DateTime, DotType> dotsByDay,
}) {
  final firstDayOfMonth = DateTime(month.year, month.month, 1);
  final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

  // Thứ 2 = 1 ... CN = 7, mình muốn grid bắt đầu từ T2
  final int leading = (firstDayOfMonth.weekday - DateTime.monday) % 7; // 0..6
  final totalDays = lastDayOfMonth.day;
  final totalCells = 35;

  DateTime norm(DateTime d) => DateTime(d.year, d.month, d.day);
  final sel = selected == null ? null : norm(selected);

  String monthTitle(int m) => 'Tháng $m';
  const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  DateTime _d(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header: arrows + month/year
      Row(
        children: [
          _monthNavButton(
            icon: Icons.chevron_left,
            onTap: () =>
                onMonthChanged(DateTime(month.year, month.month - 1, 1)),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  monthTitle(headerMonth.month),
                  style: TextStyle(
                    color: const Color(0xFF222B45),
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 0.80,
                  ),
                ),

                const SizedBox(height: 6),
                Text(
                  '${headerMonth.year}',
                  style: TextStyle(
                    color: const Color(0xFF8F9BB3),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
              ],
            ),
          ),
          _monthNavButton(
            icon: Icons.chevron_right,
            onTap: () =>
                onMonthChanged(DateTime(month.year, month.month + 1, 1)),
          ),
        ],
      ),

      // Weekday row
      GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 30 / 29, // giống cell của bạn
        children: weekdays
            .map(
              (w) => Center(
                child: Text(
                  w,
                  style: const TextStyle(
                    color: Color(0xFF8F9BB3),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w400,
                    height: 1.23,
                  ),
                ),
              ),
            )
            .toList(),
      ),

      // Grid days
      GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCells,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, i) {
          // ngày đầu của grid = firstDayOfMonth lùi lại "leading" ngày
          final cellDate = firstDayOfMonth.subtract(
            Duration(days: leading - i),
          );
          final inMonth = cellDate.month == month.month;

          final isSelected = sel != null && norm(cellDate) == sel;
          final dotType = dotsByDay[_d(cellDate)] ?? DotType.none;

          return _dayCell(
            label: '${cellDate.day}',
            inMonth: inMonth,
            selected: isSelected,
            dot: dotType,
            onTap: () => onDayTap(cellDate),
          );
        },
      ),
    ],
  );
}

Widget _monthNavButton({required IconData icon, required VoidCallback onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEDF1F7)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF4A4A4A)),
    ),
  );
}

Widget _dayCell({
  required String label,
  required bool inMonth,
  required bool selected,
  required DotType dot,
  VoidCallback? onTap,
}) {
  final bg = selected ? const Color(0xFF2F6BFF) : Colors.transparent;

  final textColor = selected
      ? Colors.white
      : (inMonth ? const Color(0xFF1F2A4A) : const Color(0xFF8F9BB3));

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 29,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w400,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (dot != null)
          Opacity(
            opacity: inMonth ? 1 : 0.5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dotColorMap[dot],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
