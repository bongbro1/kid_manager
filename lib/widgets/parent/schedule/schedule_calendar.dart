import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/birthday_event.dart';
import 'package:kid_manager/models/memory_day.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/utils/schedule_utils.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';

import '../../../../../core/app_colors.dart';
import '../../../../../core/app_text_styles.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';

class ScheduleCalendar extends StatefulWidget {
  const ScheduleCalendar({super.key});

  @override
  State<ScheduleCalendar> createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.week;

  static const _selectedCircleSize = 32.0;

  static DateTime _normalizeDay(DateTime day) =>
      DateTime(day.year, day.month, day.day);

  bool _hasEntriesForDay<T>(Map<DateTime, List<T>> source, DateTime day) {
    return source[_normalizeDay(day)]?.isNotEmpty == true;
  }

  void _selectDay(DateTime selectedDay) {
    final normalized = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    final scheduleVm = context.read<ScheduleViewModel>();

    if (isSameDay(normalized, scheduleVm.selectedDate)) return;

    scheduleVm.setDate(normalized);
    context.read<MemoryDayViewModel>().setDate(normalized);
    context.read<BirthdayViewModel>().setDate(normalized);
  }

  Future<void> _changeVisibleMonth(DateTime focusedDay) async {
    final visibleMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final scheduleVm = context.read<ScheduleViewModel>();
    final currentMonth = DateTime(
      scheduleVm.focusedMonth.year,
      scheduleVm.focusedMonth.month,
      1,
    );

    if (visibleMonth == currentMonth) return;

    await Future.wait([
      scheduleVm.changeMonth(visibleMonth),
      context.read<MemoryDayViewModel>().changeMonth(visibleMonth),
      context.read<BirthdayViewModel>().changeMonth(visibleMonth),
    ]);
  }

