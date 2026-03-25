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
  LocationData? _stableAnchor;

  TrackingPipeline({
    required this.motionDetector,
    required this.sendPolicy,
  });

  TrackingResult process(
    LocationData raw,
    Activity? act, {
    LocationData? previousReference,
    DateTime? now,
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
      act: act,
    );
    final resolvedNow = now ?? DateTime.now();
    final transport = transportDetector.update(filtered, act);

    final lastHistoryPoint = _state.lastSent;
    final distanceKm = lastHistoryPoint?.distanceTo(filtered) ?? 0.0;
    final motionReference = previousReference ?? _stableAnchor ?? lastHistoryPoint;
    final observedDistanceKm = motionReference?.distanceTo(filtered) ?? 0.0;

    final nextMotion = motionDetector.detect(
      _state.motion,
      observedDistanceKm,
      resolvedNow,
      _state.lastMoveAt,
      speedMps: filtered.speed,
      accuracyM: filtered.accuracy,
    );

    _state = _state.copyWith(
      motion: nextMotion,
      lastMoveAt:
          nextMotion == MotionState.moving ? resolvedNow : _state.lastMoveAt,
    );
    _updateStableAnchor(filtered, nextMotion);

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
        : resolvedNow.difference(_state.lastSentAt!);

    final shouldSend = sendPolicy.shouldSend(
      motion: nextMotion,
      distanceKm: distanceKm,
      sinceLast: sinceLast,
      isNight: resolvedNow.hour >= 22 || resolvedNow.hour < 6,
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
    _updateStableAnchor(location, motion);
  }

  void reset() {
    _state = const TrackingState(motion: MotionState.moving);
    _kalman = null;
    _stableAnchor = null;
  }

  LocationData _stabilizeIndoorDrift({
    required LocationData raw,
    required LocationData next,
    LocationData? previous,
    Activity? act,
  }) {
    final reference = _stableAnchor ?? previous;
    if (reference == null) {
      return next;
    }

    final dtMs = (next.timestamp - reference.timestamp).abs();
    if (dtMs <= 0 || dtMs > 30000) {
      return next;
    }

    final distanceMeters = reference.distanceTo(next) * 1000.0;
    final combinedAccuracy = math.max(reference.accuracy, next.accuracy);
    final rawSpeed = raw.speed.isFinite ? raw.speed : 0.0;
    final resolvedSpeed = next.speed.isFinite ? next.speed : 0.0;
    final activitySuggestsRealMovement = _activitySuggestsRealMovement(act);

    final strictNoiseRadiusMeters = math.max(6.0, combinedAccuracy * 1.25);
    final stickyNoiseRadiusMeters = switch (_state.motion) {
      MotionState.moving => strictNoiseRadiusMeters,
      MotionState.idle => math.max(18.0, combinedAccuracy * 1.6),
      MotionState.stationary => math.max(24.0, combinedAccuracy * 2.0),
    };

    final likelyAccuracyEnvelopeDrift =
        !activitySuggestsRealMovement &&
        combinedAccuracy >= 12 &&
        rawSpeed <= 0.55 &&
        distanceMeters <= strictNoiseRadiusMeters;

    final likelyStickyStationaryDrift =
        !activitySuggestsRealMovement &&
        _stableAnchor != null &&
        _state.motion != MotionState.moving &&
        rawSpeed <= 0.35 &&
        resolvedSpeed <= 2.2 &&
        distanceMeters <= stickyNoiseRadiusMeters;

    if (!likelyAccuracyEnvelopeDrift && !likelyStickyStationaryDrift) {
      return next;
    }

    return next.copyWith(
      latitude: reference.latitude,
      longitude: reference.longitude,
      heading: reference.heading,
      speed: 0,
    );
  }

  bool _activitySuggestsRealMovement(Activity? act) {
    if (act == null) {
      return false;
    }

    final type = act.type.name.toLowerCase();
    final confidence = act.confidence.name.toLowerCase();
    final confidentEnough = confidence == 'medium' || confidence == 'high';
    if (!confidentEnough) {
      return false;
    }

    return type == 'walking' ||
        type == 'running' ||
        type == 'on_bicycle' ||
        type == 'in_vehicle';
  }

  void _updateStableAnchor(LocationData filtered, MotionState motion) {
    if (motion == MotionState.moving) {
      _stableAnchor = null;
      return;
    }

    final currentAnchor = _stableAnchor;
    if (currentAnchor == null) {
      _stableAnchor = filtered.copyWith(speed: 0);
      return;
    }

    final distanceFromAnchorMeters = currentAnchor.distanceTo(filtered) * 1000.0;
    final maxAnchorDriftMeters = switch (motion) {
      MotionState.moving => 0.0,
      MotionState.idle => math.max(15.0, filtered.accuracy * 1.4),
      MotionState.stationary => math.max(20.0, filtered.accuracy * 1.8),
    };

    if (distanceFromAnchorMeters <= maxAnchorDriftMeters) {
      _stableAnchor = currentAnchor.copyWith(
        timestamp: filtered.timestamp,
        accuracy: math.min(currentAnchor.accuracy, filtered.accuracy),
        heading: filtered.heading,
        speed: 0,
      );
      return;
    }

    _stableAnchor = filtered.copyWith(speed: 0);
  }
}
