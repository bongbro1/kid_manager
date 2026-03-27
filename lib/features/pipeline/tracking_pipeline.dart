import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_activity_recognition/models/activity.dart';
import 'package:kid_manager/core/location/kalman_filter.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_tuning.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/helpers/location/effective_speed_estimator.dart';
import 'package:kid_manager/helpers/location/transport_mode_detector.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/tracking_result.dart';

class TrackingPipeline {
  final MotionDetector motionDetector;
  final SendPolicy sendPolicy;

  final TransportModeDetector transportDetector = TransportModeDetector();

  TrackingState _state = const TrackingState(motion: MotionState.moving);
  Kalman2D? _kalman;
  LocationData? _stableAnchor;
  bool _indoorSuppressed = false;
  int _lowConfidenceStreak = 0;
  int _releaseGoodFixStreak = 0;
  DateTime? _suppressedSince;

  TrackingPipeline({required this.motionDetector, required this.sendPolicy});

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
    final preSuppression = _stabilizeIndoorDrift(
      raw: raw,
      previous: previousReference,
      next: resolved,
      act: act,
    );
    final resolvedNow = now ?? DateTime.now();
    _updateIndoorSuppression(
      raw: raw,
      next: preSuppression,
      previous: previousReference,
      act: act,
      now: resolvedNow,
    );
    final filtered = _applyIndoorSuppression(
      next: preSuppression,
      previous: previousReference,
    );
    final transport = transportDetector.update(filtered, act);

    final lastHistoryPoint = _state.lastSent;
    final distanceKm = lastHistoryPoint?.distanceTo(filtered) ?? 0.0;
    final motionReference =
        previousReference ?? _stableAnchor ?? lastHistoryPoint;
    final observedDistanceKm = motionReference?.distanceTo(filtered) ?? 0.0;

    final nextMotion = motionDetector.detect(
      _state.motion,
      observedDistanceKm,
      resolvedNow,
      _state.lastMoveAt,
      speedMps: filtered.speed,
      accuracyM: filtered.accuracy,
    );
    final effectiveMotion = _indoorSuppressed
        ? _clampSuppressedMotion(current: _state.motion, detected: nextMotion)
        : nextMotion;

    _state = _state.copyWith(
      motion: effectiveMotion,
      lastMoveAt: effectiveMotion == MotionState.moving
          ? resolvedNow
          : _state.lastMoveAt,
    );
    _updateStableAnchor(filtered, effectiveMotion);

    if (filtered.accuracy > TrackingTuning.weakAccuracyMaxM) {
      return TrackingResult(
        filteredLocation: filtered,
        shouldSend: false,
        indoorSuppressed: _indoorSuppressed,
        motion: effectiveMotion,
        transport: transport,
      );
    }

    if (lastHistoryPoint == null) {
      return TrackingResult(
        filteredLocation: filtered,
        shouldSend:
            effectiveMotion == MotionState.moving &&
            filtered.accuracy <= TrackingTuning.historyGoodAccuracyMaxM &&
            !_indoorSuppressed,
        indoorSuppressed: _indoorSuppressed,
        motion: effectiveMotion,
        transport: transport,
      );
    }

    final sinceLast = _state.lastSentAt == null
        ? const Duration(days: 1)
        : resolvedNow.difference(_state.lastSentAt!);

    final shouldSend = sendPolicy.shouldSend(
      motion: effectiveMotion,
      distanceKm: distanceKm,
      sinceLast: sinceLast,
      isNight: resolvedNow.hour >= 22 || resolvedNow.hour < 6,
      accuracyM: filtered.accuracy,
      indoorSuppressed: _indoorSuppressed,
      transport: transport,
    );

