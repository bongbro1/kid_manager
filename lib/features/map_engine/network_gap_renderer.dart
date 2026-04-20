import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/features/map_engine/services/history_gap_detector.dart';
import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class NetworkGapRenderer {
  final MapboxMap map;

  NetworkGapRenderer(this.map);

  Future<void> init() async {
    final style = map.style;

    await _addSourceIfNeeded(
      style,
      GeoJsonSource(
        id: 'network-gap-line-source',
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );
    await _addLayerIfNeeded(
      style,
      LineLayer(
        id: 'network-gap-line-layer',
        sourceId: 'network-gap-line-source',
        lineWidth: 4,
        lineColor: 0xFFF57C00,
        lineOpacity: 0.88,
      ),
    );

    await _addSourceIfNeeded(
      style,
      GeoJsonSource(
        id: 'network-gap-marker-source',
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );
    await _addLayerIfNeeded(
      style,
      CircleLayer(
        id: 'network-gap-marker-layer',
        sourceId: 'network-gap-marker-source',
        circleRadius: 7,
        circleColor: 0xFFF57C00,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );
  }

  Future<void> render(List<HistoryGap> gaps) async {
    final lineSource = await _getGeoJsonSource('network-gap-line-source');
    final markerSource = await _getGeoJsonSource('network-gap-marker-source');
    if (lineSource == null || markerSource == null) {
      if (kDebugMode) {
        debugPrint('Skip network gap render: style source not ready');
      }
      return;
    }

    try {
      if (gaps.isEmpty) {
        await lineSource.updateGeoJSON(
          '{"type":"FeatureCollection","features":[]}',
        );
        await markerSource.updateGeoJSON(
          '{"type":"FeatureCollection","features":[]}',
        );
        return;
      }

      await lineSource.updateGeoJSON(
        jsonEncode({
          'type': 'FeatureCollection',
          'features': gaps
              .map(
                (gap) => {
                  'type': 'Feature',
                  'properties': {
                    'kind': 'network_gap',
                    'gapDurationMs': gap.marker.gapDurationMs,
                  },
                  'geometry': {
                    'type': 'LineString',
                    'coordinates': [
                      [gap.start.longitude, gap.start.latitude],
                      [gap.end.longitude, gap.end.latitude],
                    ],
                  },
                },
              )
              .toList(),
        }),
      );

      await markerSource.updateGeoJSON(
        jsonEncode({
          'type': 'FeatureCollection',
          'features': gaps
              .map(
                (gap) => {
                  'type': 'Feature',
                  'properties': {
                    'kind': 'network_gap_marker',
                    'timestamp': gap.marker.timestamp,
                    'gapDurationMs': gap.marker.gapDurationMs,
                  },
                  'geometry': {
                    'type': 'Point',
                    'coordinates': [gap.marker.longitude, gap.marker.latitude],
                  },
                },
              )
              .toList(),
        }),
      );
    } catch (error) {
      if (_isDetachedChannelError(error) || _isMissingSourceError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> clear() => render(const []);

  Future<void> _addSourceIfNeeded(
    StyleManager style,
    GeoJsonSource source,
  ) async {
    try {
      final exists = await style.styleSourceExists(source.id);
      if (!exists) {
        await style.addSource(source);
      }
    } catch (error) {
      if (_isAlreadyExistsError(error) || _isDetachedChannelError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> _addLayerIfNeeded(StyleManager style, Layer layer) async {
    try {
      final exists = await style.styleLayerExists(layer.id);
      if (!exists) {
        await style.addLayer(layer);
      }
    } catch (error) {
      if (_isAlreadyExistsError(error) || _isDetachedChannelError(error)) {
        return;
      }
      rethrow;
    }
  }

  Future<GeoJsonSource?> _getGeoJsonSource(String sourceId) async {
    try {
      final styleLoaded = await map.style.isStyleLoaded();
      if (!styleLoaded) {
        return null;
      }
      final exists = await map.style.styleSourceExists(sourceId);
      if (!exists) {
        return null;
      }
      final source = await map.style.getSource(sourceId);
      return source is GeoJsonSource ? source : null;
    } catch (error) {
      if (_isDetachedChannelError(error) || _isMissingSourceError(error)) {
        return null;
      }
      rethrow;
    }
  }

  bool _isAlreadyExistsError(Object error) {
    if (error is! PlatformException) {
      return false;
    }
    final message = (error.message ?? '').toLowerCase();
    return message.contains('already exists');
  }

  bool _isDetachedChannelError(Object error) {
    if (isMapLifecycleError(error)) {
      return true;
    }
    if (error is! PlatformException) {
      return false;
    }
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('channel-error') ||
        message.contains('unable to establish connection on channel');
  }

  bool _isMissingSourceError(Object error) {
    if (error is! PlatformException) {
      return false;
    }
    final message = (error.message ?? '').toLowerCase();
    return message.contains('is not in style') ||
        message.contains('source') && message.contains('not found');
  }
}
