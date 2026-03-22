import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/location/location_history_presenter.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/child_detail_map_vm.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_recent_points_section.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_shared_widgets.dart';

class ChildDetailMapOverviewSheet extends StatelessWidget {
  final ChildDetailMapVm vm;
  final LocationData latest;
  final Future<void> Function(LocationData point) onPointSelected;

  const ChildDetailMapOverviewSheet({
    super.key,
    required this.vm,
    required this.latest,
    required this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final orderedHistory = vm.orderedHistory;
    final groupedPoints = vm.visibleRecentHourGroups;
    final latestIndex = orderedHistory.indexWhere(
      (entry) => entry.timestamp == latest.timestamp,
    );
    final effectiveLatestTransport = LocationHistoryPresenter.resolveEffectiveTransport(
      orderedHistory,
      latest,
      indexHint: latestIndex,
    );
    final transportColor = LocationHistoryPresenter.transportColor(
      effectiveLatestTransport,
    );
    final transportLabel = LocationHistoryPresenter.transportLabel(
      l10n,
      effectiveLatestTransport,
    );
    final latestSpeedKmh = latestIndex == -1
        ? latest.speedKmh
        : LocationHistoryPresenter.resolveEffectiveSpeedKmh(
            orderedHistory,
            latestIndex,
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: vm.isToday ? const Color(0xFF34A853) : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (vm.isToday
                              ? const Color(0xFF34A853)
                              : Colors.grey)
                          .withOpacity(0.22),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.isToday
                      ? l10n.childLocationLiveLabel
                      : l10n.childLocationSelectedHistoryLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: vm.isToday
                        ? const Color(0xFF188038)
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: transportColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  transportLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: transportColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            vm.isToday
                ? l10n.childLocationCurrentJourneyTitle
                : l10n.childLocationTravelHistoryTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.childLocationUpdatedAt(latest.timeLabel),
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ChildDetailMapStatCard(
                  title: l10n.childLocationPointCountTitle,
                  value: '${vm.cachedHistory.length}',
                  unit: l10n.childLocationPointCountUnit,
                  bg: const Color(0xFFF3F8FF),
                  fg: const Color(0xFF1565C0),
                  icon: Icons.scatter_plot_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChildDetailMapStatCard(
                  title: l10n.childLocationGpsTitle,
                  value: latest.accuracy.toStringAsFixed(0),
                  unit: 'm',
                  bg: const Color(0xFFF1FBF4),
                  fg: const Color(0xFF188038),
                  icon: Icons.gps_fixed_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChildDetailMapStatCard(
                  title: l10n.childLocationSpeedLabel,
                  value: latestSpeedKmh.toStringAsFixed(1),
                  unit: 'km/h',
                  bg: const Color(0xFFFFF8F1),
                  fg: const Color(0xFFE65100),
                  icon: Icons.speed_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.childLocationRecentPointsTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                ...groupedPoints.map(
                  (group) => ChildDetailMapRecentPointsHourSection(
                    group: group,
                    history: orderedHistory,
                    onPointSelected: onPointSelected,
                  ),
                ),
                if (vm.hasMoreRecentHourGroups) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: vm.loadMoreRecentHourGroups,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            l10n.childLocationLoadMoreRecentHours(
                              vm.remainingRecentHourGroupsLabel,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: vm.showAllRecentHourGroups,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(l10n.childLocationViewAllButton),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
