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
    final baseMovementThresholdKm = accuracyM <= 15
        ? 0.006
        : accuracyM <= 30
        ? 0.008
        : accuracyM <= 50
        ? 0.012
        : 0.015;

    final movementThresholdKm = switch (current) {
      MotionState.moving => baseMovementThresholdKm,
      MotionState.idle => baseMovementThresholdKm * 1.35,
      MotionState.stationary => baseMovementThresholdKm * 1.8,
    };

    final movingSpeedThresholdMps = switch (current) {
      MotionState.moving => 0.8,
      MotionState.idle => accuracyM <= 20 ? 1.0 : 1.2,
      MotionState.stationary => accuracyM <= 20 ? 1.25 : 1.5,
    };

    if (distanceKm >= movementThresholdKm || speedMps >= movingSpeedThresholdMps) {
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
