import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';
import 'package:kid_manager/views/parent/dashboard/edit_screen_widgets/edit_screen_widgets.dart';
import 'package:kid_manager/widgets/app/app_button.dart';

class MainUsageEditor extends StatelessWidget {
  final UsageRule rule;

  final double screenHeight;

  final DateTime gridMonth;
  final DateTime headerMonth;
  final DateTime? selectedDate;

  final Map<DateTime, DotType> dotsByDay;

  final VoidCallback onCancel;
  final VoidCallback onSave;

  final ValueChanged<bool> onToggleEnabled;

  final VoidCallback onAddWindow;
  final Function(int) onRemoveWindow;
  final Function(int) onPickStart;
  final Function(int) onPickEnd;

  final ValueChanged<Set<int>> onWeekdaysChanged;

  final Function(DateTime) onMonthChanged;
  final Function(DateTime) onDayTap;

  const MainUsageEditor({
    super.key,
    required this.rule,
    required this.screenHeight,
    required this.gridMonth,
    required this.headerMonth,
    required this.selectedDate,
    required this.dotsByDay,
    required this.onCancel,
    required this.onSave,
    required this.onToggleEnabled,
    required this.onAddWindow,
    required this.onRemoveWindow,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onWeekdaysChanged,
    required this.onMonthChanged,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
          ),
        ),

        const SizedBox(height: 18),

        Divider(height: 1, color: theme.dividerTheme.color),

        const SizedBox(height: 8),

        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ===== ENABLE SWITCH =====
                Row(
                  children: [
                    Text(
                      l10n.parentUsageEnableUsage,
                      style: textTheme.titleSmall?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: rule.enabled,
                      onChanged: onToggleEnabled,
                      activeColor: scheme.onPrimary,
                      activeTrackColor: scheme.primary,
                      inactiveThumbColor: scheme.outline,
                      inactiveTrackColor: scheme.outline.withOpacity(0.3),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// ===== TIME WINDOWS =====
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
                          onPickStart: () => onPickStart(i),
                          onPickEnd: () => onPickEnd(i),
                          onDelete: () => onRemoveWindow(i),
                        ),
                      );
                    }),

                    if (rule.enabled)
                      InkWell(
                        onTap: onAddWindow,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outline),
                          ),
                          child: Icon(Icons.add, color: scheme.onSurface),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                /// ===== WEEKDAYS =====
                Text(
                  l10n.parentUsageSelectAllowedDays,
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
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
                                selected ? next.remove(day) : next.add(day);
                                onWeekdaysChanged(next);
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
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                /// ===== CALENDAR =====
                buildCalendar(
                  context: context,
                  l10n: l10n,
                  month: gridMonth,
                  headerMonth: headerMonth,
                  selected: selectedDate,
                  dotsByDay: dotsByDay,
                  onMonthChanged: onMonthChanged,
                  onDayTap: onDayTap,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: 30,
          height: 3,
          decoration: BoxDecoration(
            color: scheme.outline,
            borderRadius: BorderRadius.circular(100),
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
                fontWeight: FontWeight.w700,
                fontSize: Theme.of(context).appTypography.itemTitle.fontSize!,
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
                fontWeight: FontWeight.w700,
                fontSize: Theme.of(context).appTypography.itemTitle.fontSize!,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
