import 'package:flutter/material.dart';
import '../../../models/schedule.dart';

class SchedulePeriodSelector extends StatelessWidget {
  final SchedulePeriod? value;
  final ValueChanged<SchedulePeriod> onChanged;

  const SchedulePeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời gian',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: SchedulePeriod.values.map((p) {
            final selected = value == p;
            final style = _periodStyle(p);

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: p == SchedulePeriod.values.last ? 0 : 12,
                ),
                child: AnimatedScale(
                  scale: selected ? 1.0 : 0.97,
                  duration: const Duration(milliseconds: 120),
                  child: GestureDetector(
                    onTap: () => onChanged(p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? style.selectedBg : const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? style.dotColor : Colors.transparent,
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
                            periodLabel(p),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              color: selected ? style.dotColor : const Color(0xFF2A2A2A),
                            ),
                          ),
                        ],
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

  const _PeriodStyle({
    required this.dotColor,
    required this.selectedBg,
  });
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