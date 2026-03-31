import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/location/location_data.dart';

class CameraController {
  final MapboxMap map;
  static const double _singlePointZoom = 16.4;

  CameraController(this.map);

  Future<void> fitToRoute(List<LocationData> history) async {
    if (history.isEmpty) return;
    if (history.length == 1) {
      await focusOnPoint(history.first);
      return;
    }

    double minLat = history.first.latitude;
    double maxLat = history.first.latitude;
    double minLng = history.first.longitude;
    double maxLng = history.first.longitude;

    for (final p in history) {
      minLat = min(minLat, p.latitude);
      maxLat = max(maxLat, p.latitude);
      minLng = min(minLng, p.longitude);
      maxLng = max(maxLng, p.longitude);
    }

    final bounds = CoordinateBounds(
      southwest: Point(
        coordinates: Position(minLng, minLat),
      ),
      northeast: Point(
        coordinates: Position(maxLng, maxLat),
      ),
      infiniteBounds: false,
    );

    final cameraOptions =
    await map.cameraForCoordinateBounds(
      bounds,
      MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50),
      null,
      null,
      null,
      null,
    );

    await map.easeTo(
      cameraOptions,
      MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> focusOnPoint(
    LocationData loc, {
    double zoom = _singlePointZoom,
  }) async {
    final cameraState = await map.getCameraState();
    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(loc.longitude, loc.latitude),
        ),
        zoom: cameraState.zoom > zoom ? cameraState.zoom : zoom,
        bearing: cameraState.bearing,
        pitch: cameraState.pitch,
      ),
      MapAnimationOptions(duration: 850),
    );
  }

  Future<void> follow(LocationData loc) async {
    await map.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(loc.longitude, loc.latitude),
        ),
        zoom: 17,
      ),
      MapAnimationOptions(duration: 800),
    );
  }
}
