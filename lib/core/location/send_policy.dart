import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/core/location/tracking_tuning.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class SendPolicy {
  bool shouldSend({
    required MotionState motion,
    required double distanceKm,
    required Duration sinceLast,
    required bool isNight,
    required double accuracyM,
    required bool indoorSuppressed,
    required TransportMode transport,
    double? turnDeg,
  }) {
    if (indoorSuppressed) {
      return false;
    }

    // Prefer sending on meaningful turns when GPS quality is still usable.
    if (turnDeg != null &&
        turnDeg >= TrackingTuning.turnSendThresholdDeg &&
        accuracyM <= TrackingTuning.moderateAccuracyMaxM) {
      return true;
    }

    // Very weak GPS: only keep alive sparsely to avoid visible jumping.
    if (accuracyM >= TrackingTuning.weakGpsKeepAliveAccuracyM) {
      return sinceLast >= TrackingTuning.weakGpsKeepAliveInterval;
    }
    if (accuracyM >= TrackingTuning.moderateGpsKeepAliveAccuracyM) {
      return sinceLast >= TrackingTuning.moderateGpsKeepAliveInterval;
    }

    if (isNight) {
      if (sinceLast >= TrackingTuning.nightKeepAliveInterval) {
        return true;
      }
      return distanceKm >= TrackingTuning.nightMovingDistanceKm;
    }

    Duration movingMinInterval;
    double movingMinDistanceKm;

    switch (transport) {
      case TransportMode.walking:
        movingMinInterval = TrackingTuning.walkingMovingInterval;
        movingMinDistanceKm = TrackingTuning.walkingMovingDistanceKm;
        break;
      case TransportMode.bicycle:
        movingMinInterval = TrackingTuning.bicycleMovingInterval;
        movingMinDistanceKm = TrackingTuning.bicycleMovingDistanceKm;
        break;
      case TransportMode.vehicle:
        movingMinInterval = TrackingTuning.vehicleMovingInterval;
        movingMinDistanceKm = TrackingTuning.vehicleMovingDistanceKm;
        break;
      case TransportMode.still:
      case TransportMode.unknown:
        movingMinInterval = TrackingTuning.unknownMovingInterval;
        movingMinDistanceKm = TrackingTuning.unknownMovingDistanceKm;
        break;
    }

    if (transport == TransportMode.still || transport == TransportMode.unknown) {
      if (accuracyM >= TrackingTuning.stillUnknownWeakAccuracyMinM) {
        movingMinInterval = TrackingTuning.stillUnknownWeakInterval;
        movingMinDistanceKm = TrackingTuning.stillUnknownWeakDistanceKm;
      } else if (movingMinDistanceKm < TrackingTuning.stillUnknownTightDistanceKm) {
        movingMinDistanceKm = TrackingTuning.stillUnknownTightDistanceKm;
      }
    }

    switch (motion) {
      case MotionState.moving:
        if (distanceKm >= movingMinDistanceKm) {
          return true;
        }
        return sinceLast >= movingMinInterval;
      case MotionState.idle:
        if (distanceKm >= TrackingTuning.idleHistoryDistanceKm) {
          return true;
        }
        return sinceLast >= TrackingTuning.idleHistoryKeepAliveInterval;
      case MotionState.stationary:
        return sinceLast >= TrackingTuning.stationaryHistoryKeepAliveInterval;
    }
  }
}
