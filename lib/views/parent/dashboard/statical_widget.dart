import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:table_calendar/table_calendar.dart';
class BarWidget extends StatelessWidget {
  final double width;
  final double greyHeight;
  final double blueHeight;
  final String label;
  final bool active;
  final bool faded;

  const BarWidget({
    super.key,
    required this.width,
    required this.greyHeight,
    required this.blueHeight,
    required this.label,
    this.active = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final barColor = active
        ? scheme.primary
        : faded
            ? scheme.outline.withOpacity(0.35)
            : scheme.primary.withOpacity(0.4);

    final labelColor = active
        ? scheme.primary
        : scheme.onSurface.withOpacity(0.55);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: width,
          height: greyHeight,
          decoration: BoxDecoration(
            color: scheme.outline.withOpacity(0.16),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: blueHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: labelColor,
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


class TooltipWidget extends StatelessWidget {
  final int value;

  const TooltipWidget({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          formatMinutes(value, l10n: AppLocalizations.of(context)),
          style: textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: scheme.onPrimary,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: scheme.shadow.withOpacity(0.08),
          ),
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

            if (_start == null || (_start != null && _end != null)) {
              _start = selectedDay;
              _end = null;
            } else {
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
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ) ??
              TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: scheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: scheme.onSurface,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ) ??
              TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
              ),
          weekendStyle: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ) ??
              TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
              ),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ) ??
              TextStyle(color: scheme.onSurface),
          weekendTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
              ) ??
              TextStyle(color: scheme.onSurface),
          outsideTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.35),
              ) ??
              TextStyle(color: scheme.onSurface.withOpacity(0.35)),
          disabledTextStyle: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.25),
              ) ??
              TextStyle(color: scheme.onSurface.withOpacity(0.25)),
          rangeHighlightColor: scheme.primary.withOpacity(0.16),
          rangeStartDecoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          rangeEndDecoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          withinRangeTextStyle: TextStyle(
            color: scheme.onSurface,
          ),
          withinRangeDecoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            shape: BoxShape.rectangle,
          ),
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary),
          ),
          todayTextStyle: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
          selectedDecoration: BoxDecoration(
            color: scheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
