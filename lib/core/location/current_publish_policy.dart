import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/core/location/tracking_tuning.dart';

Duration? currentPublishInterval({
  required MotionState motion,
  required double accuracy,
  required bool shouldSendInitialCurrent,
  required bool indoorSuppressed,
}) {
  if (accuracy > TrackingTuning.currentRejectAccuracyMaxM) {
    return null;
  }

  if (shouldSendInitialCurrent) {
    return Duration.zero;
  }

  if (indoorSuppressed) {
    if (accuracy <= TrackingTuning.suppressedCurrentKeepAliveAcc20MaxM) {
      return TrackingTuning.suppressedCurrentKeepAliveAcc20;
    }
    if (accuracy <= TrackingTuning.suppressedCurrentKeepAliveAcc35MaxM) {
      return TrackingTuning.suppressedCurrentKeepAliveAcc35;
    }
    return TrackingTuning.suppressedCurrentKeepAliveFallback;
  }

  switch (motion) {
    case MotionState.moving:
      if (accuracy <= TrackingTuning.currentGoodAccuracyMaxM) {
        return TrackingTuning.currentMovingGoodInterval;
      }
      if (accuracy <= TrackingTuning.currentModerateAccuracyMaxM) {
        return TrackingTuning.currentMovingModerateInterval;
      }
      return TrackingTuning.currentMovingWeakInterval;
    case MotionState.idle:
      if (accuracy <= TrackingTuning.currentGoodAccuracyMaxM) {
        return TrackingTuning.currentIdleGoodInterval;
      }
      if (accuracy <= TrackingTuning.currentModerateAccuracyMaxM) {
        return TrackingTuning.currentIdleModerateInterval;
      }
      return TrackingTuning.currentIdleWeakInterval;
    case MotionState.stationary:
      if (accuracy <= TrackingTuning.currentGoodAccuracyMaxM) {
        return TrackingTuning.currentStationaryGoodInterval;
      }
      if (accuracy <= TrackingTuning.currentModerateAccuracyMaxM) {
        return TrackingTuning.currentStationaryModerateInterval;
      }
      return TrackingTuning.currentStationaryWeakInterval;
  }
}
