import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

Widget timeRangeRow({
  required BuildContext context,
  required TimeWindow window,
  required bool enabled,
  required VoidCallback onPickStart,
  required VoidCallback onPickEnd,
  required VoidCallback onDelete,
}) {
  final scheme = Theme.of(context).colorScheme;

  String fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Widget timeBox(String text, VoidCallback? onTap) {
    final boxColor = enabled
        ? scheme.surface
        : scheme.surface.withOpacity(0.45);

    final textColor = enabled
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(0.45);

    final borderColor = enabled
        ? scheme.outline
        : scheme.outline.withOpacity(0.6);

    final iconColor = enabled
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(0.45);

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: Theme.of(context).appTypography.itemTitle.fontSize!,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.access_time, size: 16, color: iconColor),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: scheme.onSurface.withOpacity(0.5),
          ),
        ),
        timeBox(fmt(window.endMin), onPickEnd),
      ],
    ),
  );
}

Widget overrideCard({
  required BuildContext context,
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: Theme.of(
                      context,
                    ).appTypography.sectionLabel.fontSize!,
                  ),
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

String formatDate(DateTime d) {
  return "${d.day}/${d.month}/${d.year}";
}

Widget buildCalendar({
  required BuildContext context,
  required AppLocalizations l10n,
  required DateTime month,
  required DateTime headerMonth,
  required DateTime? selected,
  required void Function(DateTime newMonth) onMonthChanged,
  required void Function(DateTime day) onDayTap,
  required Map<DateTime, DotType> dotsByDay,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  final firstDayOfMonth = DateTime(month.year, month.month, 1);

  final int leading = (firstDayOfMonth.weekday - DateTime.monday) % 7;
  final totalCells = 35;

  DateTime norm(DateTime d) => DateTime(d.year, d.month, d.day);
  final sel = selected == null ? null : norm(selected);

  final weekdays = [
    l10n.scheduleWeekdayMon,
    l10n.scheduleWeekdayTue,
    l10n.scheduleWeekdayWed,
    l10n.scheduleWeekdayThu,
    l10n.scheduleWeekdayFri,
    l10n.scheduleWeekdaySat,
    l10n.scheduleWeekdaySun,
  ];

  DateTime d(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _monthNavButton(
            context: context,
            icon: Icons.chevron_left,
            onTap: () =>
                onMonthChanged(DateTime(month.year, month.month - 1, 1)),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.scheduleCalendarMonthLabel(headerMonth.month),
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontSize: Theme.of(context).appTypography.title.fontSize!,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${headerMonth.year}',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                    fontSize: Theme.of(
                      context,
                    ).appTypography.sectionLabel.fontSize!,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _monthNavButton(
            context: context,
            icon: Icons.chevron_right,
            onTap: () =>
                onMonthChanged(DateTime(month.year, month.month + 1, 1)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      GridView.count(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 30 / 29,
        children: weekdays
            .map(
              (w) => Center(
                child: Text(
                  w,
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                    fontSize: Theme.of(context).appTypography.body.fontSize!,
                    fontWeight: FontWeight.w400,
                    height: 1.23,
                  ),
                ),
              ),
            )
            .toList(),
      ),

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
          final cellDate = firstDayOfMonth.subtract(
            Duration(days: leading - i),
          );
          final inMonth = cellDate.month == month.month;

          final isSelected = sel != null && norm(cellDate) == sel;
          final dotType = dotsByDay[d(cellDate)] ?? DotType.none;

          return _dayCell(
            context: context,
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

Widget _monthNavButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: scheme.onSurface),
    ),
  );
}

Widget _dayCell({
  required BuildContext context,
  required String label,
  required bool inMonth,
  required bool selected,
  required DotType dot,
  VoidCallback? onTap,
}) {
  final scheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  final bg = selected ? scheme.primary : Colors.transparent;

  final textColor = selected
      ? scheme.onPrimary
      : (inMonth ? scheme.onSurface : scheme.onSurface.withOpacity(0.5));

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w400,
                fontSize: Theme.of(context).appTypography.body.fontSize!,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (dot != DotType.none)
          Opacity(
            opacity: inMonth ? 1 : 0.5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color:
                        dotColorMap[dot] ??
                        (dot == DotType.block ? scheme.error : scheme.primary),
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
