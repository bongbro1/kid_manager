import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class WheelDatePicker extends StatefulWidget {
  final DateTime initialDate;

  const WheelDatePicker({super.key, required this.initialDate});

  @override
  State<WheelDatePicker> createState() => _WheelDatePickerState();
}

class _WheelDatePickerState extends State<WheelDatePicker> {
  late int day;
  late int month;
  late int year;

  @override
  void initState() {
    super.initState();

    day = widget.initialDate.day;
    month = widget.initialDate.month;
    year = widget.initialDate.year;
  }

  final List<int> years = List.generate(60, (i) => 1970 + i);

  int daysInMonth(int year, int month) {
    final date = DateTime(year, month + 1, 0);
    return date.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxDay = daysInMonth(year, month);

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          /// handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            l10n.addAccountSelectBirthDateTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                /// DAY
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: day - 1,
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        day = i + 1;
                      });
                    },
                    children: List.generate(
                      maxDay,
                      (i) => Center(child: Text('${i + 1}')),
                    ),
                  ),
                ),

                /// MONTH
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: month - 1,
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        month = i + 1;

                        if (day > daysInMonth(year, month)) {
                          day = daysInMonth(year, month);
                        }
                      });
                    },
                    children: List.generate(
                      12,
                      (i) => Center(child: Text('${i + 1}')),
                    ),
                  ),
                ),

                /// YEAR
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: years.indexOf(year),
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        year = years[i];

                        if (day > daysInMonth(year, month)) {
                          day = daysInMonth(year, month);
                        }
                      });
                    },
                    children: years
                        .map((y) => Center(child: Text('$y')))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, DateTime(year, month, day));
              },
              style: FilledButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.addAccountSelectButton,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
