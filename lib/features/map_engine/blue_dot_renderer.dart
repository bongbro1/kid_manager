import 'dart:convert';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:kid_manager/models/location/location_data.dart';

class BlueDotRenderer {
  final MapboxMap map;
  BlueDotRenderer(this.map);

  static const _srcId = "blue-dot-source";
  static const _accLayerId = "blue-dot-accuracy";
  static const _dotLayerId = "blue-dot-dot";
  static const _haloLayerId = "blue-dot-halo";

  Future<void> init() async {
    final style = map.style;

    // source: 1 point
    await style.addSource(
      GeoJsonSource(
        id: _srcId,
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );

    // 1) Accuracy circle (radius theo accuracy meters)
    // Mapbox CircleLayer radius tính theo pixel, nhưng có thể dùng circleRadiusExpression
    // dùng Expression.interpolate theo zoom để scale (đơn giản, nhìn giống GG)
    await style.addLayer(
      CircleLayer(
        id: _accLayerId,
        sourceId: _srcId,
        circleColor: 0x332196F3, // xanh nhạt (alpha ~ 0x33)
        circleStrokeColor: 0x552196F3,
        circleStrokeWidth: 1.0,
        circleOpacity: 1.0,
        circleRadiusExpression: [
          "interpolate",
          ["linear"],
          ["zoom"],
          12, ["*", ["get", "acc"], 0.10], // zoom 12: acc*0.10 px
          16, ["*", ["get", "acc"], 0.25], // zoom 16: acc*0.25 px
          18, ["*", ["get", "acc"], 0.35], // zoom 18
        ],
      ),
    );

    // 2) Halo
    await style.addLayer(
      CircleLayer(
        id: _haloLayerId,
        sourceId: _srcId,
        circleColor: 0x552196F3,
        circleOpacity: 0.35,
        circleRadius: 18.0,
      ),
    );

    // 3) Blue dot (chấm xanh + viền trắng)
    await style.addLayer(
      CircleLayer(
        id: _dotLayerId,
        sourceId: _srcId,
        circleColor: 0xFF2196F3,
        circleRadius: 7.0,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2.0,
      ),
    );
  }

  Future<void> update(LocationData loc) async {
    final feature = {
      "type": "Feature",
      "properties": {
        "acc": loc.accuracy.clamp(0, 200), // dùng cho accuracy circle
      },
      "geometry": {
        "type": "Point",
        "coordinates": [loc.longitude, loc.latitude],
      }
    };

    final geo = {
      "type": "FeatureCollection",
      "features": [feature],
    };

    final source = await map.style.getSource(_srcId) as GeoJsonSource;
    await source.updateGeoJSON(jsonEncode(geo));
  }
}