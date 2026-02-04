import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;

import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/location/location_data.dart';

enum MapRouteMode {
  none,
  singleRoute,
}

class MapViewController extends ChangeNotifier {
  final MapController controller = MapController();

  // ===== CAMERA STATE =====
  bool _autoFollow = true;
  bool get autoFollow => _autoFollow;

  bool _fittedOnce = false;

  osm.LatLng? _lastKnownCenter;

  void setAutoFollow(bool v) {
    _autoFollow = v;
    notifyListeners();
  }

  // ===== ROUTE STATE =====
  MapRouteMode _routeMode = MapRouteMode.none;
  List<osm.LatLng> _routePoints = [];

  MapRouteMode get routeMode => _routeMode;
  List<osm.LatLng> get routePoints => List.unmodifiable(_routePoints);
  bool get isRouteActive => _routeMode != MapRouteMode.none;

  // ===== BASIC MOVE =====
  void moveTo(osm.LatLng point, {double zoom = 16}) {
    _lastKnownCenter = point;
    controller.move(point, zoom);
  }

  void moveToIfAllowed(osm.LatLng point, {double zoom = 16}) {
    if (!_autoFollow) return;
    moveTo(point, zoom: zoom);
  }

  void fitCurrent({double zoom = 16}) {
    if (_lastKnownCenter != null) {
      controller.move(_lastKnownCenter!, zoom);
    }
  }

  // ===== ROUTE =====
  void showRoute(List<osm.LatLng> points) {
    if (points.length < 2) return;

    _routeMode = MapRouteMode.singleRoute;
    _routePoints = List.from(points);

    fitRoute();
    notifyListeners();
  }

  void clearRoute() {
    _routeMode = MapRouteMode.none;
    _routePoints.clear();
    notifyListeners();
  }

  void toggleRoute(List<osm.LatLng> points) {
    if (isRouteActive) {
      clearRoute();
    } else {
      showRoute(points);
    }
  }

  void fitRoute({EdgeInsets padding = const EdgeInsets.all(60)}) {
    if (_routePoints.length < 2) return;

    final bounds = LatLngBounds.fromPoints(_routePoints);
    controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: padding),
    );
  }

  // ===== FIT POINTS =====
  void fitPoints(
      List<osm.LatLng> points, {
        EdgeInsets padding = const EdgeInsets.all(60),
      }) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      moveTo(points.first);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    controller.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: padding),
    );
  }

  void fitOnce(List<osm.LatLng> points) {
    if (_fittedOnce) return;
    _fittedOnce = true;
    fitPoints(points);
  }

  void resetFit() {
    _fittedOnce = false;
  }

  // ===== MARKERS =====
  List<Marker> buildMarkers({
    required List<AppUser> children,
    required Map<String, LocationData> latestMap,
    void Function(AppUser child)? onTapChild,
  }) {
    final markers = <Marker>[];

    for (final child in children) {
      final loc = latestMap[child.uid];
      if (loc == null) continue;

      final p = osm.LatLng(loc.latitude, loc.longitude);
      if (!p.latitude.isFinite || !p.longitude.isFinite) continue;

      markers.add(
        Marker(
          key: ValueKey(child.uid),
          point: p,
          width: 90,
          height: 90,
          child: GestureDetector(
            onTap: onTapChild == null ? null : () => onTapChild(child),
            child: Column(
              children: [
                _ChildLabel(child.displayLabel),
                const Icon(Icons.location_pin, color: Colors.red, size: 44),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }
}

/// ===== PRIVATE WIDGET =====
class _ChildLabel extends StatelessWidget {
  final String text;

  const _ChildLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(blurRadius: 3, color: Colors.black26),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
