import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class HistoryGap {
  final LocationData start;
  final LocationData end;
  final LocationData marker;

  const HistoryGap({
    required this.start,
    required this.end,
    required this.marker,
  });
}

class HistoryGapDetector {
  static const Duration defaultMinGap = Duration(minutes: 5);
  static const double defaultMinDistanceMeters = 80;

  List<HistoryGap> detect(
    List<LocationData> history, {
    Duration minGap = defaultMinGap,
    double minDistanceMeters = defaultMinDistanceMeters,
  }) {
    if (history.length < 2) return const [];

    final sorted = [...history]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final gaps = <HistoryGap>[];

    for (var index = 1; index < sorted.length; index++) {
      final previous = sorted[index - 1];
      final current = sorted[index];
      final gapMs = current.timestamp - previous.timestamp;

      if (gapMs < minGap.inMilliseconds) {
        continue;
      }

      final distanceMeters = previous.distanceTo(current) * 1000;
      if (distanceMeters < minDistanceMeters) {
        continue;
      }

      final markerTimestamp = previous.timestamp + (gapMs ~/ 2);
      final marker = LocationData(
        latitude: (previous.latitude + current.latitude) / 2,
        longitude: (previous.longitude + current.longitude) / 2,
        accuracy: previous.accuracy > current.accuracy
            ? previous.accuracy
            : current.accuracy,
        timestamp: markerTimestamp,
        transport: TransportMode.unknown,
        isNetworkGap: true,
        gapDurationMs: gapMs,
        gapStartTimestamp: previous.timestamp,
        gapEndTimestamp: current.timestamp,
      );

      gaps.add(HistoryGap(start: previous, end: current, marker: marker));
    }

    return gaps;
  }
}
