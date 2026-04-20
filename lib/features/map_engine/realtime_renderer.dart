import 'dart:convert';
import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/location/location_data.dart';

class RealtimeRenderer {
  final MapboxMap map;

  RealtimeRenderer(this.map);

  Future<void> init() async {
    final style = map.style;
    try {
      await style.addSource(
        GeoJsonSource(
          id: "current-source",
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      );

      await style.addLayer(
        CircleLayer(
          id: "current-layer",
          sourceId: "current-source",
          circleRadius: 8,
          circleColor: 0xFF2196F3,
          circleStrokeWidth: 2,
          circleStrokeColor: 0xFFFFFFFF,
        ),
      );
    } catch (error) {
      if (isMapLifecycleError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> update(LocationData loc) async {
    final geo = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [loc.longitude, loc.latitude],
          },
        },
      ],
    };

    try {
      final source =
          await map.style.getSource("current-source") as GeoJsonSource;
      await source.updateGeoJSON(jsonEncode(geo));
    } catch (error) {
      if (isMapLifecycleError(error)) {
        return;
      }
      rethrow;
    }
  }
}
