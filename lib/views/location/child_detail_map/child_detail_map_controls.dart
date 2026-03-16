import 'package:flutter/material.dart';

class ChildDetailMapAppBarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ChildDetailMapAppBarChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChildDetailMapFab extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const ChildDetailMapFab({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? primary : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class ChildDetailTimeWindowSelection {
  final int startMinute;
  final int endMinute;

  const ChildDetailTimeWindowSelection({
    required this.startMinute,
    required this.endMinute,
  });
}

Future<ChildDetailTimeWindowSelection?> showChildDetailTimeWindowSheet({
  required BuildContext context,
  required int initialStartMinute,
  required int initialEndMinute,
  required String Function(int minuteOfDay) minuteLabel,
}) {
  return showModalBottomSheet<ChildDetailTimeWindowSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      var draftStart = initialStartMinute.toDouble();
      var draftEnd = initialEndMinute.toDouble();

      void applyPreset(StateSetter setSheetState, int start, int end) {
        setSheetState(() {
          draftStart = start.toDouble();
          draftEnd = end.toDouble();
        });
      }

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final startLabel = minuteLabel(draftStart.round());
          final endLabel = minuteLabel(draftEnd.round());

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chọn khung giờ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chỉ tải và hiển thị lịch sử trong khoảng giờ đang chọn.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RangePresetChip(
                        label: 'Cả ngày',
                        selected:
                            draftStart.round() == 0 &&
                            draftEnd.round() == (24 * 60) - 1,
                        onTap: () =>
                            applyPreset(setSheetState, 0, (24 * 60) - 1),
                      ),
                      _RangePresetChip(
                        label: 'Sáng',
                        selected:
                            draftStart.round() == 6 * 60 &&
                            draftEnd.round() == (11 * 60) + 59,
                        onTap: () =>
                            applyPreset(setSheetState, 6 * 60, (11 * 60) + 59),
                      ),
                      _RangePresetChip(
                        label: 'Chiều',
                        selected:
                            draftStart.round() == 12 * 60 &&
                            draftEnd.round() == (17 * 60) + 59,
                        onTap: () =>
                            applyPreset(setSheetState, 12 * 60, (17 * 60) + 59),
                      ),
                      _RangePresetChip(
                        label: 'Tối',
                        selected:
                            draftStart.round() == 18 * 60 &&
                            draftEnd.round() == (23 * 60) + 59,
                        onTap: () =>
                            applyPreset(setSheetState, 18 * 60, (23 * 60) + 59),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE8EAED)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryChip(
                            label: 'Bắt đầu',
                            value: startLabel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryChip(
                            label: 'Kết thúc',
                            value: endLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: RangeValues(draftStart, draftEnd),
                    min: 0,
                    max: ((24 * 60) - 1).toDouble(),
                    divisions: (24 * 4) - 1,
                    labels: RangeLabels(startLabel, endLabel),
                    onChanged: (values) {
                      setSheetState(() {
                        draftStart = values.start.roundToDouble();
                        draftEnd = values.end.roundToDouble();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Hủy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(
                            ChildDetailTimeWindowSelection(
                              startMinute: draftStart.round(),
                              endMinute: draftEnd.round(),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _RangePresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangePresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.14) : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE0E3E7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
