import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

class MapboxController extends ChangeNotifier {
  mbx.MapboxMap? _map;
  bool _styleReady = false;
  bool get isReady => _styleReady;

  Timer? _debounce;

  final Map<String, Uint8List> _avatarCache = {}; // childId -> bytes
  final Map<String, Uint8List> _avatarBytesById = {};
  final Map<String, String?> _avatarKeyById = {}; // url/data string

  final Map<String, mbx.Position> _currentPositions = {};
  final Set<String> _addedStyleImages = <String>{};

  static const String defaultAvatarId = "default_avatar_location";
  Map<String, mbx.Position> _lastPositions = {};
  Map<String, double> _lastHeadings = {};
  Map<String, String> _lastNames = {};
  Future<void> _styleQueue = Future.value();

  void attach(mbx.MapboxMap map) {
    _map = map;
  }

  void detach() {
    _debounce?.cancel();
    _styleReady = false;
    _addedStyleImages.clear();
    _map = null;
    notifyListeners();
  }

  void scheduleUpdate({
    required Map<String, mbx.Position> positions,
    required Map<String, double> headings,
    required Map<String, String> names,
  }) {
    // ✅ lưu để refresh khi avatar load xong
    _lastPositions = Map.of(positions);
    _lastHeadings  = Map.of(headings);
    _lastNames     = Map.of(names);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 60), () {
      updateChildren(
        positions: positions,
        headings: headings,
        names: names,
      );
    });
  }


  Future<void> _refreshGeoJsonIfPossible() async {
    if (_lastPositions.isEmpty) return;
    await updateChildren(
      positions: _lastPositions,
      headings: _lastHeadings,
      names: _lastNames,
    );
  }
  Future<T> _enqueueStyle<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _styleQueue = _styleQueue.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Uint8List? _tryDecodeDataUrl(String s) {
    const prefix = 'base64,';
    final idx = s.indexOf(prefix);
    if (!s.startsWith('data:') || idx < 0) return null;
    final b64 = s.substring(idx + prefix.length).trim();
    if (b64.isEmpty) return null;
    return base64Decode(b64);
  }

  Future<Uint8List> _fetchAvatarBytes(String key) async {
    final dataBytes = _tryDecodeDataUrl(key);
    if (dataBytes != null) return dataBytes;

    final uri = Uri.tryParse(key);
    if (uri == null || !(uri.isScheme("http") || uri.isScheme("https"))) {
      throw Exception("invalid url: $key");
    }

    final client = http.Client();
    try {
      final resp = await client.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception("HTTP ${resp.statusCode} len=${resp.bodyBytes.length}");
      }
      if (resp.bodyBytes.isEmpty) throw Exception("empty bytes");
      return resp.bodyBytes;
    } finally {
      client.close();
    }
  }

  Future<({Uint8List png, int w, int h})> _normalizeToPng(Uint8List inputBytes) async {
    // ✅ nhỏ hơn
    const int W = 96;
    const int H = 118;

    const double circleSize = 96;
    const double paddingTop = 4;
    const double pointerH = 16;
    const double border = 3;

    final codec = await ui.instantiateImageCodec(inputBytes);
    final frame = await codec.getNextFrame();
    final src = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final centerX = W / 2.0;
    final circleR = (circleSize / 2.0) - border;
    final circleCenter = ui.Offset(centerX, paddingTop + circleSize / 2.0);

    // shadow
    final shadowPaint = ui.Paint()
      ..isAntiAlias = true
      ..color = const ui.Color(0x33000000);
    canvas.drawCircle(circleCenter.translate(0, 3), circleR + 2, shadowPaint);

    final shadowPath = ui.Path()
      ..moveTo(centerX - 10, paddingTop + circleSize - 3)
      ..lineTo(centerX + 10, paddingTop + circleSize - 3)
      ..lineTo(centerX, paddingTop + circleSize + pointerH)
      ..close();
    canvas.drawPath(shadowPath.shift(const ui.Offset(0, 3)), shadowPaint);

    // ✅ nền đỏ
    final bubblePaint = ui.Paint()
      ..isAntiAlias = true
      ..color = const ui.Color(0xFFE53935); // đỏ đẹp (Material Red 600)

    canvas.drawCircle(circleCenter, circleR + border, bubblePaint);

    final pointerPath = ui.Path()
      ..moveTo(centerX - 12, paddingTop + circleSize - 4)
      ..lineTo(centerX + 12, paddingTop + circleSize - 4)
      ..lineTo(centerX, paddingTop + circleSize + pointerH)
      ..close();
    canvas.drawPath(pointerPath, bubblePaint);

    // clip circle vẽ avatar
    final clipPath = ui.Path()
      ..addOval(ui.Rect.fromCircle(center: circleCenter, radius: circleR));
    canvas.save();
    canvas.clipPath(clipPath);

    final paint = ui.Paint()
      ..isAntiAlias = true
      ..filterQuality = ui.FilterQuality.high;

    final dstRect = ui.Rect.fromCircle(center: circleCenter, radius: circleR);
    final srcRect = _centerCropRect(src.width.toDouble(), src.height.toDouble());
    canvas.drawImageRect(src, srcRect, dstRect, paint);
    canvas.restore();

    // viền trắng mỏng cho nổi trên nền đỏ
    final borderPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = border
      ..color = const ui.Color(0xFFFFFFFF)
      ..isAntiAlias = true;
    canvas.drawCircle(circleCenter, circleR + border / 2, borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(W, H);

    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception("toByteData(png) == null");
    debugPrint("normalize -> outW=$W outH=$H");
    return (png: bd.buffer.asUint8List(), w: W, h: H);
  }

  /// center-crop để fill hết khung vuông mà không méo hình
  ui.Rect _centerCropRect(double w, double h) {
    if (w == 0 || h == 0) return ui.Rect.zero;

    if (w > h) {
      final left = (w - h) / 2.0;
      return ui.Rect.fromLTWH(left, 0, h, h);
    } else {
      final top = (h - w) / 2.0;
      return ui.Rect.fromLTWH(0, top, w, w);
    }
  }

  Future<void> _addPngStyleImageIfNeeded(String id, Uint8List anyEncodedBytes) async {
    final map = _map;
    if (map == null) return;
    if (_addedStyleImages.contains(id)) return;

    await _enqueueStyle(() async {
      final mapNow = _map;
      if (mapNow == null) return;

      for (int attempt = 1; attempt <= 5; attempt++) {
        if (_map == null) return; // detach giữa chừng

        final loaded = await mapNow.style.isStyleLoaded();
        if (!loaded) {
          await Future.delayed(const Duration(milliseconds: 120));
          continue;
        }

        try {
          final norm = await _normalizeToPng(anyEncodedBytes);

          await mapNow.style.addStyleImage(
            id,
            1.0,
            mbx.MbxImage(width: norm.w, height: norm.h, data: norm.png), //  PNG bytes
            false,
            [],
            [],
            null,
          );

          _addedStyleImages.add(id);
          debugPrint("✅ addStyleImage OK id=$id w=${norm.w} h=${norm.h}");
          return;
        } catch (e) {
          debugPrint("⚠️ addStyleImage fail id=$id attempt=$attempt err=$e");
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }

      throw Exception("addStyleImage failed after retries id=$id");
    });
  }

  // ================= STYLE =================

  Future<void> onStyleLoaded() async {
    final map = _map;
    if (map == null) return;

    _addedStyleImages.clear();

    // Source FIRST
    if (!await map.style.styleSourceExists("children-source")) {
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

    // Icon layer
    if (!await map.style.styleLayerExists("children-layer")) {
      await map.style.addLayer(
        mbx.SymbolLayer(
          id: "children-layer",
          sourceId: "children-source",
          filter: ["!", ["has", "point_count"]],
          iconImageExpression: ["get", "avatar_id"],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconAnchor: mbx.IconAnchor.BOTTOM,
          iconOffset: [0, 0],
          iconSizeExpression: [
            "interpolate",
            ["linear"],
            ["zoom"],
            5, 0.28,
            10, 0.32,
            16, 0.35,
            18, 0.35,
          ],
        ),
      );
    }

    // Name layer
    if (!await map.style.styleLayerExists("name-layer")) {
      await map.style.addLayer(
        mbx.SymbolLayer(
          id: "name-layer",
          sourceId: "children-source",
          filter: ["!", ["has", "point_count"]],
          textFieldExpression: ["get", "name"],
          textSize: 14,
          textColor: 0xFF111111,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 3.0,
          textHaloBlur: 0.4,
          textAllowOverlap: true,
          textIgnorePlacement: true,

          //  đặt tên lên trên icon
          textAnchor: mbx.TextAnchor.BOTTOM,
          textOffset: [0, -2.6], // tăng/giảm để vừa ý (2.0 -> 2.6)
        ),
      );
    }

    _styleReady = true;
    notifyListeners();

    //  QUAN TRỌNG: style reload xong -> re-add lại các avatar đã cache
    // (nếu không, iconImageExpression trỏ tới id mà style mới chưa có)
    for (final entry in _avatarBytesById.entries) {
      await _addPngStyleImageIfNeeded(entry.key, entry.value);
    }
  }


  String _normalizeAvatarKey(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return s;

    // nếu bị dính nhiều token (space/newline), lấy token đầu
    final parts = s.split(RegExp(r'\s+'));
    if (parts.length == 1) return s;

    // ưu tiên https nếu có
    final https = parts.firstWhere(
          (p) => p.startsWith('https://') || p.startsWith('http://'),
      orElse: () => parts.first,
    );
    return https;
  }
  // ================= AVATAR =================

  Future<void> setDefaultAvatar(Uint8List bytes) async {
    await _addPngStyleImageIfNeeded(defaultAvatarId, bytes);
  }

  Future<void> setAvatarSmart({
    required String childId,
    required String? photoUrlOrData,
    required Uint8List defaultBytes,
  }) async {
    if (photoUrlOrData == null || photoUrlOrData.trim().isEmpty) {
      debugPrint("🟡 avatar none child=$childId -> default");
      _avatarCache.remove(childId);
      _avatarBytesById.remove(childId);
      _avatarKeyById.remove(childId);
      return;
    }

    final key = _normalizeAvatarKey(photoUrlOrData);
    if (key != photoUrlOrData.trim()) {
      debugPrint("🧹 avatar key normalized child=$childId");
      debugPrint("   raw=${photoUrlOrData.trim()}");
      debugPrint("   key=$key");
    }

    final oldKey = _avatarKeyById[childId];
    final cached = _avatarBytesById[childId];

    if (oldKey == key && cached != null) {
      await _addPngStyleImageIfNeeded(childId, cached);
      _avatarCache[childId] = cached;
      return;
    }

    try {
      final bytes = await _fetchAvatarBytes(key); // ✅ dùng key đã normalize
      debugPrint("✅ fetched bytes=${bytes.length} child=$childId key=$key");

      _avatarKeyById[childId] = key;
      _avatarBytesById[childId] = bytes;

      await _addPngStyleImageIfNeeded(childId, bytes);
      _avatarCache[childId] = bytes;
      print("Vao den day 2");
      notifyListeners();
      await _refreshGeoJsonIfPossible();

      debugPrint("✅ avatar ready child=$childId (refreshed)");

      debugPrint("✅ avatar ready child=$childId bytes=${bytes.length}");
    } catch (e) {
      debugPrint("🔴 avatar fail child=$childId key=$key err=$e");

      _avatarCache.remove(childId);
      _avatarBytesById.remove(childId);
      _avatarKeyById.remove(childId);
      await setDefaultAvatar(defaultBytes);
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

      final avatarId = _avatarCache.containsKey(id) ? id : defaultAvatarId;
      debugPrint("🧩 feature id=$id avatarId=$avatarId cache=${_avatarCache.containsKey(id)}");
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
        jsonEncode({"type": "FeatureCollection", "features": features}),
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
    await map.easeTo(
      mbx.CameraOptions(center: mbx.Point(coordinates: pos), zoom: 17, pitch: 30),
      mbx.MapAnimationOptions(duration: duration),
    );
    return duration;
  }

  Future<void> fitPoints(List<mbx.Position> positions) async {
    final map = _map;
    if (map == null || positions.isEmpty) return;

    num minLat = positions.first.lat, maxLat = positions.first.lat;
    num minLng = positions.first.lng, maxLng = positions.first.lng;

    for (final p in positions) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    await map.setCamera(
      mbx.CameraOptions(
        center: mbx.Point(
          coordinates: mbx.Position((minLng + maxLng) / 2, (minLat + maxLat) / 2),
        ),
        zoom: 13,
      ),
    );
  }
}