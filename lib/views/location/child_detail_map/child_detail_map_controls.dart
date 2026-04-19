import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// App bar chip  ← THIẾT KẾ BẢN 1
// Nền trắng nhẹ (#F6F8FA), bo 14, viền mỏng #E3E7EB, icon + text đen
// ─────────────────────────────────────────────────────────────────────────────

class ChildDetailMapAppBarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  const ChildDetailMapAppBarChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted
              ? locationPanelHighlightColor(scheme)
              : locationPanelMutedColor(scheme),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted
                ? scheme.primary.withOpacity(0.45)
                : locationPanelBorderColor(scheme),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlighted ? scheme.primary : scheme.onSurface,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: Theme.of(
                    context,
                  ).appTypography.supporting.fontSize!,
                  color: highlighted ? scheme.primary : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB (Floating Action Button)  ← THIẾT KẾ BẢN 1
// Inactive: nền trắng, viền #E5E7EB
// Active  : nền primary 14% opacity, viền primary 35% opacity
// ─────────────────────────────────────────────────────────────────────────────

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
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active
                ? primary.withOpacity(0.14)
                : locationPanelColor(scheme).withOpacity(0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? primary.withOpacity(0.35)
                  : locationPanelBorderColor(scheme),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 21,
            color: active ? primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Time-window selection model
// ─────────────────────────────────────────────────────────────────────────────

class ChildDetailTimeWindowSelection {
  final int startMinute;
  final int endMinute;

  const ChildDetailTimeWindowSelection({
    required this.startMinute,
    required this.endMinute,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Time-window bottom sheet  ← THIẾT KẾ BẢN 1
// ─────────────────────────────────────────────────────────────────────────────

Future<ChildDetailTimeWindowSelection?> showChildDetailTimeWindowSheet({
  required BuildContext context,
  required int initialStartMinute,
  required int initialEndMinute,
  required String Function(int minuteOfDay) minuteLabel,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<ChildDetailTimeWindowSelection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: locationPanelColor(scheme),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
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
                  // ── Title ──────────────────────────────────────────────
                  Text(
                    l10n.childLocationTimeWindowTitle,
                    style: TextStyle(
                      fontSize: Theme.of(
                        context,
                      ).appTypography.screenTitle.fontSize!,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.childLocationTimeWindowSubtitle,
                    style: TextStyle(
                      fontSize: Theme.of(
                        context,
                      ).appTypography.sectionLabel.fontSize!,
                      height: 1.35,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Preset chips ────────────────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RangePresetChip(
                        label: l10n.childLocationRangeAllDay,
                        selected:
                            draftStart.round() == 0 &&
                            draftEnd.round() == (24 * 60) - 1,
                        onTap: () =>
                            applyPreset(setSheetState, 0, (24 * 60) - 1),
                      ),
                      _RangePresetChip(
                        label: l10n.childLocationPresetMorning,
                        selected:
                            draftStart.round() == 6 * 60 &&
                            draftEnd.round() == (11 * 60) + 59,
                        onTap: () =>
                            applyPreset(setSheetState, 6 * 60, (11 * 60) + 59),
                      ),
                      _RangePresetChip(
                        label: l10n.childLocationPresetAfternoon,
                        selected:
                            draftStart.round() == 12 * 60 &&
                            draftEnd.round() == (17 * 60) + 59,
                        onTap: () =>
                            applyPreset(setSheetState, 12 * 60, (17 * 60) + 59),
                      ),
                      _RangePresetChip(
                        label: l10n.childLocationPresetEvening,
                        selected:
                            draftStart.round() == 18 * 60 &&
                            draftEnd.round() == (23 * 60) + 59,
                        onTap: () =>
                            applyPreset(setSheetState, 18 * 60, (23 * 60) + 59),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ── Summary display ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: locationPanelMutedColor(scheme),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: locationPanelBorderColor(scheme),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ChildDetailMapSummaryChip(
                            backgroundColor: locationPanelColor(scheme),
                            label: l10n.childLocationTagStart,
                            value: startLabel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChildDetailMapSummaryChip(
                            backgroundColor: locationPanelColor(scheme),
                            label: l10n.childLocationTagEnd,
                            value: endLabel,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Range slider ────────────────────────────────────────
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

                  // ── Action buttons ──────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(l10n.cancelButton),
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
                          child: Text(l10n.confirmButton),
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

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? primary.withOpacity(0.14)
              : locationPanelMutedColor(scheme),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primary : locationPanelBorderColor(scheme),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Theme.of(context).appTypography.supporting.fontSize!,
            fontWeight: FontWeight.w700,
            color: selected ? primary : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
