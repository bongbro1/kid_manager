import 'package:kid_manager/core/location/tracking_state.dart';

class MotionDetector {
  static const double moveThresholdKm = 0.008;

  MotionState detect(
      MotionState current,
      double distanceKm,
      DateTime now,
      DateTime? lastMoveAt,
      ) {
    if (distanceKm >= moveThresholdKm) {
      return MotionState.moving;
    }

    if (lastMoveAt == null) return current;

    final idleFor = now.difference(lastMoveAt);

    if (idleFor >= const Duration(minutes: 5)) {
      return MotionState.stationary;
    }

    if (idleFor >= const Duration(minutes: 1)) {
      return MotionState.idle;
    }

    return current;
  }
}
