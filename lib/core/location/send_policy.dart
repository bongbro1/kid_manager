import 'package:kid_manager/core/location/tracking_state.dart';

class SendPolicy {
  bool shouldSend({
    required MotionState motion,
    required double distanceKm,
    required Duration sinceLast,
    required bool isNight,
  }) {
    if (isNight) {
      return distanceKm >= 0.1;
    }

    switch (motion) {
      case MotionState.moving:
        if (distanceKm >= 0.008) return true;
        if (sinceLast >= const Duration(seconds: 5)) return true;
        return false;

      case MotionState.idle:
        return distanceKm >= 0.015;

      case MotionState.stationary:
        return false;
    }
  }
}
