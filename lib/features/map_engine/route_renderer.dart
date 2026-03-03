import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class RouteRenderer {
  final MapboxMap map;
  RouteRenderer(this.map);

  Future<void> init() async {
    final style = map.style;

    await style.addSource(
      GeoJsonSource(id: "route-road-source", data: '{"type":"FeatureCollection","features":[]}'),
    );
    await style.addLayer(
      LineLayer(
        id: "route-road-layer",
        sourceId: "route-road-source",
        lineWidth: 5,
        lineColor: 0xFF1976D2,
      ),
    );

    await style.addSource(
      GeoJsonSource(id: "route-straight-source", data: '{"type":"FeatureCollection","features":[]}'),
    );
    await style.addLayer(
      LineLayer(
        id: "route-straight-layer",
        sourceId: "route-straight-source",
        lineWidth: 4,
        lineColor: 0xFF90A4AE,
      ),
    );
  }

  Future<void> renderRoad(List<List<double>> coords) async {
    final source = await map.style.getSource("route-road-source") as GeoJsonSource;
    if (coords.length < 2) {
      await source.updateGeoJSON('{"type":"FeatureCollection","features":[]}');
      return;
    }
    await source.updateGeoJSON(jsonEncode({
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coords},
          "properties": {"kind": "road"},
        }
      ],
    }));
  }

  Future<void> renderStraightSegments(List<List<List<double>>> segments) async {
    final source = await map.style.getSource("route-straight-source") as GeoJsonSource;
    if (segments.isEmpty) {
      await source.updateGeoJSON('{"type":"FeatureCollection","features":[]}');
      return;
    }
    await source.updateGeoJSON(jsonEncode({
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "MultiLineString", "coordinates": segments},
          "properties": {"kind": "straight"},
        }
      ],
    }));
  }

  // ✅ alias để code cũ không vỡ
  Future<void> renderGeometry(List<List<double>> coords) => renderRoad(coords);
}