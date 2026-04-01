import 'dart:math';

import 'package:kid_manager/models/location/location_data.dart';

class EffectiveSpeedEstimator {
  static const double _rawReliableThresholdMps = 0.35;
  static const double _minDeriveSeconds = 2.0;
  static const double _maxDeriveSeconds = 180.0;
  static const double _maxAccuracyForDerive = 50.0;
  static const double _minAccuracyForNoiseEnvelope = 8.0;
  static const double _noiseEnvelopeFactor = 1.25;
  static const double _minDerivedDistanceMeters = 3.0;
  static const double _maxReasonableDerivedMps = 45.0;

  static LocationData resolveIncomingLocation(
    LocationData point, {
    LocationData? previous,
  }) {
    final resolvedSpeed = resolvePointSpeedMps(point, previous: previous);
    if ((resolvedSpeed - point.speed).abs() < 0.01) {
      return point;
    }
    return point.copyWith(speed: resolvedSpeed);
  }

  static double resolvePointSpeedMps(
    LocationData point, {
    LocationData? previous,
    LocationData? next,
  }) {
    if (_isRawReliable(point.speed)) {
      return point.speed;
    }

    final candidates = <double>[];

    final prevDerived = previous == null
        ? null
        : _deriveSegmentSpeedMps(previous, point);
    if (prevDerived != null) {
      candidates.add(prevDerived);
    }

    final nextDerived = next == null ? null : _deriveSegmentSpeedMps(point, next);
    if (nextDerived != null) {
      candidates.add(nextDerived);
    }

    if (candidates.isEmpty) {
      return point.speed > 0 ? point.speed : 0;
    }

    candidates.sort();
    return candidates[candidates.length ~/ 2];
  }

  static double resolveHistorySpeedKmh(List<LocationData> history, int index) {
    return resolveHistorySpeedMps(history, index) * 3.6;
  }

  static double resolveHistorySpeedMps(List<LocationData> history, int index) {
    if (index < 0 || index >= history.length) {
      return 0;
    }

    final current = history[index];
    final previous = index > 0 ? history[index - 1] : null;
    final next = index + 1 < history.length ? history[index + 1] : null;

    return resolvePointSpeedMps(
      current,
      previous: previous,
      next: next,
    );
  }

  static bool _isRawReliable(double speedMps) {
    return speedMps.isFinite && speedMps > _rawReliableThresholdMps;
  }

  static double? _deriveSegmentSpeedMps(LocationData from, LocationData to) {
    final dtMs = (to.timestamp - from.timestamp).abs();
    if (dtMs <= 0) return null;

    final dtSec = dtMs / 1000.0;
    if (dtSec < _minDeriveSeconds || dtSec > _maxDeriveSeconds) {
      return null;
    }

    final worstAccuracy = max(from.accuracy, to.accuracy);
    if (worstAccuracy > _maxAccuracyForDerive) {
      return null;
    }

    final distanceMeters = from.distanceTo(to) * 1000.0;
    if (!distanceMeters.isFinite) return null;

    // Indoor/school jitter often creates a fake segment whose displacement is
    // still inside the combined accuracy envelope. Treat it as stationary
    // instead of converting it into a derived walking speed.
    if (worstAccuracy >= _minAccuracyForNoiseEnvelope &&
        distanceMeters <= worstAccuracy * _noiseEnvelopeFactor) {
      return 0.0;
    }

    if (distanceMeters < _minDerivedDistanceMeters) {
      return 0.0;
    }

    final derived = distanceMeters / dtSec;
    if (!derived.isFinite || derived > _maxReasonableDerivedMps) {
      return null;
    }

    return derived;
  }
}
