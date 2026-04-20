import 'dart:convert';

import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class BlueDotRenderer {
  final MapboxMap map;

  BlueDotRenderer(this.map);

  static const _srcId = 'blue-dot-source';
  static const _accLayerId = 'blue-dot-accuracy';
  static const _dotLayerId = 'blue-dot-dot';
  static const _haloLayerId = 'blue-dot-halo';

  Future<void> init() async {
    final style = map.style;

    try {
      await style.addSource(
        GeoJsonSource(
          id: _srcId,
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      );

      await style.addLayer(
        CircleLayer(
          id: _accLayerId,
          sourceId: _srcId,
          circleColor: 0x332196F3,
          circleStrokeColor: 0x552196F3,
          circleStrokeWidth: 1.0,
          circleOpacity: 1.0,
          circleRadiusExpression: [
            'interpolate',
            ['linear'],
            ['zoom'],
            12,
            ['*', ['get', 'acc'], 0.10],
            16,
            ['*', ['get', 'acc'], 0.25],
            18,
            ['*', ['get', 'acc'], 0.35],
          ],
        ),
      );

      await style.addLayer(
        CircleLayer(
          id: _haloLayerId,
          sourceId: _srcId,
          circleColor: 0x552196F3,
          circleOpacity: 0.35,
          circleRadius: 18.0,
        ),
      );

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
    } catch (error) {
      if (isMapLifecycleError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> update(LocationData loc) async {
    final feature = {
      'type': 'Feature',
      'properties': {'acc': loc.accuracy.clamp(0, 200)},
      'geometry': {
        'type': 'Point',
        'coordinates': [loc.longitude, loc.latitude],
      },
    };

    final geo = {
      'type': 'FeatureCollection',
      'features': [feature],
    };

    try {
      final source = await map.style.getSource(_srcId) as GeoJsonSource;
      await source.updateGeoJSON(jsonEncode(geo));
    } catch (error) {
      if (isMapLifecycleError(error)) {
        return;
      }
      rethrow;
    }
  }
}
