import 'dart:convert';

import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class RouteRenderer {
  RouteRenderer(this.map);

  final MapboxMap map;
  int _generation = 0;
  bool _disposed = false;

  bool _isActive(int generation) => !_disposed && generation == _generation;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
  }

  Future<void> init() async {
    if (_disposed) return;
    final generation = _generation;
    final style = map.style;

    if (!await _runSafe(
      generation: generation,
      action: () => style.addSource(
        GeoJsonSource(
          id: 'route-road-source',
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      ),
    )) {
      return;
    }
    if (!await _runSafe(
      generation: generation,
      action: () => style.addLayer(
        LineLayer(
          id: 'route-road-layer',
          sourceId: 'route-road-source',
          lineWidth: 5,
          lineColor: 0xFF1976D2,
        ),
      ),
    )) {
      return;
    }

    if (!await _runSafe(
      generation: generation,
      action: () => style.addSource(
        GeoJsonSource(
          id: 'route-straight-source',
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      ),
    )) {
      return;
    }
    await _runSafe(
      generation: generation,
      action: () => style.addLayer(
        LineLayer(
          id: 'route-straight-layer',
          sourceId: 'route-straight-source',
          lineWidth: 4,
          lineColor: 0xFF90A4AE,
        ),
      ),
    );
  }

  Future<void> renderRoad(List<List<double>> coords) async {
    if (_disposed) return;
    final generation = _generation;
    try {
      final source =
          await map.style.getSource('route-road-source') as GeoJsonSource;
      if (!_isActive(generation)) return;
      if (coords.length < 2) {
        await source.updateGeoJSON(
          '{"type":"FeatureCollection","features":[]}',
        );
        return;
      }
      await source.updateGeoJSON(
        jsonEncode({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {'type': 'LineString', 'coordinates': coords},
              'properties': {'kind': 'road'},
            },
          ],
        }),
      );
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> renderStraightSegments(List<List<List<double>>> segments) async {
    if (_disposed) return;
    final generation = _generation;
    try {
      final source =
          await map.style.getSource('route-straight-source') as GeoJsonSource;
      if (!_isActive(generation)) return;
      if (segments.isEmpty) {
        await source.updateGeoJSON(
          '{"type":"FeatureCollection","features":[]}',
        );
        return;
      }
      await source.updateGeoJSON(
        jsonEncode({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {'type': 'MultiLineString', 'coordinates': segments},
              'properties': {'kind': 'straight'},
            },
          ],
        }),
      );
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> renderGeometry(List<List<double>> coords) => renderRoad(coords);

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
        return false;
      }
      rethrow;
    }
  }
}
