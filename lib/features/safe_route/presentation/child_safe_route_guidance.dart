import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_hazard.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';

enum ChildSafeRouteSeverity { safe, offRoute, danger, arrived }

class ChildSafeRouteGuidance {
  const ChildSafeRouteGuidance({
    required this.severity,
    required this.primaryInstruction,
    required this.secondaryInstruction,
    required this.statusLabel,
    required this.remainingDistanceLabel,
    required this.etaLabel,
    required this.remainingDistanceMeters,
    required this.distanceFromRouteMeters,
    required this.progress,
    required this.triggeredHazard,
  });

  final ChildSafeRouteSeverity severity;
  final String primaryInstruction;
  final String secondaryInstruction;
  final String statusLabel;
  final String remainingDistanceLabel;
  final String etaLabel;
  final double remainingDistanceMeters;
  final double distanceFromRouteMeters;
  final double progress;
  final RouteHazard? triggeredHazard;
}

ChildSafeRouteGuidance buildChildSafeRouteGuidance({
  required SafeRoute route,
  required Trip trip,
  required LocationData location,
  required String languageCode,
}) {
  final l10n = lookupAppLocalizations(Locale(languageCode));
  final strings = _ChildSafeRouteStrings(l10n);
  final points = _normalizedRoutePoints(route);
  if (points.isEmpty) {
    return ChildSafeRouteGuidance(
      severity: ChildSafeRouteSeverity.safe,
      primaryInstruction: strings.continueStraight(strings.distanceLabel(0)),
      secondaryInstruction: strings.routeLoading,
      statusLabel: strings.safeStatus,
      remainingDistanceLabel: strings.distanceLabel(0),
      etaLabel: strings.etaLabel(0),
      remainingDistanceMeters: 0,
      distanceFromRouteMeters: 0,
      progress: 0,
      triggeredHazard: null,
    );
  }

  final triggeredHazard = _findTriggeredHazard(route, location);
  final match = _matchCurrentLocationToRoute(location, points);
  final remainingMeters = _remainingDistanceMeters(
    current: location,
    points: points,
    match: match,
  );
  final distanceToDestinationMeters = _distanceMeters(
    location.latitude,
    location.longitude,
    route.endPoint.latitude,
    route.endPoint.longitude,
  );
  final thresholdMeters = math.max(50.0, route.corridorWidthMeters);
  final isOffRoute =
      trip.status == TripStatus.deviated ||
      trip.status == TripStatus.temporarilyDeviated ||
      match.distanceFromRouteMeters > thresholdMeters;
  final isArrived =
      remainingMeters <= 12 &&
      distanceToDestinationMeters <= 10 &&
      match.distanceFromRouteMeters <= math.max(15.0, thresholdMeters * 0.35);

  final severity = triggeredHazard != null
      ? ChildSafeRouteSeverity.danger
      : isArrived
      ? ChildSafeRouteSeverity.arrived
      : isOffRoute
      ? ChildSafeRouteSeverity.offRoute
      : ChildSafeRouteSeverity.safe;

  final etaSeconds = _estimateEtaSeconds(
    remainingDistanceMeters: remainingMeters,
    route: route,
    location: location,
  );

  final primaryInstruction = _buildPrimaryInstruction(
    strings: strings,
    severity: severity,
    points: points,
    match: match,
    remainingMeters: remainingMeters,
    hazard: triggeredHazard,
    location: location,
  );
  final secondaryInstruction = _buildSecondaryInstruction(
    strings: strings,
    severity: severity,
    distanceFromRouteMeters: match.distanceFromRouteMeters,
    remainingMeters: remainingMeters,
    hazard: triggeredHazard,
  );

  return ChildSafeRouteGuidance(
    severity: severity,
    primaryInstruction: primaryInstruction,
    secondaryInstruction: secondaryInstruction,
    statusLabel: strings.statusLabel(severity),
    remainingDistanceLabel: strings.distanceLabel(remainingMeters),
    etaLabel: strings.etaLabel(etaSeconds),
    remainingDistanceMeters: remainingMeters,
    distanceFromRouteMeters: match.distanceFromRouteMeters,
    progress: route.distanceMeters <= 0
        ? 0
        : (1 - (remainingMeters / route.distanceMeters)).clamp(0, 1).toDouble(),
    triggeredHazard: triggeredHazard,
  );
}

