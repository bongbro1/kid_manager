import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/location/location_data.dart';

class HistoryRenderer {
  final MapboxMap map;

  HistoryRenderer(this.map);

  Future<void> init() async {
    final style = map.style;

    await style.addSource(
      GeoJsonSource(
        id: "history-source",
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );

    await style.addLayer(
      CircleLayer(
        id: "history-layer",
        sourceId: "history-source",
        circleRadius: 6,
        circleColor: 0xFFFF5722,
        circleStrokeWidth: 1,
        circleStrokeColor: 0xFFFFFFFF,
      ),
    );
  }

  Future<void> render(List<LocationData> history) async {
    final geo = {
      "type": "FeatureCollection",
      "features": history.map((e) {
        return {
          "type": "Feature",
          "properties": {
            "timestamp": e.timestamp
          },
          "geometry": {
            "type": "Point",
            "coordinates": [e.longitude, e.latitude]
          }
        };
      }).toList()
    };

    final source =
    await map.style.getSource("history-source")
    as GeoJsonSource;

    await source.updateGeoJSON(jsonEncode(geo));
  }
}