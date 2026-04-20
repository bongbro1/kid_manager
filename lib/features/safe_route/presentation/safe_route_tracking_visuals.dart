import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_hazard.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_tracking_state.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

enum SafeRouteTrackingSeverity { safe, warning, danger }

class SafeRouteTrackingVisuals {
  final SafeRouteTrackingSeverity severity;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final Color accentColor;
  final Color softColor;
  final Color bannerColor;
  final Color borderColor;
  final Color badgeBackgroundColor;
  final Color badgeForegroundColor;
  final Color iconBackgroundColor;

  const SafeRouteTrackingVisuals({
    required this.severity,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.accentColor,
    required this.softColor,
    required this.bannerColor,
    required this.borderColor,
    required this.badgeBackgroundColor,
    required this.badgeForegroundColor,
    required this.iconBackgroundColor,
  });
}

SafeRouteTrackingVisuals resolveSafeRouteTrackingVisuals(
  SafeRouteTrackingState state, {
  required AppLocalizations l10n,
  required String fallbackStatusLabel,
}) {
  final distanceMeters = state.activeTrip?.currentDistanceFromRouteMeters ?? 0;
  final triggeredHazard = findTriggeredSafeRouteHazard(state);

  if (triggeredHazard != null) {
    return SafeRouteTrackingVisuals(
      severity: SafeRouteTrackingSeverity.danger,
      icon: Icons.warning_amber_rounded,
      title: l10n.safeRouteVisualDangerTitle,
      subtitle: l10n.safeRouteVisualDangerSubtitle(triggeredHazard.name),
      badgeLabel: l10n.safeRouteVisualDangerBadge,
      accentColor: const Color(0xFFDC2626),
      softColor: const Color(0xFFFEF2F2),
      bannerColor: const Color(0xFFFFF6F6),
      borderColor: const Color(0xFFFCA5A5),
      badgeBackgroundColor: const Color(0xFFDC2626),
      badgeForegroundColor: Colors.white,
      iconBackgroundColor: const Color(0xFFFEE2E2),
    );
  }

  switch (state.activeTrip?.status) {
    case TripStatus.temporarilyDeviated:
    case TripStatus.deviated:
      return SafeRouteTrackingVisuals(
        severity: SafeRouteTrackingSeverity.warning,
        icon: Icons.near_me_rounded,
        title: distanceMeters > 0
            ? l10n.safeRouteVisualOffRouteTitle(
                l10n.safeRouteDistanceLabel(distanceMeters),
              )
            : fallbackStatusLabel,
        subtitle: state.activeTrip?.reason?.trim().isNotEmpty == true
            ? state.activeTrip!.reason!
            : l10n.safeRouteVisualOffRouteSubtitle,
        badgeLabel: l10n.safeRouteVisualOffRouteBadge,
        accentColor: const Color(0xFFD97706),
        softColor: const Color(0xFFFFF7ED),
        bannerColor: const Color(0xFFFFFBF2),
        borderColor: const Color(0xFFFCD34D),
        badgeBackgroundColor: const Color(0xFFFEF3C7),
        badgeForegroundColor: const Color(0xFFB45309),
        iconBackgroundColor: const Color(0xFFFFEDD5),
      );
    case TripStatus.completed:
      return SafeRouteTrackingVisuals(
        severity: SafeRouteTrackingSeverity.safe,
        icon: Icons.check_circle_rounded,
        title: l10n.safeRouteVisualCompletedTitle,
        subtitle: l10n.safeRouteVisualCompletedSubtitle,
        badgeLabel: l10n.safeRouteVisualCompletedBadge,
        accentColor: const Color(0xFF2563EB),
        softColor: const Color(0xFFEFF6FF),
        bannerColor: Colors.white,
        borderColor: const Color(0xFFBFDBFE),
        badgeBackgroundColor: const Color(0xFFDBEAFE),
        badgeForegroundColor: const Color(0xFF1D4ED8),
        iconBackgroundColor: const Color(0xFFDBEAFE),
      );
    case TripStatus.cancelled:
      return SafeRouteTrackingVisuals(
        severity: SafeRouteTrackingSeverity.warning,
        icon: Icons.pause_circle_rounded,
        title: l10n.safeRouteVisualCancelledTitle,
        subtitle: l10n.safeRouteVisualCancelledSubtitle,
        badgeLabel: l10n.safeRouteVisualCancelledBadge,
        accentColor: const Color(0xFF64748B),
        softColor: const Color(0xFFF8FAFC),
        bannerColor: Colors.white,
        borderColor: const Color(0xFFE2E8F0),
        badgeBackgroundColor: const Color(0xFFE2E8F0),
        badgeForegroundColor: const Color(0xFF475569),
        iconBackgroundColor: const Color(0xFFE2E8F0),
      );
    case TripStatus.planned:
      return SafeRouteTrackingVisuals(
        severity: SafeRouteTrackingSeverity.safe,
        icon: Icons.event_available_rounded,
        title: l10n.safeRouteVisualPlannedTitle,
        subtitle: l10n.safeRouteVisualPlannedSubtitle,
        badgeLabel: l10n.safeRouteVisualPlannedBadge,
        accentColor: const Color(0xFF1D4ED8),
        softColor: const Color(0xFFEFF6FF),
        bannerColor: Colors.white,
        borderColor: const Color(0xFFBFDBFE),
        badgeBackgroundColor: const Color(0xFFDBEAFE),
        badgeForegroundColor: const Color(0xFF1D4ED8),
        iconBackgroundColor: const Color(0xFFDBEAFE),
      );
    case TripStatus.active:
    case null:
      return SafeRouteTrackingVisuals(
        severity: SafeRouteTrackingSeverity.safe,
        icon: Icons.shield_rounded,
        title: l10n.safeRouteVisualActiveTitle,
        subtitle: l10n.safeRouteVisualActiveSubtitle,
        badgeLabel: l10n.safeRouteVisualActiveBadge,
        accentColor: const Color(0xFF059669),
        softColor: const Color(0xFFECFDF3),
        bannerColor: Colors.white,
        borderColor: const Color(0xFFA7F3D0),
        badgeBackgroundColor: const Color(0xFFD1FAE5),
        badgeForegroundColor: const Color(0xFF059669),
        iconBackgroundColor: const Color(0xFFD1FAE5),
      );
  }
}

RouteHazard? findTriggeredSafeRouteHazard(SafeRouteTrackingState state) {
  final live = state.liveLocation;
  final route = state.activeRoute;
  if (live == null || route == null) return null;

  for (final hazard in route.hazards) {
    final distance = _distanceMeters(
      live.latitude,
      live.longitude,
      hazard.latitude,
      hazard.longitude,
    );
    if (distance <= hazard.radiusMeters) {
      return hazard;
    }
  }

  final reason = (state.activeTrip?.reason ?? '').toLowerCase();
  if (reason.contains('danger') || reason.contains('hazard')) {
    return route.hazards.isEmpty ? null : route.hazards.first;
  }

  return null;
}

bool isSafeRouteDangerState(SafeRouteTrackingState state) {
  return findTriggeredSafeRouteHazard(state) != null;
}

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _degToRad(double degrees) => degrees * math.pi / 180.0;
