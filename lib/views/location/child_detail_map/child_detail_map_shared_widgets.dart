import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/child_detail_map_vm.dart';

class ChildDetailMapStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final Color bg;
  final Color fg;
  final IconData icon;

  const ChildDetailMapStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fg.withOpacity(0.9),
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

class ChildDetailMapInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const ChildDetailMapInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            hint,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ChildDetailMapTechSection extends StatefulWidget {
  final ChildDetailMapVm vm;
  final LocationData point;

  const ChildDetailMapTechSection({
    super.key,
    required this.vm,
    required this.point,
  });

  @override
  State<ChildDetailMapTechSection> createState() =>
      _ChildDetailMapTechSectionState();
}

class _ChildDetailMapTechSectionState extends State<ChildDetailMapTechSection> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 17,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.childLocationTechnicalDetailsTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  ChildDetailMapDetailRow(
                    label: l10n.childLocationDetailFullTimeLabel,
                    value: widget.vm.formatFullLabelForTimestamp(
                      widget.point.timestamp,
                    ),
                  ),
                  ChildDetailMapDetailRow(
                    label: l10n.childLocationDetailHeadingLabel,
                    value: '${widget.point.heading.toStringAsFixed(0)}°',
                  ),
                  ChildDetailMapDetailRow(
                    label: l10n.childLocationDetailCoordinatesLabel,
                    value:
                        '${widget.point.latitude.toStringAsFixed(6)}, ${widget.point.longitude.toStringAsFixed(6)}',
                  ),
                  ChildDetailMapDetailRow(
                    label: l10n.childLocationDetailAccuracyLabel,
                    value: '${widget.point.accuracy.toStringAsFixed(0)} m',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChildDetailMapSummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;

  const ChildDetailMapSummaryChip({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor = const Color(0xFFF8F9FA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
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

class ChildDetailMapTagChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const ChildDetailMapTagChip({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ChildDetailMapDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const ChildDetailMapDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
