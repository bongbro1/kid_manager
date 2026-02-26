import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;
import 'dart:ui' as ui; // Sử dụng ui của Flutter thay vì thư viện image ngoàiimport 'package:image/image.dart' as img;
import 'package:image/image.dart' as img;
class MapboxController extends ChangeNotifier {
  mbx.MapboxMap? _map;
  bool _styleReady = false;
  final Map<String, Uint8List> _avatarCache = {};
  final Map<String, mbx.Position> _currentPositions = {};
  bool get isReady => _styleReady;
  Timer? _debounce;

  static const String defaultAvatarId = "default_avatar";
  // ================= ATTACH =================

  void attach(mbx.MapboxMap map) {
    _map = map;
  }

  void detach() {
    _styleReady = false;

    _map = null;
    notifyListeners();
  }


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
    if (_map == null) return;
    final map = _map!;

    // 1️⃣ Source
    await map.style.addSource(
      mbx.GeoJsonSource(
        id: "children-source",
        cluster: true,
        clusterRadius: 60,
        clusterMaxZoom: 14,
        data: jsonEncode({
          "type": "FeatureCollection",
          "features": [],
        }),
      ),
    );

    // 2️⃣ Cluster circle
    await map.style.addLayer(
      mbx.CircleLayer(
        id: "cluster-layer",
        sourceId: "children-source",
        filter: ["has", "point_count"],
        circleRadius: 26,
        circleColor: 0xFF1976D2,
      ),
    );

    // 3️⃣ Cluster text
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

    // 4️⃣ Avatar layer (NON-CLUSTER)
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
        iconAllowOverlap: true,
        textFieldExpression: ["get", "name"],
        textSize: 12,
        textOffset: [0, 2],
        textColor: 0xFF000000,
        textAllowOverlap: true,
      ),
    );

    _styleReady = true;
    notifyListeners();
  }

  // ================= PRELOAD AVATAR =================

  Future<void> preloadAvatars(Map<String, Uint8List> avatars) async {
    if (_map == null) return;

    for (final entry in avatars.entries) {
      final mbxImg = await _convertToMbxImage(entry.value);
      if (mbxImg != null && _map != null) {
        _avatarCache[entry.key] = entry.value;
        await _map!.style.addStyleImage(entry.key, 1.0, mbxImg, false, [], [], null);
      }
    }
  }



// mapbox_controller.dart

  Future<mbx.MbxImage?> _convertToMbxImage(Uint8List bytes) async {
    // Dùng package 'image' thay vì dart:ui để đảm bảo RGBA đúng format
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    // Chuyển sang RGBA8888
    final rgba = img.Image.from(decoded)..convert(numChannels: 4);
    final rgbaBytes = rgba.getBytes(order: img.ChannelOrder.rgba);

    return mbx.MbxImage(
      width: rgba.width,
      height: rgba.height,
      data: Uint8List.fromList(rgbaBytes),
    );
  }

  Future<void> setDefaultAvatar(Uint8List pngBytes) async {
    if (_map == null) return;
    try {
      // ✅ Decode + convert TRƯỚC, trên Dart isolate
      final decoded = img.decodeImage(pngBytes);
      if (decoded == null) return;

      final rgba = decoded.convert(numChannels: 4);
      final rgbaBytes = Uint8List.fromList(
          rgba.getBytes(order: img.ChannelOrder.rgba)
      );

      // ✅ Đảm bảo gọi trên main thread bằng cách wrap vào Future.microtask
      await Future.microtask(() async {
        if (_map == null) return;

        // Double-check style loaded
        final loaded = await _map!.style.isStyleLoaded();
        if (!loaded) {
          debugPrint("❌ Style chưa load");
          return;
        }

        await _map!.style.addStyleImage(
          defaultAvatarId,
          1.0,
          mbx.MbxImage(
            width: rgba.width,
            height: rgba.height,
            data: rgbaBytes, // raw RGBA
          ),
          false, [], [], null,
        );
        debugPrint("✅ DEFAULT IMAGE ADDED OK");
      });
    } catch (e, stack) {
      debugPrint("🔥 addStyleImage FAILED: $e\n$stack");
    }
  }
  Future<void> updateChildren({
    required Map<String, mbx.Position> positions,
    required Map<String, double> headings,
    required Map<String, String> names,
  }) async {
    if (_map == null || !_styleReady) return;
    _currentPositions
      ..clear()
      ..addAll(positions);
    final features = positions.entries.map((entry) {
      final id = entry.key;
      final pos = entry.value;
      debugPrint("avatar_id used: ${_avatarCache.containsKey(id) ? id : defaultAvatarId}");
      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [pos.lng, pos.lat],
        },
        "properties": {
          "id":id,
          "avatar_id": _avatarCache.containsKey(id)
              ? id
              :defaultAvatarId,
          "heading": headings[id] ?? 0,
          "name": names[id] ?? "",
        }
      };
    }).toList();

    final source = await _map!.style.getSource("children-source");

    if (source is mbx.GeoJsonSource) {
      await source.updateGeoJSON(
        jsonEncode({
          "type": "FeatureCollection",
          "features": features,
        }),
      );
    }
  }

  Future<int> zoomToChild(String childId) async {
    if (_map == null) return 0;

    final pos = _currentPositions[childId];
    if (pos == null) return 0;

    const duration = 1200;

    await _map!.flyTo(
      mbx.CameraOptions(
        center: mbx.Point(coordinates: pos),
        zoom: 17.5,
        pitch: 40,
      ),
      mbx.MapAnimationOptions(duration: duration),
    );

    return duration;
  }

  // ================= FIT =================

  Future<void> fitPoints(List<mbx.Position> positions) async {
    if (_map == null || positions.isEmpty) return;

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

    await _map!.flyTo(
      mbx.CameraOptions(
        center: mbx.Point(
          coordinates: mbx.Position(
            (minLng + maxLng) / 2,
            (minLat + maxLat) / 2,
          ),
        ),
        zoom: 13,
      ),
      mbx.MapAnimationOptions(duration: 1200),
    );
  }
}