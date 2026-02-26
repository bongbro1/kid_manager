import 'package:flutter_activity_recognition/models/activity.dart';
import 'package:kid_manager/core/location/kalman_filter.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/helpers/location/transport_mode_detector.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/tracking_result.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class TrackingPipeline {
  final MotionDetector motionDetector;
  final SendPolicy sendPolicy;
  bool _sentFirstFix = false;
  DateTime? _firstFixStartedAt;
  bool _sentFirstGoodFix = false;

  final TransportModeDetector transportDetector = TransportModeDetector();

  TrackingState _state = const TrackingState(motion: MotionState.moving);
  Kalman2D? _kalman;

  TrackingPipeline({
    required this.motionDetector,
    required this.sendPolicy,
  });

  TrackingResult process(LocationData raw, Activity? act) {
    _kalman ??= Kalman2D(raw.latitude, raw.longitude);

    final filtered = _kalman!.filter(raw);
    final now = DateTime.now();

    final TransportMode transport = transportDetector.update(filtered, act);

    final last = _state.lastSent;
    double distance = 0;
    if (last != null) distance = last.distanceTo(filtered);

    // FIRST SEND
    if (last == null) {
      final initialMotion =
      (filtered.speedKmh < 1.0) ? MotionState.idle : MotionState.moving;

      // ✅ Luôn gửi 1 lần đầu tiên ngay khi có fix đầu tiên
      _sentFirstFix = true;
      _state = _state.copyWith(
        motion: initialMotion,
        lastSent: filtered,
        lastSentAt: now,
        lastMoveAt: initialMotion == MotionState.moving ? now : null,
      );

      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: true, // ✅ luôn true lần đầu
        motion: initialMotion,
        transport: transport,
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
    if (!_sentFirstGoodFix && filtered.accuracy <= 30) {
      _sentFirstGoodFix = true;

      // update state như 1 lần gửi thật sự
      _state = _state.copyWith(
        motion: newMotion,
        lastSent: filtered,
        lastSentAt: now,
        lastMoveAt: newMotion == MotionState.moving ? now : _state.lastMoveAt,
      );

      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: true,
        motion: newMotion,
        transport: transport,
      );
    }    final shouldSend = sendPolicy.shouldSend(
      motion: newMotion,
      distanceKm: distance,
      sinceLast: sinceLast,
      isNight: now.hour >= 22 || now.hour < 6,
      accuracyM: filtered.accuracy,
      transport: transport,
    );

    if (shouldSend) {
      _state = _state.copyWith(
        motion: newMotion,
        lastSent: filtered,
        lastSentAt: now,
        lastMoveAt: newMotion == MotionState.moving ? now : _state.lastMoveAt,
      );
    } else {
      _state = _state.copyWith(motion: newMotion);
    }

    if (filtered.accuracy > 50) {
      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: false,
        motion: newMotion,
        transport: transport,
      );
    }

    return TrackingResult(
      filteredLocation: filtered,
      shouldSend: shouldSend,
      motion: newMotion,
      transport: transport,
    );
  }

  void reset() {
    _state = const TrackingState(motion: MotionState.moving);
    _kalman = null;
    _sentFirstFix = false;
    _firstFixStartedAt = null;
    _sentFirstGoodFix = false;

  }
}