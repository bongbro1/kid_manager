import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/core/location/tracking_tuning.dart';

class MotionDetector {
  MotionState detect(
    MotionState current,
    double distanceKm,
    DateTime now,
    DateTime? lastMoveAt, {
    required double speedMps,
    required double accuracyM,
  }) {
    final baseMovementThresholdKm = accuracyM <= TrackingTuning.goodAccuracyMaxM
        ? TrackingTuning.motionBaseMovementThresholdGoodKm
        : accuracyM <= TrackingTuning.moderateAccuracyMaxM
        ? TrackingTuning.motionBaseMovementThresholdModerateKm
        : accuracyM <= TrackingTuning.weakAccuracyMaxM
        ? TrackingTuning.motionBaseMovementThresholdWeakKm
        : TrackingTuning.motionBaseMovementThresholdFallbackKm;

    final movementThresholdKm = switch (current) {
      MotionState.moving => baseMovementThresholdKm,
      MotionState.idle =>
        baseMovementThresholdKm * TrackingTuning.motionIdleDistanceMultiplier,
      MotionState.stationary =>
        baseMovementThresholdKm *
            TrackingTuning.motionStationaryDistanceMultiplier,
    };

    final movingSpeedThresholdMps = switch (current) {
      MotionState.moving => TrackingTuning.motionMovingSpeedThresholdMovingMps,
      MotionState.idle =>
        accuracyM <= TrackingTuning.goodAccuracyMaxM
            ? TrackingTuning.motionMovingSpeedThresholdIdleGoodMps
            : TrackingTuning.motionMovingSpeedThresholdIdleWeakMps,
      MotionState.stationary =>
        accuracyM <= TrackingTuning.goodAccuracyMaxM
            ? TrackingTuning.motionMovingSpeedThresholdStationaryGoodMps
            : TrackingTuning.motionMovingSpeedThresholdStationaryWeakMps,
    };

    if (distanceKm >= movementThresholdKm ||
        speedMps >= movingSpeedThresholdMps) {
      return MotionState.moving;
    }

    if (lastMoveAt == null) {
      return current == MotionState.stationary
          ? MotionState.stationary
          : MotionState.idle;
    }

    final idleFor = now.difference(lastMoveAt);

    if (idleFor >= TrackingTuning.motionStationaryDelay) {
      return MotionState.stationary;
    }

    if (idleFor >= TrackingTuning.motionIdleDelay) {
      return MotionState.idle;
    }

    return MotionState.idle;
  }
}
