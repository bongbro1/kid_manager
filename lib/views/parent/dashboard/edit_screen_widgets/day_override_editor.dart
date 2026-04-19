import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';
import 'package:kid_manager/views/parent/dashboard/edit_screen_widgets/edit_screen_widgets.dart';

class DayOverrideEditor extends StatelessWidget {
  final DateTime date;
  final DayOverrideOption selectedOption;
  final ValueChanged<DayOverrideOption> onOptionChanged;
  final VoidCallback onBack;
  final VoidCallback onSave;

  const DayOverrideEditor({
    super.key,
    required this.date,
    required this.selectedOption,
    required this.onOptionChanged,
    required this.onBack,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            Material(
              color: scheme.surfaceContainerHighest.withOpacity(0.55),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Text(
                    l10n.parentUsageDayRuleModalHint,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatDate(date),
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 52),
          ],
        ),
        const SizedBox(height: 24),
        _OverrideOptionCard(
          icon: Icons.schedule_rounded,
          title: l10n.parentUsageRuleFollowScheduleTitle,
          subtitle: l10n.parentUsageRuleFollowScheduleSubtitle,
          accent: scheme.primary,
          value: DayOverrideOption.followSchedule,
          selectedOption: selectedOption,
          onTap: () => onOptionChanged(DayOverrideOption.followSchedule),
        ),
        const SizedBox(height: 12),
        _OverrideOptionCard(
          icon: Icons.check_circle_rounded,
          title: l10n.parentUsageRuleAllowAllDayTitle,
          subtitle: l10n.parentUsageRuleAllowAllDaySubtitle,
          accent: const Color(0xFF22C55E),
          value: DayOverrideOption.allowFullDay,
          selectedOption: selectedOption,
          onTap: () => onOptionChanged(DayOverrideOption.allowFullDay),
        ),
        const SizedBox(height: 12),
        _OverrideOptionCard(
          icon: Icons.block_rounded,
          title: l10n.parentUsageRuleBlockAllDayTitle,
          subtitle: l10n.parentUsageRuleBlockAllDaySubtitle,
          accent: scheme.error,
          value: DayOverrideOption.blockFullDay,
          selectedOption: selectedOption,
          onTap: () => onOptionChanged(DayOverrideOption.blockFullDay),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.only(bottom: bottomSafe > 0 ? bottomSafe : 0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                l10n.saveButton,
                style: textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: Theme.of(context).appTypography.itemTitle.fontSize!,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverrideOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final DayOverrideOption value;
  final DayOverrideOption selectedOption;
  final VoidCallback onTap;

  const _OverrideOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.value,
    required this.selectedOption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isSelected = selectedOption == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isSelected
            ? accent.withOpacity(0.08)
            : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? accent.withOpacity(0.95)
              : scheme.outlineVariant.withOpacity(0.55),
          width: isSelected ? 1.4 : 1,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: accent.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withOpacity(0.16)
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? accent : scheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.64),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : scheme.outline.withOpacity(0.55),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