    return TrackingResult(
      filteredLocation: filtered,
      shouldSend: shouldSend,
      indoorSuppressed: _indoorSuppressed,
      motion: effectiveMotion,
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
    _indoorSuppressed = false;
    _lowConfidenceStreak = 0;
    _releaseGoodFixStreak = 0;
    _suppressedSince = null;
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
    if (dtMs <= 0 ||
        dtMs > TrackingTuning.indoorDriftMaxReferenceAge.inMilliseconds) {
      return next;
    }

    final distanceMeters = reference.distanceTo(next) * 1000.0;
    final combinedAccuracy = math.max(reference.accuracy, next.accuracy);
    final rawSpeed = raw.speed.isFinite ? raw.speed : 0.0;
    final resolvedSpeed = next.speed.isFinite ? next.speed : 0.0;
    final activitySuggestsRealMovement = _activitySuggestsRealMovement(act);

    final strictNoiseRadiusMeters = math.max(
      TrackingTuning.indoorDriftStrictNoiseRadiusMinM,
      combinedAccuracy * TrackingTuning.indoorDriftStrictNoiseRadiusMultiplier,
    );
    final stickyNoiseRadiusMeters = switch (_state.motion) {
      MotionState.moving => strictNoiseRadiusMeters,
      MotionState.idle => math.max(
        TrackingTuning.indoorDriftStickyIdleNoiseRadiusMinM,
        combinedAccuracy *
            TrackingTuning.indoorSuppressionNoiseRadiusMultiplier,
      ),
      MotionState.stationary => math.max(
        TrackingTuning.indoorDriftStickyStationaryNoiseRadiusMinM,
        combinedAccuracy *
            TrackingTuning.indoorDriftStickyStationaryNoiseRadiusMultiplier,
      ),
    };

    final likelyAccuracyEnvelopeDrift =
        !activitySuggestsRealMovement &&
        combinedAccuracy >=
            TrackingTuning.indoorDriftAccuracyEnvelopeMinAccuracyM &&
        rawSpeed <= TrackingTuning.indoorDriftAccuracyEnvelopeRawSpeedMaxMps &&
        distanceMeters <= strictNoiseRadiusMeters;

    final likelyStickyStationaryDrift =
        !activitySuggestsRealMovement &&
        _stableAnchor != null &&
        _state.motion != MotionState.moving &&
        rawSpeed <= TrackingTuning.indoorDriftStickyRawSpeedMaxMps &&
        resolvedSpeed <= TrackingTuning.indoorDriftStickyResolvedSpeedMaxMps &&
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

  void _updateIndoorSuppression({
    required LocationData raw,
    required LocationData next,
    LocationData? previous,
    Activity? act,
    required DateTime now,
  }) {
    final reference = _stableAnchor ?? previous ?? _state.lastSent ?? next;

    if (_indoorSuppressed) {
      if (_shouldReleaseIndoorSuppression(
        raw: raw,
        next: next,
        reference: reference,
        act: act,
      )) {
        final suppressedFor = _suppressedSince == null
            ? null
            : now.difference(_suppressedSince!);
        _indoorSuppressed = false;
        _lowConfidenceStreak = 0;
        _releaseGoodFixStreak = 0;
        _suppressedSince = null;
        if (kDebugMode) {
          debugPrint(
            'TrackingPipeline indoor suppression released '
            'after=${suppressedFor?.inSeconds ?? 0}s '
            'acc=${next.accuracy.toStringAsFixed(1)} '
            'speed=${next.speed.toStringAsFixed(2)}',
          );
        }
      }
      return;
    }

    if (_isLowConfidenceIndoorFix(
      raw: raw,
      next: next,
      reference: reference,
      act: act,
    )) {
      _lowConfidenceStreak += 1;
      if (_lowConfidenceStreak >= TrackingTuning.indoorSuppressionEntryStreak) {
        _indoorSuppressed = true;
        _lowConfidenceStreak = 0;
        _releaseGoodFixStreak = 0;
        _suppressedSince = now;
        _stableAnchor = _buildSuppressedAnchor(reference, next);
        if (kDebugMode) {
          final distanceMeters = reference.distanceTo(next) * 1000.0;
          debugPrint(
            'TrackingPipeline indoor suppression entered '
            'acc=${next.accuracy.toStringAsFixed(1)} '
            'rawSpeed=${raw.speed.toStringAsFixed(2)} '
            'resolvedSpeed=${next.speed.toStringAsFixed(2)} '
            'distance=${distanceMeters.toStringAsFixed(1)}m',
          );
        }
      }
      return;
    }

    _lowConfidenceStreak = 0;
  }

  bool _isLowConfidenceIndoorFix({
    required LocationData raw,
    required LocationData next,
    required LocationData reference,
    Activity? act,
  }) {
    if (_activitySuggestsRealMovement(act)) {
      return false;
    }

    if (next.accuracy < TrackingTuning.indoorSuppressionLowAccuracyMinM ||
        next.accuracy > TrackingTuning.indoorSuppressionMaxAccuracyM) {
      return false;
    }

    if (raw.speed > TrackingTuning.indoorSuppressionLowRawSpeedMaxMps ||
        next.speed > TrackingTuning.indoorSuppressionLowResolvedSpeedMaxMps) {
      return false;
    }

    final combinedAccuracy = math.max(reference.accuracy, next.accuracy);
    final distanceMeters = reference.distanceTo(next) * 1000.0;
    final noiseRadiusMeters = math.max(
      TrackingTuning.indoorSuppressionNoiseRadiusMinM,
      combinedAccuracy * TrackingTuning.indoorSuppressionNoiseRadiusMultiplier,
    );

    return distanceMeters <= noiseRadiusMeters;
  }

  bool _shouldReleaseIndoorSuppression({
    required LocationData raw,
    required LocationData next,
    required LocationData reference,
    Activity? act,
  }) {
    final distanceMeters = reference.distanceTo(next) * 1000.0;
    final releaseDistanceMeters = math.max(
      TrackingTuning.indoorSuppressionReleaseDistanceMinM,
      math.max(reference.accuracy, next.accuracy) *
          TrackingTuning.indoorSuppressionReleaseDistanceMultiplier,
    );
    final goodAccuracy =
        next.accuracy <=
        TrackingTuning.indoorSuppressionReleaseGoodFixAccuracyMaxM;
    final goodSpeed =
        raw.speed >=
            TrackingTuning.indoorSuppressionReleaseGoodFixSpeedMinMps ||
        next.speed >= TrackingTuning.indoorSuppressionReleaseGoodFixSpeedMinMps;
    final strongActivity = _activitySuggestsRealMovement(act);
    final outsideEnvelope = distanceMeters >= releaseDistanceMeters;

    if (!goodAccuracy || !outsideEnvelope) {
      _releaseGoodFixStreak = 0;
      return false;
    }

    if (strongActivity) {
      _releaseGoodFixStreak = 0;
      return true;
    }

    if (!goodSpeed) {
      _releaseGoodFixStreak = 0;
      return false;
    }

    _releaseGoodFixStreak += 1;
    if (_releaseGoodFixStreak >=
        TrackingTuning.indoorSuppressionReleaseGoodFixStreak) {
      _releaseGoodFixStreak = 0;
      return true;
    }
    return false;
  }

  LocationData _applyIndoorSuppression({
    required LocationData next,
    LocationData? previous,
  }) {
    if (!_indoorSuppressed) {
      return next;
    }

    final anchor = _stableAnchor ?? previous ?? _state.lastSent ?? next;
    _stableAnchor = _refreshSuppressedAnchor(anchor, next);
    final refreshedAnchor = _stableAnchor ?? anchor;
    return refreshedAnchor.copyWith(
      timestamp: next.timestamp,
      accuracy: math.min(refreshedAnchor.accuracy, next.accuracy),
      heading: next.heading,
      speed: 0,
    );
  }

  LocationData _buildSuppressedAnchor(
    LocationData reference,
    LocationData next,
  ) {
    return reference.copyWith(
      timestamp: next.timestamp,
      accuracy: math.min(reference.accuracy, next.accuracy),
      heading: next.heading,
      speed: 0,
    );
  }

  LocationData _refreshSuppressedAnchor(
    LocationData anchor,
    LocationData next,
  ) {
    final distanceMeters = anchor.distanceTo(next) * 1000.0;
    if (distanceMeters > TrackingTuning.indoorSuppressionAnchorRefreshRadiusM) {
      return anchor;
    }

    return anchor.copyWith(
      timestamp: next.timestamp,
      accuracy: math.min(anchor.accuracy, next.accuracy),
      heading: next.heading,
      speed: 0,
    );
  }

  MotionState _clampSuppressedMotion({
    required MotionState current,
    required MotionState detected,
  }) {
    if (current == MotionState.stationary ||
        detected == MotionState.stationary) {
      return MotionState.stationary;
    }
    return MotionState.idle;
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

    if (_indoorSuppressed) {
      _stableAnchor = _refreshSuppressedAnchor(currentAnchor, filtered);
      return;
    }

    final distanceFromAnchorMeters =
        currentAnchor.distanceTo(filtered) * 1000.0;
    final maxAnchorDriftMeters = switch (motion) {
      MotionState.moving => 0.0,
      MotionState.idle => math.max(
        TrackingTuning.stableAnchorIdleMaxDriftMinM,
        filtered.accuracy * TrackingTuning.stableAnchorIdleDriftMultiplier,
      ),
      MotionState.stationary => math.max(
        TrackingTuning.stableAnchorStationaryMaxDriftMinM,
        filtered.accuracy *
            TrackingTuning.stableAnchorStationaryDriftMultiplier,
      ),
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
