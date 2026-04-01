import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../models/location/location_data.dart';

class HistoryRenderer {
  HistoryRenderer(this.map);

  final MapboxMap map;
  bool _visible = false;
  int _generation = 0;
  bool _disposed = false;

  bool _isActive(int generation) => !_disposed && generation == _generation;

  bool get isVisible => _visible;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
  }

  Future<void> init({bool visible = false}) async {
    if (_disposed) return;
    final generation = _generation;
    _visible = visible;
    final style = map.style;

    if (!await _runSafe(
      generation: generation,
      action: () => style.addSource(
        GeoJsonSource(
          id: 'history-source',
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      ),
    )) {
      return;
    }

    await _runSafe(
      generation: generation,
      action: () => style.addLayer(
        CircleLayer(
          id: 'history-layer',
          sourceId: 'history-source',
          circleRadiusExpression: const [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            4,
            14,
            6,
            17,
            9,
          ],
          circleColor: 0xFFFF5722,
          circleStrokeWidth: 1,
          circleStrokeColor: 0xFFFFFFFF,
          visibility: visible ? Visibility.VISIBLE : Visibility.NONE,
        ),
      ),
    );
  }

  Future<void> setVisible(bool visible) async {
    if (_disposed) return;
    final generation = _generation;
    _visible = visible;
    final style = map.style;

    try {
      final layer = await style.getLayer('history-layer');
      if (!_isActive(generation)) return;
      if (layer is CircleLayer) {
        layer.visibility = visible ? Visibility.VISIBLE : Visibility.NONE;
        await style.updateLayer(layer);
      }
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> render(List<LocationData> history) async {
    if (_disposed) return;
    final generation = _generation;
    final geo = {
      'type': 'FeatureCollection',
      'features': history
          .map(
            (item) => {
              'type': 'Feature',
              'properties': {'timestamp': item.timestamp},
              'geometry': {
                'type': 'Point',
                'coordinates': [item.longitude, item.latitude],
              },
            },
          )
          .toList(),
    };

    try {
      final source =
          await map.style.getSource('history-source') as GeoJsonSource;
      if (!_isActive(generation)) return;
      await source.updateGeoJSON(jsonEncode(geo));
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }

  Future<bool> _runSafe({
    required int generation,
    required Future<void> Function() action,
  }) async {
    if (!_isActive(generation)) return false;
    try {
      await action();
      return _isActive(generation);
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        if (kDebugMode) {
          debugPrint('Skip stale history renderer map task');
        }
        return false;
      }
      rethrow;
    }
  }
}