List<RoutePoint> _normalizedRoutePoints(SafeRoute route) {
  final fromRoute = [...route.points]
    ..sort((a, b) => a.sequence.compareTo(b.sequence));
  if (fromRoute.length >= 2) {
    return fromRoute;
  }
  return [
    route.startPoint.copyWith(sequence: 0),
    route.endPoint.copyWith(sequence: 1),
  ];
}

RouteHazard? _findTriggeredHazard(SafeRoute route, LocationData location) {
  for (final hazard in route.hazards) {
    final distance = _distanceMeters(
      location.latitude,
      location.longitude,
      hazard.latitude,
      hazard.longitude,
    );
    if (distance <= hazard.radiusMeters) {
      return hazard;
    }
  }
  return null;
}

String _buildPrimaryInstruction({
  required _ChildSafeRouteStrings strings,
  required ChildSafeRouteSeverity severity,
  required List<RoutePoint> points,
  required _RouteProjection match,
  required double remainingMeters,
  required RouteHazard? hazard,
  required LocationData location,
}) {
  if (severity == ChildSafeRouteSeverity.danger && hazard != null) {
    return strings.leaveDangerZone(hazard.name);
  }
  if (severity == ChildSafeRouteSeverity.offRoute) {
    return strings.returnToSafeRoute;
  }
  if (severity == ChildSafeRouteSeverity.arrived) {
    return strings.arrivedInstruction;
  }

  final nextTurnDistance = _distanceToNextTurn(
    current: location,
    points: points,
    match: match,
  );

  final turnInstruction = _upcomingTurnInstruction(
    points: points,
    match: match,
    strings: strings,
    distanceToTurnMeters: nextTurnDistance,
  );
  if (turnInstruction != null) {
    return turnInstruction;
  }

  final straightDistance = math.min(nextTurnDistance, remainingMeters);
  return strings.continueStraight(strings.distanceLabel(straightDistance));
}

String _buildSecondaryInstruction({
  required _ChildSafeRouteStrings strings,
  required ChildSafeRouteSeverity severity,
  required double distanceFromRouteMeters,
  required double remainingMeters,
  required RouteHazard? hazard,
}) {
  switch (severity) {
    case ChildSafeRouteSeverity.danger:
      return strings.dangerDescription(hazard?.name ?? strings.dangerArea);
    case ChildSafeRouteSeverity.offRoute:
      return strings.offRouteDescription(
        strings.distanceLabel(distanceFromRouteMeters),
      );
    case ChildSafeRouteSeverity.arrived:
      return strings.arrivedDescription;
    case ChildSafeRouteSeverity.safe:
      return strings.remainingDescription(
        strings.distanceLabel(remainingMeters),
      );
  }
}

String? _upcomingTurnInstruction({
  required List<RoutePoint> points,
  required _RouteProjection match,
  required _ChildSafeRouteStrings strings,
  required double distanceToTurnMeters,
}) {
  final currentIndex = match.segmentIndex;
  if (currentIndex < 0 || currentIndex + 2 >= points.length) {
    return null;
  }

  final turnPoint = points[currentIndex + 1];
  final afterTurnPoint = points[currentIndex + 2];
  final beforeTurnPoint = points[currentIndex];

  final currentBearing = _bearingDegrees(beforeTurnPoint, turnPoint);
  final nextBearing = _bearingDegrees(turnPoint, afterTurnPoint);
  final delta = _normalizeDegrees(nextBearing - currentBearing);
  final distanceLabel = strings.distanceLabel(distanceToTurnMeters);

  if (delta.abs() < 18) {
    return null;
  }
  if (delta.abs() > 145) {
    return strings.makeUTurn(distanceLabel);
  }
  if (delta > 70) {
    return strings.turnRight(distanceLabel);
  }
  if (delta < -70) {
    return strings.turnLeft(distanceLabel);
  }
  if (delta > 0) {
    return strings.keepRight(distanceLabel);
  }
  return strings.keepLeft(distanceLabel);
}

