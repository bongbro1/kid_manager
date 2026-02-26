import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/location/location_data.dart';

class RouteRenderer {
  final MapboxMap map;

  RouteRenderer(this.map);

  Future<void> init() async {
    final style = map.style;

    await style.addSource(
      GeoJsonSource(
        id: "route-source",
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );

    await style.addLayer(
      LineLayer(
        id: "route-layer",
        sourceId: "route-source",
        lineWidth: 5,
        lineColor: 0xFF1976D2,
      ),
    );
  }

  /// Render theo danh sách tọa độ [lon, lat] đã map-match (bám đường)
  Future<void> renderGeometry(List<List<double>> coords) async {
    if (coords.length < 2) return;

    final geo = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {"type": "LineString", "coordinates": coords},
          "properties": {},
        }
      ],
    };

    final source =
    await map.style.getSource("route-source") as GeoJsonSource;

    await source.updateGeoJSON(jsonEncode(geo));
  }


}