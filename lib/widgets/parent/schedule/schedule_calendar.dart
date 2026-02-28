import 'package:flutter/material.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/utils/schedule_utils.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';

import '../../../../../core/app_colors.dart';
import '../../../../../core/app_text_styles.dart';
import '../../../../../viewmodels/schedule_vm.dart';


class ScheduleCalendar extends StatefulWidget {
  const ScheduleCalendar({super.key});

  @override
  State<ScheduleCalendar> createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.week;

  static const _selectedCircleSize = 32.0;

  Widget _buildDayCell({
  required DateTime day,
  required bool isSelected,
  required bool hasMemory,
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

      // ✅ chấm vàng góc phải
      if (hasMemory)
        const Positioned(
          top: 6,
          right: 10,
          child: SizedBox(
            width: 6,
            height: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFF4B400),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();
    final memoryVm = context.watch<MemoryDayViewModel>();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const _CalendarHeader(),
          TableCalendar(
            locale: 'vi_VN',
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2050, 12, 31),
            focusedDay: scheduleVm.selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, scheduleVm.selectedDate),
            onDaySelected: (selectedDay, _) {
              scheduleVm.setDate(selectedDay);
              memoryVm.setDate(selectedDay);
            },
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            headerVisible: false,
            daysOfWeekHeight: 40,
            calendarStyle: CalendarStyle(
              isTodayHighlighted: false,
              selectedDecoration: const BoxDecoration(
                color: AppColors.calendarSelection,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              defaultTextStyle: AppTextStyles.scheduleDayNumber,
              weekendTextStyle: AppTextStyles.scheduleDayNumber,
              outsideTextStyle: const TextStyle(
                color: Color(0xFFBCC1CD),
                fontFamily: 'Poppins',
                fontSize: 15,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: AppTextStyles.scheduleDayName,
              weekendStyle: AppTextStyles.scheduleDayName,
            ),
            calendarBuilders: CalendarBuilders(
              selectedBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day: day,
                  isSelected: true,
                  hasMemory: memoryVm.hasMemory(day),
                  textStyle: AppTextStyles.scheduleDayNumber,
                );
              },

              // ✅ thêm ngay dưới selectedBuilder
              defaultBuilder: (context, day, focusedDay) {
                return _buildDayCell(
                  day: day,
                  isSelected: false,
                  hasMemory: memoryVm.hasMemory(day),
                  textStyle: AppTextStyles.scheduleDayNumber,
                );
              },

              dowBuilder: (context, day) => Center(
                child: Text(
                  _weekdayShortName(day),
                  style: AppTextStyles.scheduleDayName.copyWith(
                    color: const Color(0xFFBCC1CD),
                  ),
                ),
              ),

              markerBuilder: (_, date, __) {
                final key = DateTime(date.year, date.month, date.day);
                final daySchedules = scheduleVm.monthSchedules[key] ?? const [];

                if (daySchedules.isEmpty) {
                  return const SizedBox.shrink();
                }

                final periods = daySchedules
                    .map((s) => s.period)
                    .toSet()
                    .toList()
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
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
              CalendarFormat.week: 'Week',
            },
            pageAnimationEnabled: true,
          ),
          GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 10 && _calendarFormat == CalendarFormat.week) {
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
                    color: const Color(0xFFE0E0E0),
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

  String _weekdayShortName(DateTime day) {
    switch (day.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader();

  @override
  Widget build(BuildContext context) {
    final scheduleVm = context.watch<ScheduleViewModel>();
    final memoryVm = context.watch<MemoryDayViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              final newMonth = DateTime(scheduleVm.selectedDate.year, scheduleVm.selectedDate.month - 1);
              scheduleVm.changeMonth(newMonth);
              memoryVm.changeMonth(newMonth);
            },
            icon: const Icon(Icons.chevron_left, color: AppColors.darkText),
          ),
          Column(
            children: [
              Text('Tháng ${scheduleVm.selectedDate.month}', style: AppTextStyles.scheduleMonthYear),
              Text('${scheduleVm.selectedDate.year}', style: AppTextStyles.scheduleYear),
            ],
          ),
          IconButton(
            onPressed: () {
              final newMonth = DateTime(scheduleVm.selectedDate.year, scheduleVm.selectedDate.month + 1);
              scheduleVm.changeMonth(newMonth);
              memoryVm.changeMonth(newMonth);
            },
            icon: const Icon(Icons.chevron_right, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }
}
