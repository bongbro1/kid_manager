import 'package:kid_manager/models/location/location_data.dart';

class InteractionController {
  final List<LocationData> points;
  final void Function(LocationData point)? onPointSelected;

  InteractionController(
      this.points, {
        this.onPointSelected,
      });

  void handleTap({
    required double lat,
    required double lng,
    double maxDistanceMeters = 35,
  }) {
    final nearest = _findNearestPoint(
      points,
      lat,
      lng,
      maxDistanceMeters: maxDistanceMeters,
    );

    if (nearest != null) {
      onPointSelected?.call(nearest);
    }
  }

  LocationData? _findNearestPoint(
      List<LocationData> points,
      double lat,
      double lng, {
        double maxDistanceMeters = 35,
      }) {
    if (points.isEmpty) return null;

    LocationData? nearest;
    double minDistance = double.infinity;

    final tapped = LocationData(
      latitude: lat,
      longitude: lng,
      accuracy: 0,
      timestamp: 0,
    );

    for (final p in points) {
      final distMeters = tapped.distanceTo(p) * 1000.0;
      if (distMeters < minDistance) {
        minDistance = distMeters;
        nearest = p;
      }
    }

    if (minDistance > maxDistanceMeters) return null;
    return nearest;
  }
}