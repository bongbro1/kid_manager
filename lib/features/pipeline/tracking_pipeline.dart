import 'dart:math' as math;

import 'package:flutter_activity_recognition/models/activity.dart';
import 'package:kid_manager/core/location/kalman_filter.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/helpers/location/effective_speed_estimator.dart';
import 'package:kid_manager/helpers/location/transport_mode_detector.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/tracking_result.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class TrackingPipeline {
  final MotionDetector motionDetector;
  final SendPolicy sendPolicy;

  final TransportModeDetector transportDetector = TransportModeDetector();

  TrackingState _state = const TrackingState(motion: MotionState.moving);
  Kalman2D? _kalman;

  TrackingPipeline({
    required this.motionDetector,
    required this.sendPolicy,
  });

  TrackingResult process(
    LocationData raw,
    Activity? act, {
    LocationData? previousReference,
  }) {
    _kalman ??= Kalman2D(raw.latitude, raw.longitude);

    final resolved = EffectiveSpeedEstimator.resolveIncomingLocation(
      _kalman!.filter(raw),
      previous: previousReference,
    );
    final filtered = _stabilizeIndoorDrift(
      raw: raw,
      previous: previousReference,
      next: resolved,
    );
    final now = DateTime.now();
    final transport = transportDetector.update(filtered, act);

    final lastHistoryPoint = _state.lastSent;
    final distanceKm = lastHistoryPoint?.distanceTo(filtered) ?? 0.0;
    final motionReference = previousReference ?? lastHistoryPoint;
    final observedDistanceKm = motionReference?.distanceTo(filtered) ?? 0.0;

    final nextMotion = motionDetector.detect(
      _state.motion,
      observedDistanceKm,
      now,
      _state.lastMoveAt,
      speedMps: filtered.speed,
      accuracyM: filtered.accuracy,
    );

    _state = _state.copyWith(
      motion: nextMotion,
      lastMoveAt: nextMotion == MotionState.moving ? now : _state.lastMoveAt,
    );

    if (filtered.accuracy > 50) {
      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: false,
        motion: nextMotion,
        transport: transport,
      );
    }

    if (lastHistoryPoint == null) {
      return TrackingResult(
        filteredLocation: filtered,
        shouldSend:
            nextMotion == MotionState.moving && filtered.accuracy <= 30,
        motion: nextMotion,
        transport: transport,
      );
    }

    final sinceLast = _state.lastSentAt == null
        ? const Duration(days: 1)
        : now.difference(_state.lastSentAt!);

    final shouldSend = sendPolicy.shouldSend(
      motion: nextMotion,
      distanceKm: distanceKm,
      sinceLast: sinceLast,
      isNight: now.hour >= 22 || now.hour < 6,
      accuracyM: filtered.accuracy,
      transport: transport,
    );

    return TrackingResult(
      filteredLocation: filtered,
      shouldSend: shouldSend,
      motion: nextMotion,
      transport: transport,
    );
  }

  void acknowledgeHistorySent(
    LocationData location,
    MotionState motion, {
    DateTime? sentAt,
  }) {
    final now = sentAt ?? DateTime.now();
    _state = _state.copyWith(
      motion: motion,
      lastSent: location,
      lastSentAt: now,
      lastMoveAt: motion == MotionState.moving ? now : _state.lastMoveAt,
    );
  }

  void reset() {
    _state = const TrackingState(motion: MotionState.moving);
    _kalman = null;
  }

  LocationData _stabilizeIndoorDrift({
    required LocationData raw,
    required LocationData next,
    LocationData? previous,
  }) {
    if (previous == null) {
      return next;
    }

    final dtMs = (next.timestamp - previous.timestamp).abs();
    if (dtMs <= 0 || dtMs > 30000) {
      return next;
    }

    final distanceMeters = previous.distanceTo(next) * 1000.0;
    final combinedAccuracy = math.max(previous.accuracy, next.accuracy);
    final rawSpeed = raw.speed.isFinite ? raw.speed : 0.0;
    final resolvedSpeed = next.speed.isFinite ? next.speed : 0.0;

    final noiseRadiusMeters = combinedAccuracy <= 12
        ? 8.0
        : math.min(65.0, math.max(12.0, combinedAccuracy * 0.8));

    final likelyIndoorDrift =
        rawSpeed <= 0.8 &&
        resolvedSpeed <= 1.6 &&
        distanceMeters <= noiseRadiusMeters;

    if (!likelyIndoorDrift) {
      return next;
    }

    return next.copyWith(
      latitude: previous.latitude,
      longitude: previous.longitude,
      heading: previous.heading,
      speed: 0,
    );
  }
}
