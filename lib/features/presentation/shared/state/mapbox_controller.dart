import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

class MapboxController extends ChangeNotifier {
  mbx.MapboxMap? _map;
  bool _styleReady = false;
  bool get isReady => _styleReady;

  Timer? _debounce;

  /// Cache avatar bytes theo id (child uid)
  final Map<String, Uint8List> _avatarCache = {};

  /// Lưu positions hiện tại để zoomToChild
  final Map<String, mbx.Position> _currentPositions = {};

  /// Track style images đã add cho style hiện tại (vì v2.18.0 không có styleImageExists)
  final Set<String> _addedStyleImages = <String>{};

  static const String defaultAvatarId = "default_avatar_location";

  // ================= ATTACH / DETACH =================

  void attach(mbx.MapboxMap map) {
    _map = map;
  }

  void detach() {
    _debounce?.cancel();
    _styleReady = false;

    // style thay đổi -> images coi như mất
    _addedStyleImages.clear();

    _map = null;
    notifyListeners();
  }

  // ================= UPDATE (debounce) =================

  void scheduleUpdate({
    required Map<String, mbx.Position> positions,
    required Map<String, double> headings,
    required Map<String, String> names,
  }) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 60), () {
      updateChildren(
        positions: positions,
        headings: headings,
        names: names,
      );
    });
  }

  // ================= STYLE =================

  Future<void> onStyleLoaded() async {
    final map = _map;
    if (map == null) return;

    // style mới -> images cũ không còn
    _addedStyleImages.clear();

    // 5) NAME layer (đẹp + rõ + to)
    // 5) NAME layer (đẹp + rõ + to)
    final hasNameLayer = await map.style.styleLayerExists("name-layer");
    if (!hasNameLayer) {
      await map.style.addLayer(
        mbx.SymbolLayer(
          id: "name-layer",
          sourceId: "children-source",
          filter: ["!", ["has", "point_count"]],

          // text
          textFieldExpression: ["get", "name"],
          textSize: 15,                 // ✅ to hơn
          textColor: 0xFF111111,

          // halo để nổi trên map
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 3.0,
          textHaloBlur: 0.4,

          // luôn hiện
          textAllowOverlap: true,
          textIgnorePlacement: true,


          textOffset: [0, -2.8],
          // (nếu muốn cao hơn nữa: -3.2 hoặc -3.6)
        ),
      );
    }
    // 1) Source
    final hasSource = await map.style.styleSourceExists("children-source");
    if (!hasSource) {
      await map.style.addSource(
        mbx.GeoJsonSource(
          id: "children-source",
          cluster: true,
          clusterRadius: 60,
          clusterMaxZoom: 14,
          data: jsonEncode({"type": "FeatureCollection", "features": []}),
        ),
      );
    }

    // 2) Cluster circle
    final hasClusterLayer = await map.style.styleLayerExists("cluster-layer");
    if (!hasClusterLayer) {
      await map.style.addLayer(
        mbx.CircleLayer(
          id: "cluster-layer",
          sourceId: "children-source",
          filter: ["has", "point_count"],
          circleRadius: 26,
          circleColor: 0xFF1976D2,
        ),
      );
    }

    // 3) Cluster count text
    final hasClusterCount = await map.style.styleLayerExists("cluster-count");
    if (!hasClusterCount) {
      await map.style.addLayer(
        mbx.SymbolLayer(
          id: "cluster-count",
          sourceId: "children-source",
          filter: ["has", "point_count"],
          textField: "{point_count}",
          textSize: 14,
          textColor: 0xFFFFFFFF,
        ),
      );
    }

    // 4) Children layer (non-cluster)
    final hasChildrenLayer = await map.style.styleLayerExists("children-layer");
    if (!hasChildrenLayer) {
      await map.style.addLayer(
        mbx.SymbolLayer(
          id: "children-layer",
          sourceId: "children-source",
          filter: ["!", ["has", "point_count"]],
          iconImageExpression: ["get", "avatar_id"],
          iconSizeExpression: [
            "interpolate",
            ["linear"],
            ["zoom"],
            5, 0.6,
            10, 0.9,
            16, 1.2
          ],
          iconRotateExpression: ["get", "heading"],
          // iconAllowOverlap: true,
          // textFieldExpression: ["get", "name"],
          // textSize: 12,
          // textOffset: [0, 2],
          // textColor: 0xFF000000,
          // textAllowOverlap: true,
        ),
      );
    }

    _styleReady = true;
    notifyListeners();
  }

  // ================= IMAGE HELPERS (dart:ui) =================


  // ================= DEFAULT AVATAR =================

  Future<void> setDefaultAvatar(Uint8List encodedBytes) async {
    final map = _map;
    if (map == null) return;

    // tránh add lại
    if (_addedStyleImages.contains(defaultAvatarId)) return;

    try {
      final size = await _decodeSize(encodedBytes);
      if (size == null) return;

      // chờ style loaded
      for (int attempt = 1; attempt <= 3; attempt++) {
        final loaded = await map.style.isStyleLoaded();
        if (!loaded) {
          await Future.delayed(const Duration(milliseconds: 120));
          continue;
        }

        await map.style.addStyleImage(
          defaultAvatarId,
          1.0,
          mbx.MbxImage(
            width: size.w,
            height: size.h,
            data: encodedBytes, // ✅ PNG/JPG/WebP bytes
          ),
          false,
          [],
          [],
          null,
        );

        _addedStyleImages.add(defaultAvatarId);
        debugPrint("✅ DEFAULT AVATAR ADDED (ENCODED) w=${size.w} h=${size.h}");
        return;
      }
    } catch (e, st) {
      debugPrint("🔥 setDefaultAvatar(ENCODED) FAILED: $e");
      debugPrint("$st");
    }
  }

  Future<({int w, int h})?> _decodeSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      return (w: img.width, h: img.height);
    } catch (e) {
      debugPrint("🔥 _decodeSize failed: $e");
      return null;
    }
  }
  // ================= PRELOAD AVATARS =================

  Future<void> preloadAvatars(Map<String, Uint8List> avatars) async {
    final map = _map;
    if (map == null) return;

    for (final e in avatars.entries) {
      final id = e.key;
      final bytes = e.value;

      if (_addedStyleImages.contains(id)) continue;

      try {
        final size = await _decodeSize(bytes);
        if (size == null) continue;

        await map.style.addStyleImage(
          id,
          1.0,
          mbx.MbxImage(width: size.w, height: size.h, data: bytes), // ✅ encoded
          false,
          [],
          [],
          null,
        );

        _addedStyleImages.add(id);
        _avatarCache[id] = bytes;
        debugPrint("✅ avatar $id added w=${size.w} h=${size.h}");
      } catch (err) {
        debugPrint("🔥 preload avatar $id failed: $err");
      }
    }
  }

  // ================= UPDATE SOURCE =================

  Future<void> updateChildren({
    required Map<String, mbx.Position> positions,
    required Map<String, double> headings,
    required Map<String, String> names,
  }) async {
    final map = _map;
    if (map == null || !_styleReady) return;

    _currentPositions
      ..clear()
      ..addAll(positions);

    final features = positions.entries.map((entry) {
      final id = entry.key;
      final pos = entry.value;

      // Nếu chưa có avatar riêng thì dùng defaultAvatarId
      final avatarId = _avatarCache.containsKey(id) ? id : defaultAvatarId;

      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [pos.lng, pos.lat],
        },
        "properties": {
          "id": id,
          "avatar_id": avatarId,
          "heading": headings[id] ?? 0,
          "name": names[id] ?? "",
        }
      };
    }).toList();

    final source = await map.style.getSource("children-source");
    if (source is mbx.GeoJsonSource) {
      await source.updateGeoJSON(
        jsonEncode({
          "type": "FeatureCollection",
          "features": features,
        }),
      );
    }
  }

  // ================= CAMERA =================

  Future<int> zoomToChild(String childId) async {
    final map = _map;
    if (map == null) return 0;

    final pos = _currentPositions[childId];
    if (pos == null) return 0;

    const duration = 900;

    // easeTo mượt hơn flyTo, ít “bay từ trái đất”
    await map.easeTo(
      mbx.CameraOptions(
        center: mbx.Point(coordinates: pos),
        zoom: 17,
        pitch: 30,
      ),
      mbx.MapAnimationOptions(duration: duration),
    );

    return duration;
  }

  Future<void> fitPoints(List<mbx.Position> positions) async {
    final map = _map;
    if (map == null || positions.isEmpty) return;

    num minLat = positions.first.lat;
    num maxLat = positions.first.lat;
    num minLng = positions.first.lng;
    num maxLng = positions.first.lng;

    for (final p in positions) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    // setCamera: không “bay từ ngoài không gian”
    await map.setCamera(
      mbx.CameraOptions(
        center: mbx.Point(
          coordinates: mbx.Position(
            (minLng + maxLng) / 2,
            (minLat + maxLat) / 2,
          ),
        ),
        zoom: 13,
      ),
    );
  }
}