double _distanceToNextTurn({
  required LocationData current,
  required List<RoutePoint> points,
  required _RouteProjection match,
}) {
  if (points.length < 2) return 0;
  final nextPointIndex = math.min(match.segmentIndex + 1, points.length - 1);
  final nextPoint = points[nextPointIndex];
  return _distanceMeters(
    current.latitude,
    current.longitude,
    nextPoint.latitude,
    nextPoint.longitude,
  );
}

double _remainingDistanceMeters({
  required LocationData current,
  required List<RoutePoint> points,
  required _RouteProjection match,
}) {
  if (points.length < 2) return 0;

  var remaining = _distanceMeters(
    current.latitude,
    current.longitude,
    match.projectedLatitude,
    match.projectedLongitude,
  );

  final segmentStart = points[match.segmentIndex];
  final segmentEnd = points[match.segmentIndex + 1];
  final segmentLength = _distanceMeters(
    segmentStart.latitude,
    segmentStart.longitude,
    segmentEnd.latitude,
    segmentEnd.longitude,
  );
  remaining += segmentLength * (1 - match.segmentFraction);

  for (var i = match.segmentIndex + 1; i < points.length - 1; i++) {
    remaining += _distanceMeters(
      points[i].latitude,
      points[i].longitude,
      points[i + 1].latitude,
      points[i + 1].longitude,
    );
  }

  return remaining;
}

double _estimateEtaSeconds({
  required double remainingDistanceMeters,
  required SafeRoute route,
  required LocationData location,
}) {
  if (remainingDistanceMeters <= 1) return 0;
  if (location.speed > 1.0) {
    return remainingDistanceMeters / location.speed;
  }
  if (route.distanceMeters > 0 && route.durationSeconds > 0) {
    return route.durationSeconds *
        (remainingDistanceMeters / route.distanceMeters);
  }
  return remainingDistanceMeters / 1.3;
}

_RouteProjection _matchCurrentLocationToRoute(
  LocationData current,
  List<RoutePoint> points,
) {
  if (points.length < 2) {
    return _RouteProjection(
      segmentIndex: 0,
      segmentFraction: 0,
      distanceFromRouteMeters: 0,
      projectedLatitude: points.first.latitude,
      projectedLongitude: points.first.longitude,
    );
  }

  _RouteProjection? best;
  for (var i = 0; i < points.length - 1; i++) {
    final projection = _projectOntoSegment(
      current: current,
      start: points[i],
      end: points[i + 1],
      segmentIndex: i,
    );
    if (best == null ||
        projection.distanceFromRouteMeters < best.distanceFromRouteMeters) {
      best = projection;
    }
  }
  return best!;
}

_RouteProjection _projectOntoSegment({
  required LocationData current,
  required RoutePoint start,
  required RoutePoint end,
  required int segmentIndex,
}) {
  final originLat = current.latitude;
  final metersPerLat = 111320.0;
  final cosValue = math.cos(originLat * math.pi / 180.0).abs();
  final metersPerLng = 111320.0 * cosValue.clamp(0.0001, 1.0).toDouble();

  final ax = (start.longitude - current.longitude) * metersPerLng;
  final ay = (start.latitude - current.latitude) * metersPerLat;
  final bx = (end.longitude - current.longitude) * metersPerLng;
  final by = (end.latitude - current.latitude) * metersPerLat;

  final dx = bx - ax;
  final dy = by - ay;
  final lengthSquared = dx * dx + dy * dy;

  var t = 0.0;
  if (lengthSquared > 0) {
    t = (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0).toDouble();
  }

  final qx = ax + dx * t;
  final qy = ay + dy * t;
  final distance = math.sqrt(qx * qx + qy * qy);

  final projectedLongitude = current.longitude + (qx / metersPerLng);
  final projectedLatitude = current.latitude + (qy / metersPerLat);

  return _RouteProjection(
    segmentIndex: segmentIndex,
    segmentFraction: t,
    distanceFromRouteMeters: distance,
    projectedLatitude: projectedLatitude,
    projectedLongitude: projectedLongitude,
  );
}

