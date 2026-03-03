import 'package:flutter/material.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:table_calendar/table_calendar.dart';

class BarWidget extends StatelessWidget {
  final double width;
  final double height;
  final double valueHeight;
  final String label;
  final bool active;
  final bool faded;

  const BarWidget({
    required this.width,
    required this.height,
    required this.valueHeight,
    required this.label,
    this.active = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = active
        ? const Color(0xFF3B82F6)
        : faded
        ? const Color(0xFFE2E8F0)
        : const Color(0x663B82F6);

    final labelColor = active
        ? const Color(0xFF3B82F6)
        : const Color(0xFF94A3B8);

    return SizedBox(
      width: width,
      height: height + 45,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          /// BAR + LABEL
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: height,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: valueHeight,
                      decoration: BoxDecoration(
                        color: valueColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 10,
                    fontFamily: 'Inter',
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TooltipWidget extends StatelessWidget {
  final int value;

  const TooltipWidget({required this.value});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          formatMinutes(value),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class CustomRangeCalendar extends StatefulWidget {
  final DateTime? fromDate;
  final DateTime? toDate;
  final Function(DateTime?) onFromChanged;
  final Function(DateTime?) onToChanged;

  const CustomRangeCalendar({
    super.key,
    this.fromDate,
    this.toDate,
    required this.onFromChanged,
    required this.onToChanged,
  });

  @override
  State<CustomRangeCalendar> createState() => _CustomRangeCalendarState();
}

class _CustomRangeCalendarState extends State<CustomRangeCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    _start = widget.fromDate;
    _end = widget.toDate;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(blurRadius: 12, color: Colors.black.withOpacity(0.05)),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2100),
        focusedDay: _focusedDay,
        rangeStartDay: _start,
        rangeEndDay: _end,
        rangeSelectionMode: RangeSelectionMode.toggledOn,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;

            // Case 1: chưa có start → chọn start
            if (_start == null || (_start != null && _end != null)) {
              _start = selectedDay;
              _end = null;
            }
            // Case 2: đã có start → chọn end
            else {
              if (selectedDay.isBefore(_start!)) {
                _end = _start;
                _start = selectedDay;
              } else {
                _end = selectedDay;
              }
            }
          });

          widget.onFromChanged(_start);
          widget.onToChanged(_end);
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        calendarStyle: CalendarStyle(
          rangeHighlightColor: const Color(0xFFDBEAFE),
          rangeStartDecoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: const BoxDecoration(
            color: Color(0xFF3B82F6),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3B82F6)),
          ),
          todayTextStyle: const TextStyle(color: Color(0xFF3B82F6)),
        ),
      ),
    );
  }
}
