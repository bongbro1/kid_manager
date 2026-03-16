import 'package:kid_manager/models/location/location_data.dart';

class LocationStopSummary {
  final int count;
  final Duration totalDuration;
  final Duration longestDuration;

  const LocationStopSummary({
    required this.count,
    required this.totalDuration,
    required this.longestDuration,
  });
}

class LocationTripSummary {
  final int count;
  final double totalDistanceKm;
  final Duration activeDuration;

  const LocationTripSummary({
    required this.count,
    required this.totalDistanceKm,
    required this.activeDuration,
  });
}

class LocationHistorySummary {
  final LocationStopSummary stops;
  final LocationTripSummary trips;
  final int pointCount;
  final Duration span;

  const LocationHistorySummary({
    required this.stops,
    required this.trips,
    required this.pointCount,
    required this.span,
  });

  factory LocationHistorySummary.empty() {
    return const LocationHistorySummary(
      stops: LocationStopSummary(
        count: 0,
        totalDuration: Duration.zero,
        longestDuration: Duration.zero,
      ),
      trips: LocationTripSummary(
        count: 0,
        totalDistanceKm: 0,
        activeDuration: Duration.zero,
      ),
      pointCount: 0,
      span: Duration.zero,
    );
  }
}

class LocationHistoryAnalyzer {
  static const double _stopRadiusMeters = 35;
  static const double _stationarySpeedThresholdKmh = 3;
  static const int _minStopDurationMs = 3 * 60 * 1000;
  static const double _minTripDistanceKm = 0.05;
  static const int _minTripDurationMs = 2 * 60 * 1000;

  static LocationHistorySummary summarize(List<LocationData> points) {
    if (points.length < 2) {
      return LocationHistorySummary.empty();
    }

    final sorted = [...points]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final stopRanges = _detectStopRanges(sorted);

    var totalDistanceKm = 0.0;
    for (var i = 1; i < sorted.length; i++) {
      totalDistanceKm += sorted[i - 1].distanceTo(sorted[i]);
    }

    var stopTotal = Duration.zero;
    var stopLongest = Duration.zero;
    for (final stop in stopRanges) {
      stopTotal += stop.duration;
      if (stop.duration > stopLongest) {
        stopLongest = stop.duration;
      }
    }

    final tripCount = _countTrips(sorted, stopRanges);
    final spanMs = sorted.last.timestamp - sorted.first.timestamp;

    final safeSpanMs = spanMs < 0 ? 0 : spanMs;

    return LocationHistorySummary(
      stops: LocationStopSummary(
        count: stopRanges.length,
        totalDuration: stopTotal,
        longestDuration: stopLongest,
      ),
      trips: LocationTripSummary(
        count: tripCount,
        totalDistanceKm: totalDistanceKm,
        activeDuration: Duration(milliseconds: safeSpanMs),
      ),
      pointCount: sorted.length,
      span: Duration(milliseconds: safeSpanMs),
    );
  }

  static List<_StopRange> _detectStopRanges(List<LocationData> sorted) {
    final stops = <_StopRange>[];
    var index = 0;

    while (index < sorted.length - 1) {
      final anchor = sorted[index];
      if (anchor.speedKmh > _stationarySpeedThresholdKmh) {
        index++;
        continue;
      }

      var end = index;
      while (end + 1 < sorted.length) {
        final next = sorted[end + 1];
        final distMeters = anchor.distanceTo(next) * 1000;
        if (distMeters > _stopRadiusMeters ||
            next.speedKmh > _stationarySpeedThresholdKmh) {
          break;
        }
        end++;
      }

      final durationMs = sorted[end].timestamp - anchor.timestamp;
      if (durationMs >= _minStopDurationMs) {
        stops.add(
          _StopRange(
            startIndex: index,
            endIndex: end,
            duration: Duration(milliseconds: durationMs),
          ),
        );
        index = end + 1;
        continue;
      }

      index++;
    }

    return stops;
  }

  static int _countTrips(List<LocationData> sorted, List<_StopRange> stops) {
    if (sorted.length < 2) return 0;

    var tripCount = 0;
    var cursor = 0;

    void maybeAddTrip(int startIndex, int endIndex) {
      if (endIndex - startIndex < 1) return;

      var distanceKm = 0.0;
      for (var i = startIndex + 1; i <= endIndex; i++) {
        distanceKm += sorted[i - 1].distanceTo(sorted[i]);
      }

      final durationMs =
          sorted[endIndex].timestamp - sorted[startIndex].timestamp;
      if (distanceKm >= _minTripDistanceKm || durationMs >= _minTripDurationMs) {
        tripCount++;
      }
    }

    for (final stop in stops) {
      maybeAddTrip(cursor, stop.startIndex - 1);
      cursor = stop.endIndex + 1;
    }

    maybeAddTrip(cursor, sorted.length - 1);
    return tripCount;
  }
}

class _StopRange {
  final int startIndex;
  final int endIndex;
  final Duration duration;

  const _StopRange({
    required this.startIndex,
    required this.endIndex,
    required this.duration,
  });
}
