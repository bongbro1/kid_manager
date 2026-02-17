import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as osm;

import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/services/location/mapbox_route_service.dart';
import 'package:kid_manager/core/map/gps_optimizer.dart';

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
  StreamSubscription? _sub;

  bool _autoFollow = true;

  // ============================================================
  // MAP CREATED
  // ============================================================

  void _onMapCreated(MapboxMap mapboxMap) async {
    _map = mapboxMap;


    // Bây giờ style chắc chắn đã sẵn sàng

    _annotationManager =
    await _map!.annotations
        .createPointAnnotationManager();

    await _addRouteLayer();

    await _loadHistory();

    _listenRealtime();
  }


  // ============================================================
  // ROUTE LAYER
  // ============================================================

  Future<void> _addRouteLayer() async {

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
        lineColor: 0xFF2196F3,
      ),
    );
  }

  Future<void> _updateRoute() async {
    print("TRAIL LENGTH: ${_trail.length}");

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
  // MARKER
  // ============================================================

  Future<void> _updateMarker(
      osm.LatLng p,
      double heading) async {

    if (_annotationManager == null) return;

    final point = Point(
      coordinates:
      Position(p.longitude, p.latitude),
    );

    if (_marker == null) {

      _marker = await _annotationManager!
          .create(
        PointAnnotationOptions(
          geometry: point,
          iconSize: 1.2,
          iconRotate: heading,
        ),
      );

    } else {

      _marker!.geometry = point;
      _marker!.iconRotate = heading;

      await _annotationManager!
          .update(_marker!);
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _listenRealtime() {
    final vm =
    context.read<ParentLocationVm>();

    _sub = vm
        .watchChildLocation(widget.childId)
        .listen((loc) async {

      final newPoint =
      osm.LatLng(loc.latitude, loc.longitude);

      if (_trail.isEmpty) {
        _trail.add(newPoint);
        await _updateRoute();
        return;
      }

      final snapped =
      await MapboxRouteService
          .snapSegment([_trail.last, newPoint]);

      if (snapped == null ||
          snapped.isEmpty) return;

      _trail.addAll(snapped);

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
    });
  }

  // ============================================================
  // LOAD HISTORY
  // ============================================================

  Future<void> _loadHistory() async {

    print("USING TEST DATA");

    _trail.clear();

    _trail.addAll([

      // 1️⃣ Thanh Niên - gần Trấn Quốc
      osm.LatLng(21.04818, 105.83632),
      osm.LatLng(21.04905, 105.83728),
      osm.LatLng(21.05012, 105.83846),

      // 2️⃣ Trích Sài
      osm.LatLng(21.05180, 105.84090),
      osm.LatLng(21.05360, 105.84360),
      osm.LatLng(21.05520, 105.84620),

      // 3️⃣ Lạc Long Quân
      osm.LatLng(21.05630, 105.84890),
      osm.LatLng(21.05655, 105.85140),
      osm.LatLng(21.05610, 105.85410),

      // 4️⃣ Xuân La
      osm.LatLng(21.05490, 105.85660),
      osm.LatLng(21.05320, 105.85830),
      osm.LatLng(21.05130, 105.85910),

      // 5️⃣ Nhật Chiêu
      osm.LatLng(21.04940, 105.85870),
      osm.LatLng(21.04760, 105.85780),

      // 6️⃣ Quảng An
      osm.LatLng(21.04600, 105.85570),
      osm.LatLng(21.04500, 105.85330),

      // 7️⃣ Yên Phụ
      osm.LatLng(21.04540, 105.84960),
      osm.LatLng(21.04680, 105.84620),
      osm.LatLng(21.04790, 105.84290),

      // 🔁 Đóng vòng
      osm.LatLng(21.04818, 105.83632),

    ]);

    await _updateRoute();

    await _map?.easeTo(
      CameraOptions(
        center: Point(
          coordinates: Position(
            _trail.last.longitude,
            _trail.last.latitude,
          ),
        ),
        zoom: 16,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

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
        title:
        Text("Lịch sử ${widget.childId}"),
        actions: [
          IconButton(
            icon: Icon(
              _autoFollow
                  ? Icons.gps_fixed
                  : Icons.gps_not_fixed,
            ),
            onPressed: () {
              setState(() {
                _autoFollow =
                !_autoFollow;
              });
            },
          ),
        ],
      ),
      body: MapWidget(
        styleUri: "mapbox://styles/mapbox/streets-v12",
        onMapCreated: (mapboxMap) {
          _map = mapboxMap;
        },
        onStyleLoadedListener: (event) async {
          print("STYLE READY");

          _annotationManager =
          await _map!.annotations.createPointAnnotationManager();

          await _addRouteLayer();
          await _loadHistory();
          _listenRealtime();
        },
      ),

    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
