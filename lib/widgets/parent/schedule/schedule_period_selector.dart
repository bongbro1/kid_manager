import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import '../../../models/schedule.dart';

class SchedulePeriodSelector extends StatelessWidget {
  final SchedulePeriod? value;
  final ValueChanged<SchedulePeriod>? onChanged;
  final bool enabled;

  const SchedulePeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canTap = enabled && onChanged != null;
    final typography = Theme.of(context).appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.schedulePeriodTitle,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: typography.title.fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: SchedulePeriod.values.map((p) {
            final selected = value == p;
            final style = _periodStyle(p);
            final colorScheme = Theme.of(context).colorScheme;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: p == SchedulePeriod.values.last ? 0 : 12,
                ),
                child: AnimatedScale(
                  scale: selected ? 1.0 : 0.97,
                  duration: const Duration(milliseconds: 120),
                  child: GestureDetector(
                    onTap: canTap ? () => onChanged!(p) : null,
                    child: Opacity(
                      opacity: enabled ? 1.0 : 0.7,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected
                              ? style.selectedBg
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected
                                ? style.dotColor
                                : colorScheme.onSurface.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: style.dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              _periodLabel(l10n, p),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: typography.body.fontSize,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? style.dotColor
                                    : colorScheme.onSurface.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PeriodStyle {
  final Color dotColor;
  final Color selectedBg;

  const _PeriodStyle({required this.dotColor, required this.selectedBg});
}

_PeriodStyle _periodStyle(SchedulePeriod p) {
  switch (p) {
    case SchedulePeriod.morning:
      return const _PeriodStyle(
        dotColor: Color(0xFF8B5CF6),
        selectedBg: Color(0xFFEDE9FE),
      );
    case SchedulePeriod.afternoon:
      return const _PeriodStyle(
        dotColor: Color(0xFF00B383),
        selectedBg: Color(0xFFE7F7F1),
      );
    case SchedulePeriod.evening:
      return const _PeriodStyle(
        dotColor: Color(0xFF3B82F6),
        selectedBg: Color(0xFFE8F1FF),
      );
  }
}

String _periodLabel(AppLocalizations l10n, SchedulePeriod p) {
  switch (p) {
    case SchedulePeriod.morning:
      return l10n.schedulePeriodMorning;
    case SchedulePeriod.afternoon:
      return l10n.schedulePeriodAfternoon;
    case SchedulePeriod.evening:
      return l10n.schedulePeriodEvening;
  }
}
