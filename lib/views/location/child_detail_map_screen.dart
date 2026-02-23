import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/location/history_snap_engine.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as osm;

import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/services/location/mapbox_route_service.dart';



class ChildDetailMapScreen extends StatefulWidget {
  final String childId;

  const ChildDetailMapScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildDetailMapScreen> createState() =>
      _ChildDetailMapScreenState();
}

class _ChildDetailMapScreenState
    extends State<ChildDetailMapScreen> {

  MapboxMap? _map;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _marker;

  final List<osm.LatLng> _trail = [];
  final List<osm.LatLng> _buffer = [];

  StreamSubscription? _sub;
  Timer? _debounce;

  bool _autoFollow = true;

  static const double _minMoveDistance = 15; // meters
  static const int _bufferSize = 6;

  final _distance = const osm.Distance();

  // ============================================================
  // MAP INIT
  // ============================================================

  Future<void> _onStyleLoaded() async {
    print("Ham Nay Dc Goi");
    _annotationManager =
    await _map!.annotations.createPointAnnotationManager();

    // await _addRouteLayer();
    // _listenRealtime();
    await _addRouteLayer();
    await _loadFakeHistory();

  }

  Future<void> _loadFakeHistory() async {
    final fakeHistory =
    context.read<ParentLocationVm>()
        .generateFakeHoTayHistory();

    final engine = HistorySnapEngine();

    final result =
    await engine.snapHistory(fakeHistory);

    if (result.snappedPoints.isEmpty) {
      debugPrint("❌ SNAP FAIL");
      return;
    }
    debugPrint("SNAPPED LENGTH: ${result.snappedPoints.length}");

    _trail
      ..clear()
      ..addAll(result.snappedPoints);

    await _updateRoute();
    await _fitCameraToRoute();

    debugPrint("✅ SNAP OK");
    debugPrint("Distance: ${result.totalDistanceKm} km");
    debugPrint("Fallback used: ${result.usedFallback}");
  }
  // Production
  Future<void> _loadHistory() async {
    final engine = HistorySnapEngine();

    final history =
    await context.read<ParentLocationVm>()
        .loadLocationHistory(widget.childId);

    final result =
    await engine.snapHistory(history);

    _trail
      ..clear()
      ..addAll(result.snappedPoints);

    await _updateRoute();
    await _fitCameraToRoute();

    debugPrint("Distance: ${result.totalDistanceKm}");
    debugPrint("Fallback used: ${result.usedFallback}");
  }
  Future<void> _fitCameraToRoute() async {
    if (_trail.isEmpty) return;

    double minLat = _trail.first.latitude;
    double maxLat = _trail.first.latitude;
    double minLng = _trail.first.longitude;
    double maxLng = _trail.first.longitude;

    for (final p in _trail) {
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
    await _map!.cameraForCoordinateBounds(
      bounds,
      MbxEdgeInsets(
        top: 100,
        left: 50,
        bottom: 100,
        right: 50,
      ),
      null,
      null,
      null,
      null
    );

    await _map!.easeTo(
      cameraOptions,
      MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> _addRouteLayer() async {
    debugPrint("TRAIL LENGTH: ${_trail.length}");

    await _map!.style.addSource(
      GeoJsonSource(
        id: "route-source",
        data: jsonEncode({
          "type": "FeatureCollection",
          "features": []
        }),
      ),
    );

    await _map!.style.addLayer(
      LineLayer(
        id: "route-layer",
        sourceId: "route-source",
        lineWidth: 6.0,
        lineColor: 0xFF1976D2,
      ),
    );
  }

  Future<void> _updateRoute() async {
    debugPrint("TRAIL LENGTH: ${_trail.length}");

    if (_trail.length < 2) return;

    final geoJson = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": _trail
                .map((p) => [p.longitude, p.latitude])
                .toList(),
          }
        }
      ]
    };

    final source =
    await _map!.style.getSource("route-source")
    as GeoJsonSource;

    await source.updateGeoJSON(jsonEncode(geoJson));
  }

  // ============================================================
  // REALTIME LISTENER
  // ============================================================

  void _listenRealtime() {
    final vm =
    context.read<ParentLocationVm>();

    _sub = vm
        .watchChildLocation(widget.childId)
        .listen((loc) async {

      final newPoint =
      osm.LatLng(loc.latitude, loc.longitude);
      print("NEW LOCATION");

      // Lọc nhiễu
      if (_trail.isNotEmpty) {
        final d = _distance(
            _trail.last,
            newPoint);

        if (d < _minMoveDistance) {
          return; // bỏ qua di chuyển quá nhỏ
        }
      }

      _buffer.add(newPoint);

      if (_buffer.length > _bufferSize) {
        _buffer.removeAt(0);
      }

      _debounce?.cancel();
      _debounce = Timer(
          const Duration(seconds: 3),
              () async {
                print("DEBOUNCE FIRED ${_buffer.length}");

            if (_buffer.length < 2) return;

                final result =
                await MapboxRouteService.snapSegment(_buffer);

                if (result == null ||
                    result.points.length < 2) return;

                _trail.addAll(result.points);


                await _updateRoute();

            final heading =
            _calculateHeading(
                _trail[_trail.length - 2],
                _trail.last);

            await _updateMarker(
                _trail.last,
                heading);

            if (_autoFollow) {
              await _map!.easeTo(
                CameraOptions(
                  center: Point(
                    coordinates: Position(
                      _trail.last.longitude,
                      _trail.last.latitude,
                    ),
                  ),
                  zoom: 17,
                  pitch: 45,
                  bearing: heading,
                ),
                MapAnimationOptions(duration: 800),
              );
            }

            _buffer.clear();
          });
    });
  }

  // ============================================================
  // MARKER
  // ============================================================

  Future<void> _updateMarker(
      osm.LatLng p,
      double heading) async {

    final point = Point(
      coordinates:
      Position(p.longitude, p.latitude),
    );

    if (_marker == null) {
      _marker =
      await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: point,
          iconSize: 1.2,
          iconRotate: heading,
        ),
      );
    } else {
      _marker!.geometry = point;
      _marker!.iconRotate = heading;
      await _annotationManager!.update(_marker!);
    }
  }

  // ============================================================
  // HEADING
  // ============================================================

  double _calculateHeading(
      osm.LatLng from,
      osm.LatLng to) {

    final dLon =
        (to.longitude - from.longitude) *
            pi / 180;

    final lat1 =
        from.latitude * pi / 180;
    final lat2 =
        to.latitude * pi / 180;

    final y =
        sin(dLon) * cos(lat2);
    final x =
        cos(lat1) * sin(lat2) -
            sin(lat1) *
                cos(lat2) *
                cos(dLon);

    return atan2(y, x) * 180 / pi;
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking ${widget.childId}"),
        actions: [
          IconButton(
            icon: Icon(
              _autoFollow
                  ? Icons.gps_fixed
                  : Icons.gps_not_fixed,
            ),
            onPressed: () {
              setState(() {
                _autoFollow = !_autoFollow;
              });
            },
          ),
        ],
      ),
      body: AppMapView(
        onMapCreated: (map) {
          _map = map;
        },
        onStyleLoaded: () async {
          await _onStyleLoaded();
        },
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
