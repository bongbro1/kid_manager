import 'package:flutter/material.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/utils/schedule_utils.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();

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
            focusedDay: vm.selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, vm.selectedDate),
            onDaySelected: (selectedDay, _) => vm.setDate(selectedDay),
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
                return Center(
                  child: Container(
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
                  ),
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
                final daySchedules = vm.monthSchedules[key] ?? const [];

                if (daySchedules.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Lấy tập period có trong ngày (không lặp)
                final periods = daySchedules
                    .map((s) => s.period)
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.index.compareTo(b.index)); 
                // đảm bảo thứ tự: morning -> afternoon -> evening

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
                          color: schedulePeriodColor(periods[i]), // ✅ dùng chung util
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
    final vm = context.watch<ScheduleViewModel>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => vm.changeMonth(
              DateTime(vm.selectedDate.year, vm.selectedDate.month - 1),
            ),
            icon: const Icon(Icons.chevron_left, color: AppColors.darkText),
          ),
          Column(
            children: [
              Text('Tháng ${vm.selectedDate.month}', style: AppTextStyles.scheduleMonthYear),
              Text('${vm.selectedDate.year}', style: AppTextStyles.scheduleYear),
            ],
          ),
          IconButton(
            onPressed: () => vm.changeMonth(
              DateTime(vm.selectedDate.year, vm.selectedDate.month + 1),
            ),
            icon: const Icon(Icons.chevron_right, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }
}
