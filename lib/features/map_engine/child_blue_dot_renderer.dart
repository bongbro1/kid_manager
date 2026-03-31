import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:kid_manager/services/location/map_avatar_marker_factory.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class ChildBlueDotRenderer {
  ChildBlueDotRenderer(this.map, {this.avatarUrl});

  final MapboxMap map;
  final String? avatarUrl;

  static const _srcId = 'blue-dot-source';
  static const _accLayerId = 'blue-dot-accuracy';
  static const _haloLayerId = 'blue-dot-halo';
  static const _markerLayerId = 'blue-dot-marker';
  static const _markerIconProperty = 'marker_icon_id';
  static const _defaultMarkerIconId = 'blue-dot-default-icon';
  static const _avatarMarkerIconId = 'blue-dot-avatar-icon';

  LocationData? _last;
  String _resolvedMarkerIconId = _defaultMarkerIconId;
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

    if (!await _safeRun(
      generation: generation,
      action: () => style.addSource(
        GeoJsonSource(
          id: _srcId,
          data: '{"type":"FeatureCollection","features":[]}',
        ),
      ),
    )) {
      return;
    }

    if (!await _safeRun(
      generation: generation,
      action: () => style.addLayer(
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
            [
              '*',
              ['get', 'acc'],
              0.10,
            ],
            16,
            [
              '*',
              ['get', 'acc'],
              0.25,
            ],
            18,
            [
              '*',
              ['get', 'acc'],
              0.35,
            ],
          ],
        ),
      ),
    )) {
      return;
    }

    if (!await _safeRun(
      generation: generation,
      action: () => style.addLayer(
        CircleLayer(
          id: _haloLayerId,
          sourceId: _srcId,
          circleColor: 0x552196F3,
          circleOpacity: 0.35,
          circleRadius: 18.0,
        ),
      ),
    )) {
      return;
    }

    await _addMarkerStyleImage(
      _defaultMarkerIconId,
      photoUrlOrData: null,
      generation: generation,
    );
    if (!_isActive(generation)) return;

    final trimmedAvatarUrl = avatarUrl?.trim() ?? '';
    if (trimmedAvatarUrl.isNotEmpty) {
      await _addMarkerStyleImage(
        _avatarMarkerIconId,
        photoUrlOrData: trimmedAvatarUrl,
        generation: generation,
      );
      if (!_isActive(generation)) return;
      _resolvedMarkerIconId = _avatarMarkerIconId;
    }

    await _safeRun(
      generation: generation,
      action: () => style.addLayer(
        SymbolLayer(
          id: _markerLayerId,
          sourceId: _srcId,
          iconImageExpression: ['get', _markerIconProperty],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1.0,
        ),
      ),
    );
  }

  Future<void> _addMarkerStyleImage(
    String iconId, {
    required String? photoUrlOrData,
    required int generation,
  }) async {
    if (!_isActive(generation)) return;
    final markerImage = await MapAvatarMarkerFactory.build(
      photoUrlOrData: photoUrlOrData,
      accentColor: const Color(0xFF2196F3),
      size: 68,
    );
    if (!_isActive(generation)) return;
    try {
      await map.style.addStyleImage(
        iconId,
        1.0,
        MbxImage(
          width: markerImage.width,
          height: markerImage.height,
          data: markerImage.bytes,
        ),
        false,
        [],
        [],
        null,
      );
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      if (error is! PlatformException ||
          !(error.message?.contains('already exists') ?? false)) {
        rethrow;
      }
    }
  }

  Future<void> update(LocationData loc) async {
    if (_disposed) return;
    final generation = _generation;
    final last = _last;
    if (last != null) {
      final distMeters = last.distanceTo(loc) * 1000.0;
      final accuracyDelta = (last.accuracy - loc.accuracy).abs();
      if (distMeters < 1.5 && accuracyDelta < 2) {
        return;
      }
    }
    if (!_isActive(generation)) return;
    _last = loc;

    final feature = {
      'type': 'Feature',
      'properties': {
        'acc': loc.accuracy.clamp(0, 200),
        _markerIconProperty: _resolvedMarkerIconId,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [loc.longitude, loc.latitude],
      },
    };

    final geoJson = {
      'type': 'FeatureCollection',
      'features': [feature],
    };
    try {
      final source = await map.style.getSource(_srcId) as GeoJsonSource;
      if (!_isActive(generation)) return;
      await source.updateGeoJSON(jsonEncode(geoJson));
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }

  Future<bool> _safeRun({
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
