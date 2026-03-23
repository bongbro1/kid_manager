import 'package:kid_manager/core/location/tracking_state.dart';

class MotionDetector {
  static const Duration _idleDelay = Duration(seconds: 45);
  static const Duration _stationaryDelay = Duration(minutes: 3);

  MotionState detect(
    MotionState current,
    double distanceKm,
    DateTime now,
    DateTime? lastMoveAt, {
    required double speedMps,
    required double accuracyM,
  }) {
    final movementThresholdKm = accuracyM <= 15
        ? 0.006
        : accuracyM <= 30
        ? 0.008
        : accuracyM <= 50
        ? 0.012
        : 0.015;

    if (distanceKm >= movementThresholdKm || speedMps >= 0.8) {
      return MotionState.moving;
    }

    if (lastMoveAt == null) {
      return current == MotionState.stationary
          ? MotionState.stationary
          : MotionState.idle;
    }

    final idleFor = now.difference(lastMoveAt);

    if (idleFor >= _stationaryDelay) {
      return MotionState.stationary;
    }

    if (idleFor >= _idleDelay) {
      return MotionState.idle;
    }

    return MotionState.idle;
  }
}
