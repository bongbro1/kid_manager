import 'dart:math';

import 'package:kid_manager/models/zones/geo_zone.dart';

double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusM = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180.0;
  final dLon = (lon2 - lon1) * pi / 180.0;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180.0) *
          cos(lat2 * pi / 180.0) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusM * c;
}

/// Returns the first zone that truly overlaps or touches the candidate.
GeoZone? findOverlappingZone({
  required GeoZone candidate,
  required List<GeoZone> existing,
  double touchToleranceM = 0.0,
}) {
  for (final z in existing) {
    if (!z.enabled || z.id == candidate.id) continue;

    final distanceM = _haversineMeters(
      candidate.lat,
      candidate.lng,
      z.lat,
      z.lng,
    );
    final boundaryDistanceM = candidate.radiusM + z.radiusM;
    final distanceToBoundaryM = distanceM - boundaryDistanceM;

    if (distanceToBoundaryM <= touchToleranceM) {
      return z;
    }
  }

  return null;
}