double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = _toRadians(lat2 - lat1);
  final dLng = _toRadians(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _bearingDegrees(RoutePoint from, RoutePoint to) {
  final lat1 = _toRadians(from.latitude);
  final lat2 = _toRadians(to.latitude);
  final dLng = _toRadians(to.longitude - from.longitude);

  final y = math.sin(dLng) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  return (_toDegrees(math.atan2(y, x)) + 360) % 360;
}

double _normalizeDegrees(double degrees) {
  var value = degrees;
  while (value > 180) {
    value -= 360;
  }
  while (value < -180) {
    value += 360;
  }
  return value;
}

double _toRadians(double degrees) => degrees * math.pi / 180.0;

double _toDegrees(double radians) => radians * 180.0 / math.pi;

class _RouteProjection {
  const _RouteProjection({
    required this.segmentIndex,
    required this.segmentFraction,
    required this.distanceFromRouteMeters,
    required this.projectedLatitude,
    required this.projectedLongitude,
  });

  final int segmentIndex;
  final double segmentFraction;
  final double distanceFromRouteMeters;
  final double projectedLatitude;
  final double projectedLongitude;
}

class _ChildSafeRouteStrings {
  const _ChildSafeRouteStrings(this.l10n);

  final AppLocalizations l10n;

  String get routeLoading => l10n.safeRouteGuidanceLoadingRoute;
  String get safeStatus => l10n.safeRouteGuidanceStatusOnRoute;
  String get dangerArea => l10n.safeRouteGuidanceDangerArea;
  String get returnToSafeRoute => l10n.safeRouteGuidanceReturnToSafeRoute;
  String get arrivedInstruction => l10n.safeRouteGuidanceArrivedInstruction;
  String get arrivedDescription => l10n.safeRouteGuidanceArrivedDescription;

  String statusLabel(ChildSafeRouteSeverity severity) {
    switch (severity) {
      case ChildSafeRouteSeverity.danger:
        return l10n.safeRouteVisualDangerBadge;
      case ChildSafeRouteSeverity.offRoute:
        return l10n.safeRouteGuidanceStatusOffRoute;
      case ChildSafeRouteSeverity.arrived:
        return l10n.safeRouteGuidanceStatusAlmostThere;
      case ChildSafeRouteSeverity.safe:
        return l10n.safeRouteGuidanceStatusSafeRoute;
    }
  }

  String leaveDangerZone(String hazardName) {
    return l10n.safeRouteGuidanceLeaveDangerZone(hazardName);
  }

  String dangerDescription(String hazardName) {
    return l10n.safeRouteGuidanceDangerDescription(hazardName);
  }

  String offRouteDescription(String distanceLabel) {
    return l10n.safeRouteGuidanceOffRouteDescription(distanceLabel);
  }

  String remainingDescription(String distanceLabel) {
    return l10n.safeRouteGuidanceRemainingDescription(distanceLabel);
  }

  String continueStraight(String distanceLabel) {
    return l10n.safeRouteGuidanceContinueStraight(distanceLabel);
  }

  String turnLeft(String distanceLabel) {
    return l10n.safeRouteGuidanceTurnLeft(distanceLabel);
  }

  String turnRight(String distanceLabel) {
    return l10n.safeRouteGuidanceTurnRight(distanceLabel);
  }

  String keepLeft(String distanceLabel) {
    return l10n.safeRouteGuidanceKeepLeft(distanceLabel);
  }

  String keepRight(String distanceLabel) {
    return l10n.safeRouteGuidanceKeepRight(distanceLabel);
  }

  String makeUTurn(String distanceLabel) {
    return l10n.safeRouteGuidanceMakeUTurn(distanceLabel);
  }

  String etaLabel(double seconds) {
    if (seconds <= 0) {
      return l10n.safeRouteGuidanceEtaNow;
    }
    if (seconds >= 3600) {
      final hours = seconds ~/ 3600;
      final minutes = ((seconds % 3600) / 60).round();
      if (minutes == 0) {
        return l10n.safeRouteDurationHours(hours);
      }
      return l10n.safeRouteDurationHoursMinutesShort(hours, minutes);
    }
    return l10n.safeRouteDurationMinutes(math.max(1, (seconds / 60).round()));
  }

  String distanceLabel(double meters) {
    return l10n.safeRouteDistanceLabel(math.max(1, meters));
  }
}
