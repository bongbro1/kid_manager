import 'dart:convert';
import 'dart:typed_data';
import 'package:kid_manager/helpers/zone/zone_circle.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'package:kid_manager/models/zones/geo_zone.dart';

class ZoneMapRenderer {
  final mbx.MapboxMap map;

  ZoneMapRenderer(this.map);

  // 2 sources: safe & danger => tránh expression mismatch
  static const _safeSrc = "zones-safe-src";
  static const _dangerSrc = "zones-danger-src";
  static const _safeFill = "zones-safe-fill";
  static const _safeLine = "zones-safe-line";
  static const _dangerFill = "zones-danger-fill";
  static const _dangerLine = "zones-danger-line";

  mbx.PointAnnotationManager? _annoMgr;

  Future<void> ensureLayers() async {
    final style = map.style;

    // sources
    try {
      await style.addSource(
        mbx.GeoJsonSource(id: _safeSrc, data: '{"type":"FeatureCollection","features":[]}'),
      );
    } catch (_) {}
    try {
      await style.addSource(
        mbx.GeoJsonSource(id: _dangerSrc, data: '{"type":"FeatureCollection","features":[]}'),
      );
    } catch (_) {}

    // SAFE fill/line
    try {
      await style.addLayer(
        mbx.FillLayer(
          id: _safeFill,
          sourceId: _safeSrc,
          fillColor: 0x4400C853, // green
          fillOpacity: 0.35,
        ),
      );
    } catch (_) {}
    try {
      await style.addLayer(
        mbx.LineLayer(
          id: _safeLine,
          sourceId: _safeSrc,
          lineWidth: 2.2,
          lineColor: 0xFF00C853,
        ),
      );
    } catch (_) {}

    // DANGER fill/line
    try {
      await style.addLayer(
        mbx.FillLayer(
          id: _dangerFill,
          sourceId: _dangerSrc,
          fillColor: 0x44FF0000, // red
          fillOpacity: 0.35,
        ),
      );
    } catch (_) {}
    try {
      await style.addLayer(
        mbx.LineLayer(
          id: _dangerLine,
          sourceId: _dangerSrc,
          lineWidth: 2.2,
          lineColor: 0xFFFF0000,
        ),
      );
    } catch (_) {}
  }

  Future<void> syncZoneCircles(List<GeoZone> zones) async {
    final safeFeatures = <Map<String, dynamic>>[];
    final dangerFeatures = <Map<String, dynamic>>[];

    for (final z in zones) {
      final ring = circlePolygon(lat: z.lat, lng: z.lng, radiusM: z.radiusM, points: 64);
      final feat = {
        "type": "Feature",
        "properties": {"zoneId": z.id},
        "geometry": {"type": "Polygon", "coordinates": [ring]},
      };
      if (z.type == ZoneType.danger) {
        dangerFeatures.add(feat);
      } else {
        safeFeatures.add(feat);
      }
    }

    final safeGeo = {"type": "FeatureCollection", "features": safeFeatures};
    final dangerGeo = {"type": "FeatureCollection", "features": dangerFeatures};

    final s1 = await map.style.getSource(_safeSrc);
    if (s1 is mbx.GeoJsonSource) {
      await s1.updateGeoJSON(jsonEncode(safeGeo));
    }
    final s2 = await map.style.getSource(_dangerSrc);
    if (s2 is mbx.GeoJsonSource) {
      await s2.updateGeoJSON(jsonEncode(dangerGeo));
    }
  }

  Future<void> ensureAnnoManager() async {
    _annoMgr ??= await map.annotations.createPointAnnotationManager();
  }

  Future<void> syncZoneIcons({
    required List<GeoZone> zones,
    required Uint8List safeIcon,
    required Uint8List dangerIcon,
  }) async {
    await ensureAnnoManager();
    await _annoMgr!.deleteAll();

    for (final z in zones) {
      final img = z.type == ZoneType.danger ? dangerIcon : safeIcon;
      await _annoMgr!.create(
        mbx.PointAnnotationOptions(
          geometry: mbx.Point(coordinates: mbx.Position(z.lng, z.lat)),
          image: img,
          iconSize: 1.0,
        ),
      );
    }
  }
}