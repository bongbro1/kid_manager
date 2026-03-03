import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/location/location_data.dart';

class HistoryRenderer {
  final MapboxMap map;
  bool _visible = false; // ✅ mặc định ẩn

  HistoryRenderer(this.map);

  Future<void> init({bool visible = false}) async {
    _visible = visible;
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
        circleRadiusExpression: const [
          "interpolate",
          ["linear"],
          ["zoom"],
          10, 4,
          14, 6,
          17, 9,
        ],
        circleColor: 0xFFFF5722,
        circleStrokeWidth: 1,
        circleStrokeColor: 0xFFFFFFFF,
        // ✅ mặc định ẩn
        visibility: visible ? Visibility.VISIBLE : Visibility.NONE,
      ),
    );
  }

  /// ✅ bật/tắt hiển thị dot
  Future<void> setVisible(bool visible) async {
    _visible = visible;
    final style = map.style;

    final layer = await style.getLayer("history-layer");
    if (layer is CircleLayer) {
      layer.visibility = visible ? Visibility.VISIBLE : Visibility.NONE;
      await style.updateLayer(layer);
    }
  }

  bool get isVisible => _visible;

  Future<void> render(List<LocationData> history) async {
    final geo = {
      "type": "FeatureCollection",
      "features": history.map((e) {
        return {
          "type": "Feature",
          "properties": {"timestamp": e.timestamp},
          "geometry": {
            "type": "Point",
            "coordinates": [e.longitude, e.latitude]
          }
        };
      }).toList()
    };

    final source = await map.style.getSource("history-source") as GeoJsonSource;
    await source.updateGeoJSON(jsonEncode(geo));
  }
}