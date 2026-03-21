import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/models/location/location_data.dart';
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

  Future<void> init() async {
    final style = map.style;

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

    await _addMarkerStyleImage(
      _defaultMarkerIconId,
      photoUrlOrData: null,
    );

    final trimmedAvatarUrl = avatarUrl?.trim() ?? '';
    if (trimmedAvatarUrl.isNotEmpty) {
      await _addMarkerStyleImage(
        _avatarMarkerIconId,
        photoUrlOrData: trimmedAvatarUrl,
      );
      _resolvedMarkerIconId = _avatarMarkerIconId;
    }

    await style.addLayer(
      SymbolLayer(
        id: _markerLayerId,
        sourceId: _srcId,
        iconImageExpression: ['get', _markerIconProperty],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconAnchor: IconAnchor.CENTER,
        iconSize: 1.0,
      ),
    );
  }

  Future<void> _addMarkerStyleImage(
    String iconId, {
    required String? photoUrlOrData,
  }) async {
    final markerImage = await MapAvatarMarkerFactory.build(
      photoUrlOrData: photoUrlOrData,
      accentColor: const Color(0xFF2196F3),
      size: 68,
    );
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
      if (error is! PlatformException ||
          !(error.message?.contains('already exists') ?? false)) {
        rethrow;
      }
    }
  }

  Future<void> update(LocationData loc) async {
    final last = _last;
    if (last != null) {
      final distMeters = last.distanceTo(loc) * 1000.0;
      final accuracyDelta = (last.accuracy - loc.accuracy).abs();
      if (distMeters < 1.5 && accuracyDelta < 2) {
        return;
      }
    }
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
    final source = await map.style.getSource(_srcId) as GeoJsonSource;
    await source.updateGeoJSON(jsonEncode(geoJson));
  }
}