  Widget _buildDayCell({
    required DateTime day,
    required bool isSelected,
    required bool hasMemory,
    required bool hasBirthday,
    required TextStyle textStyle,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Center(
          child: isSelected
              ? Container(
                  width: _selectedCircleSize,
                  height: _selectedCircleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.calendarSelection,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Text('${day.day}', style: textStyle),
        ),
        // ✅ chấm đỏ góc trái nếu có sinh nhật
        if (hasBirthday)
          const Positioned(
            top: 3,
            left: 7,
            child: _CalendarCornerBadge(
              icon: Icons.cake_rounded,
              iconColor: Color(0xFFDB2777),
              backgroundColor: Color(0xFFFFE5F2),
            ),
          ),
        // ✅ chấm vàng góc phải nếu có memory
        if (hasMemory)
          const Positioned(
            top: 3,
            right: 7,
            child: _CalendarCornerBadge(
              icon: Icons.star_rounded,
              iconColor: Color(0xFFE59A00),
              backgroundColor: Color(0xFFFFF5CF),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    final selectedDate = context.select<ScheduleViewModel, DateTime>(
      (vm) => vm.selectedDate,
    );
    final focusedMonth = context.select<ScheduleViewModel, DateTime>(
      (vm) => vm.focusedMonth,
    );
    final monthSchedules = context
        .select<ScheduleViewModel, Map<DateTime, List<Schedule>>>(
          (vm) => Map<DateTime, List<Schedule>>.unmodifiable(vm.monthSchedules),
        );
    final monthMemories = context
        .select<MemoryDayViewModel, Map<DateTime, List<MemoryDay>>>(
          (vm) => Map<DateTime, List<MemoryDay>>.unmodifiable(vm.monthMemories),
        );
    final monthBirthdays = context
        .select<BirthdayViewModel, Map<DateTime, List<BirthdayEvent>>>(
          (vm) => Map<DateTime, List<BirthdayEvent>>.unmodifiable(
            vm.monthBirthdays,
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _CalendarHeader(
            focusedMonth: focusedMonth,
            onPreviousMonth: () {
              _changeVisibleMonth(
                DateTime(focusedMonth.year, focusedMonth.month - 1),
              );
            },
            onNextMonth: () {
              _changeVisibleMonth(
                DateTime(focusedMonth.year, focusedMonth.month + 1),
              );
            },
          ),
          TableCalendar(
            locale: _tableCalendarLocale(context),
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, selectedDate),
            onDaySelected: (selectedDay, _) => _selectDay(selectedDay),
            onPageChanged: (focusedDay) => _changeVisibleMonth(focusedDay),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) =>
                setState(() => _calendarFormat = format),
            headerVisible: false,
            daysOfWeekHeight: 40,
            calendarStyle: CalendarStyle(
              isTodayHighlighted: false,
              selectedDecoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: scheme.onPrimary,
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              defaultTextStyle: AppTextStyles.scheduleDayNumber.copyWith(
                color: scheme.onSurface,
              ),
              weekendTextStyle: AppTextStyles.scheduleDayNumber.copyWith(
                color: scheme.onSurface,
              ),
              outsideTextStyle: AppTextStyles.scheduleDayNumber.copyWith(
                color: scheme.onSurface.withOpacity(0.35),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTextStyles.scheduleDayName.copyWith(
                color: scheme.onSurface.withOpacity(0.5),
              ),
              weekendStyle: AppTextStyles.scheduleDayName.copyWith(
                color: scheme.onSurface.withOpacity(0.5),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day: day,
                  isSelected: true,
                  hasMemory: _hasEntriesForDay(monthMemories, day),
                  hasBirthday: _hasEntriesForDay(monthBirthdays, day),
                  textStyle: AppTextStyles.scheduleDayNumber.copyWith(
                    color: scheme.onPrimary,
                  ),
                );
              },
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day: day,
                  isSelected: false,
                  hasMemory: _hasEntriesForDay(monthMemories, day),
                  hasBirthday: _hasEntriesForDay(monthBirthdays, day),
                  textStyle: AppTextStyles.scheduleDayNumber.copyWith(
                    color: scheme.onSurface,
                  ),
                );
              },
              outsideBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day: day,
                  isSelected: false,
                  hasMemory: _hasEntriesForDay(monthMemories, day),
                  hasBirthday: _hasEntriesForDay(monthBirthdays, day),
                  textStyle: AppTextStyles.scheduleDayNumber.copyWith(
                    color: scheme.onSurface.withOpacity(0.35),
                  ),
                );
              },
              dowBuilder: (context, day) => Center(
                child: Text(
                  _weekdayShortName(day, l10n),
                  style: AppTextStyles.scheduleDayName.copyWith(
                    color: scheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
              markerBuilder: (_, date, _) {
                final key = DateTime(date.year, date.month, date.day);
                final daySchedules = monthSchedules[key] ?? const [];

                if (daySchedules.isEmpty) {
                  return const SizedBox.shrink();
                }

                final periods =
                    daySchedules.map((s) => s.period).toSet().toList()
                      ..sort((a, b) => a.index.compareTo(b.index));

                return Positioned(
                  bottom: 3,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      periods.length,
                      (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: schedulePeriodColor(periods[i]),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            availableCalendarFormats: {
              CalendarFormat.month: l10n.scheduleCalendarFormatMonth,
              CalendarFormat.week: l10n.scheduleCalendarFormatWeek,
            },
            pageAnimationEnabled: true,
          ),
          GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 10 &&
                  _calendarFormat == CalendarFormat.week) {
                setState(() => _calendarFormat = CalendarFormat.month);
              } else if (details.delta.dy < -10 &&
                  _calendarFormat == CalendarFormat.month) {
                setState(() => _calendarFormat = CalendarFormat.week);
              }
            },
            child: Container(
              width: double.infinity,
              height: 20,
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outline.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayShortName(DateTime day, AppLocalizations l10n) {
    switch (day.weekday) {
      case DateTime.monday:
        return l10n.scheduleWeekdayMon;
      case DateTime.tuesday:
        return l10n.scheduleWeekdayTue;
      case DateTime.wednesday:
        return l10n.scheduleWeekdayWed;
      case DateTime.thursday:
        return l10n.scheduleWeekdayThu;
      case DateTime.friday:
        return l10n.scheduleWeekdayFri;
      case DateTime.saturday:
        return l10n.scheduleWeekdaySat;
      case DateTime.sunday:
        return l10n.scheduleWeekdaySun;
      default:
        return '';
    }
  }

  String _tableCalendarLocale(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'vi':
        return 'vi_VN';
      case 'en':
        return 'en_US';
      default:
        return 'en_US';
    }
  }
}

class _CalendarCornerBadge extends StatelessWidget {
  const _CalendarCornerBadge({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 8.5, color: iconColor),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPreviousMonth,
            icon: Icon(Icons.chevron_left, color: scheme.onSurface),
          ),
          Column(
            children: [
              Text(
                l10n.scheduleCalendarMonthLabel(focusedMonth.month),
                style: AppTextStyles.scheduleMonthYear.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              Text(
                '${focusedMonth.year}',
                style: AppTextStyles.scheduleYear.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: onNextMonth,
            icon: Icon(Icons.chevron_right, color: scheme.onSurface),
          ),
        ],
      ),
    );
  }
}
