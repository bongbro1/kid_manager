import 'package:kid_manager/core/location/kalman_filter.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/tracking_result.dart';

class TrackingPipeline {
  final MotionDetector motionDetector;
  final SendPolicy sendPolicy;

  TrackingState _state =
  const TrackingState(motion: MotionState.moving);

  Kalman2D? _kalman;

  TrackingPipeline({
    required this.motionDetector,
    required this.sendPolicy,
  });

  TrackingResult process(LocationData raw) {
    _kalman ??= Kalman2D(raw.latitude, raw.longitude);

    final filtered = _kalman!.filter(raw);
    final now = DateTime.now();

    final last = _state.lastSent;

    double distance = 0;
    if (last != null) {
      distance = last.distanceTo(filtered);
    }

    // 🚀 FIRST FIX → LUÔN GỬI
    if (last == null) {
      final newState = _state.copyWith(
        motion: MotionState.moving,
        lastSent: filtered,
        lastSentAt: now,
        lastMoveAt: now,
      );

      _state = newState;

      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: true,
        motion: MotionState.moving,
      );
    }

    final newMotion = motionDetector.detect(
      _state.motion,
      distance,
      now,
      _state.lastMoveAt,
    );

    final sinceLast = _state.lastSentAt == null
        ? const Duration(days: 1)
        : now.difference(_state.lastSentAt!);

    final shouldSend = sendPolicy.shouldSend(
      motion: newMotion,
      distanceKm: distance,
      sinceLast: sinceLast,
      isNight: now.hour >= 22 || now.hour < 6,
    );

    if (shouldSend) {
      _state = _state.copyWith(
        motion: newMotion,
        lastSent: filtered,
        lastSentAt: now,
        lastMoveAt:
        newMotion == MotionState.moving ? now : _state.lastMoveAt,
      );
    } else {
      _state = _state.copyWith(
        motion: newMotion,
      );
    }
    if (filtered.accuracy > 50) {
      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: false,
        motion: newMotion,
      );
    }


    return TrackingResult(
      filteredLocation: filtered,
      shouldSend: shouldSend,
      motion: newMotion,
    );
  }
  void reset() {
    _state = const TrackingState(motion: MotionState.moving);
    _kalman = null;
  }


}

