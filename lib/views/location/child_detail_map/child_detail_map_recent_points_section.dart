import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/location/location_history_presenter.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/child_detail_map_vm.dart';

class ChildDetailMapRecentPointsHourSection extends StatelessWidget {
  final ChildDetailMapRecentHourGroup group;
  final List<LocationData> history;
  final Future<void> Function(LocationData point) onPointSelected;

  const ChildDetailMapRecentPointsHourSection({
    super.key,
    required this.group,
    required this.history,
    required this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              group.label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          ...group.points.map(
            (point) => ChildDetailMapRecentPointRow(
              point: point,
              history: history,
              onTap: () => onPointSelected(point),
            ),
          ),
        ],
      ),
    );
  }
}

class ChildDetailMapRecentPointRow extends StatelessWidget {
  final LocationData point;
  final List<LocationData> history;
  final VoidCallback onTap;

  const ChildDetailMapRecentPointRow({
    super.key,
    required this.point,
    required this.history,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pointIndex = history.indexWhere(
      (entry) => entry.timestamp == point.timestamp,
    );
    final effectiveTransport = LocationHistoryPresenter.resolveEffectiveTransport(
      history,
      point,
      indexHint: pointIndex,
    );
    final color = point.accuracy > 30
        ? const Color(0xFFC5221F)
        : LocationHistoryPresenter.transportColor(effectiveTransport);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  point.accuracy > 30
                      ? Icons.gps_off_rounded
                      : LocationHistoryPresenter.transportIcon(
                          effectiveTransport,
                        ),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.accuracy > 30
                          ? 'Tín hiệu GPS yếu'
                          : LocationHistoryPresenter.transportLabel(
                              effectiveTransport,
                            ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bấm để xem chi tiết',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                point.timeLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
