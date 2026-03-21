import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/location/location_history_presenter.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_network_gap_sheet.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_shared_widgets.dart';

class ChildDetailMapPointSheet extends StatelessWidget {
  final LocationData point;
  final List<LocationData> history;
  final bool isToday;
  final VoidCallback? onClose;

  const ChildDetailMapPointSheet({
    super.key,
    required this.point,
    required this.history,
    required this.isToday,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (point.isNetworkGap) {
      return ChildDetailMapNetworkGapSheet(point: point, onClose: onClose);
    }

    final orderedHistory = history.length < 2
        ? history
        : ([...history]..sort((a, b) => a.timestamp.compareTo(b.timestamp)));

    final stopDuration = LocationHistoryPresenter.computeStopDuration(
      orderedHistory,
      point,
    );
    final summary = LocationHistoryPresenter.buildPointSummary(
      l10n: l10n,
      history: orderedHistory,
      point: point,
      stopDuration: stopDuration,
      isToday: isToday,
    );

    final gpsLost = point.accuracy > 30;
    final gpsVeryBad = point.accuracy > 80;
    final pointIndex = orderedHistory.indexWhere(
      (entry) => entry.timestamp == point.timestamp,
    );
    final effectiveTransport = LocationHistoryPresenter.resolveEffectiveTransport(
      orderedHistory,
      point,
      indexHint: pointIndex,
    );
    final baseColor = LocationHistoryPresenter.transportColor(effectiveTransport);
    final displayColor = gpsLost ? const Color(0xFFC5221F) : baseColor;
    final isStart =
        orderedHistory.isNotEmpty &&
        point.timestamp == orderedHistory.first.timestamp;
    final isEnd =
        orderedHistory.isNotEmpty &&
        point.timestamp == orderedHistory.last.timestamp;
    final isLatestPoint =
        orderedHistory.isNotEmpty &&
        point.timestamp == orderedHistory.last.timestamp;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: gpsLost
                      ? const Color(0xFFFDE2E1)
                      : displayColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  gpsLost
                      ? Icons.gps_off_rounded
                      : LocationHistoryPresenter.transportIcon(
                          effectiveTransport,
                        ),
                  color: displayColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday && isLatestPoint
                          ? l10n.childLocationLiveLabel
                          : l10n.childLocationSelectedHistoryLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: isToday && isLatestPoint
                            ? const Color(0xFF188038)
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: gpsLost
                            ? const Color(0xFFC5221F)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
              children: [
                if (isStart)
                  ChildDetailMapTagChip(
                    text: l10n.childLocationTagStart,
                    backgroundColor: Color(0xFFDDF5E3),
                    foregroundColor: Color(0xFF188038),
                  ),
                if (isEnd)
                  ChildDetailMapTagChip(
                    text: l10n.childLocationTagEnd,
                    backgroundColor: Color(0xFFFDE2E1),
                    foregroundColor: Color(0xFFC5221F),
                  ),
              ChildDetailMapTagChip(
                text: point.timeLabel,
                backgroundColor: const Color(0xFFF1F3F4),
                foregroundColor: const Color(0xFF5F6368),
                ),
                if (gpsVeryBad)
                  ChildDetailMapTagChip(
                    text: l10n.childLocationTagGpsVeryWeak,
                    backgroundColor: Color(0xFFFCE8E6),
                    foregroundColor: Color(0xFFC5221F),
                  )
                else if (gpsLost)
                  ChildDetailMapTagChip(
                    text: l10n.childLocationTagGpsLost,
                    backgroundColor: Color(0xFFFCE8E6),
                    foregroundColor: Color(0xFFC5221F),
                )
              else
                ChildDetailMapTagChip(
                  text: LocationHistoryPresenter.transportLabel(
                    l10n,
                    effectiveTransport,
                  ),
                  backgroundColor: displayColor.withOpacity(0.12),
                  foregroundColor: displayColor,
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ChildDetailMapInfoCard(
                  label: l10n.childLocationStayedHereLabel,
                  value: gpsLost
                      ? l10n.childLocationStayedHereUnavailable
                      : LocationHistoryPresenter.formatDuration(l10n, stopDuration),
                  hint: l10n.childLocationStopDurationHint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChildDetailMapInfoCard(
                  label: l10n.childLocationSpeedLabel,
                  value: gpsLost
                      ? l10n.childLocationSpeedUnavailable
                      : LocationHistoryPresenter.speedLabel(
                          l10n,
                          orderedHistory,
                          point,
                        ),
                  hint: LocationHistoryPresenter.transportLabel(
                    l10n,
                    effectiveTransport,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChildDetailMapInfoCard(
                  label: l10n.childLocationGpsAccuracyLabel,
                  value: LocationHistoryPresenter.accuracyLabel(l10n, point),
                  hint: '${point.accuracy.toStringAsFixed(0)} m',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChildDetailMapInfoCard(
                  label: l10n.childLocationMockGpsLabel,
                  value: point.isMock
                      ? l10n.childLocationMockGpsDetected
                      : l10n.childLocationNoLabel,
                  hint: l10n.childLocationDeviceStatusHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ChildDetailMapTechSection(point: point),
        ],
      ),
    );
  }
}
