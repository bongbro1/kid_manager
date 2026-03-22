import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

class MapboxController extends ChangeNotifier {
  mbx.MapboxMap? _map;
  bool _styleReady = false;
  bool get isReady => _styleReady;
// trong MapboxController
  mbx.Position? getChildPosition(String childId) {
    return _currentPositions[childId] ?? _lastPositions[childId];
  }
  Timer? _debounce;

  final Map<String, Uint8List> _avatarCache = {}; // childId -> bytes
  final Map<String, Uint8List> _avatarBytesById = {};
  final Map<String, String?> _avatarKeyById = {}; // url/data string
  final Map<String, DateTime> _avatarRetryBlockedUntil = {};
  final Map<String, ({Uint8List png, int w, int h, String fingerprint})>
      _normalizedStyleImageCache = {};

  final Map<String, mbx.Position> _currentPositions = {};
  final Set<String> _addedStyleImages = <String>{};

  static const String defaultAvatarId = "default_avatar_location";
  Map<String, mbx.Position> _lastPositions = {};
  Map<String, double> _lastHeadings = {};
  Map<String, String> _lastNames = {};

  // ================= FOCUS BUBBLE (MAP LAYER) =================
  static const String _bubbleSourceId = "focus-bubble-source";
  static const String _bubbleLayerId  = "focus-bubble-layer";
  static const String _bubbleImageId  = "focus_bubble_img";

  String? _bubbleCacheKey; // để tránh regenerate PNG khi text không đổi
  bool _bubbleReady = false;
  bool _bubbleImageAdded = false;
  Future<void> _styleQueue = Future.value();
  Future<void>? _styleInitInFlight;
  int? _styleInitSession;
  int _mapSession = 0;

  bool _isSessionActive(int session) => _map != null && _mapSession == session;

  bool _isDetachedChannelError(Object error) {
    if (error is! PlatformException) return false;
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    return code.contains('channel-error') ||
        message.contains('unable to establish connection on channel');
  }

  bool _isStyleImageMissingError(Object error) {
    if (error is! PlatformException) return false;
    final message = (error.message ?? '').toLowerCase();
    return message.contains('is not present in style') ||
        message.contains('cannot remove');
  }

  bool _isStyleAlreadyExistsError(Object error) {
    if (error is! PlatformException) return false;
    final message = (error.message ?? '').toLowerCase();
    return message.contains('already exists');
  }

  Future<T?> _runStyleQuery<T>({
    required int session,
    required String label,
    required Future<T> Function() call,
  }) async {
    if (!_isSessionActive(session)) return null;
    try {
      return await call();
    } catch (e) {
      if (_isDetachedChannelError(e) || !_isSessionActive(session)) {
        debugPrint("Skip map style query after detach: $label");
        return null;
      }
      rethrow;
    }
  }

  Future<bool> _runStyleWrite({
    required int session,
    required String label,
    required Future<void>? Function() call,
  }) async {
    if (!_isSessionActive(session)) return false;
    try {
      final pending = call();
      if (pending != null) {
        await pending;
      }
      return true;
    } catch (e) {
      if (_isDetachedChannelError(e) || !_isSessionActive(session)) {
        debugPrint("Skip map style write after detach: $label");
        return false;
      }
      rethrow;
    }
  }

  void attach(mbx.MapboxMap map) {
    _mapSession++;
    _map = map;
    _styleReady = false;
    _bubbleReady = false;
    _bubbleImageAdded = false;
    _bubbleCacheKey = null;
    _styleInitInFlight = null;
    _styleInitSession = null;
  }

  void detach() {
    _mapSession++;
    _debounce?.cancel();
    _styleReady = false;
    _bubbleReady = false;
    _bubbleImageAdded = false;
    _bubbleCacheKey = null;
    _addedStyleImages.clear();
    _styleQueue = Future.value();
    _styleInitInFlight = null;
    _styleInitSession = null;
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
    _debounce = Timer(const Duration(milliseconds: 100), () {
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
  Future<void> _enqueueStyle({
    required int session,
    required Future<void> Function() task,
  }) {
    final completer = Completer<void>();
    _styleQueue = _styleQueue.then((_) async {
      if (!_isSessionActive(session)) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      try {
        await task();
        if (!completer.isCompleted) completer.complete();
      } catch (e, st) {
        if (_isDetachedChannelError(e) || !_isSessionActive(session)) {
          debugPrint("Skip queued style task after detach");
          if (!completer.isCompleted) completer.complete();
          return;
        }
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  String _fingerprintBytes(Uint8List bytes) {
    if (bytes.isEmpty) return '0:0:0:0';
    final first = bytes.first;
    final middle = bytes[bytes.length ~/ 2];
    final last = bytes.last;
    return '${bytes.length}:$first:$middle:$last';
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
      Object? lastError;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          final resp = await client
              .get(uri)
              .timeout(const Duration(seconds: 15));
          if (resp.statusCode < 200 || resp.statusCode >= 300) {
            throw Exception(
              "HTTP ${resp.statusCode} len=${resp.bodyBytes.length}",
            );
          }
          if (resp.bodyBytes.isEmpty) {
            throw Exception("empty bytes");
          }
          return resp.bodyBytes;
        } catch (e) {
          lastError = e;
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 400 * attempt));
          }
        }
      }
      throw Exception("fetch retry exhausted: $lastError");
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

    final codec = await ui.instantiateImageCodec(
      inputBytes,
      targetWidth: 192,
      targetHeight: 192,
    );
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
    final session = _mapSession;
    if (map == null) return;
    if (_addedStyleImages.contains(id)) return;

    await _enqueueStyle(
      session: session,
      task: () async {
        final mapNow = _map;
        if (mapNow == null || !_isSessionActive(session)) return;

        for (int attempt = 1; attempt <= 5; attempt++) {
          if (!_isSessionActive(session) || !identical(_map, mapNow)) return;

          final loaded = await _runStyleQuery<bool>(
            session: session,
            label: "isStyleLoaded",
            call: () => mapNow.style.isStyleLoaded(),
          );

          if (!_isSessionActive(session) || !identical(_map, mapNow)) return;
          if (loaded != true) {
            await Future.delayed(const Duration(milliseconds: 120));
            continue;
          }

          try {
            final fingerprint = _fingerprintBytes(anyEncodedBytes);
            final cachedNorm = _normalizedStyleImageCache[id];

            final norm = (cachedNorm != null &&
                    cachedNorm.fingerprint == fingerprint)
                ? (png: cachedNorm.png, w: cachedNorm.w, h: cachedNorm.h)
                : await _normalizeToPng(anyEncodedBytes);
            if (!_isSessionActive(session) || !identical(_map, mapNow)) return;

            if (cachedNorm == null || cachedNorm.fingerprint != fingerprint) {
              _normalizedStyleImageCache[id] = (
                png: norm.png,
                w: norm.w,
                h: norm.h,
                fingerprint: fingerprint,
              );
            }

            final added = await _runStyleWrite(
              session: session,
              label: "addStyleImage:$id",
              call: () => mapNow.style.addStyleImage(
                id,
                1.0,
                mbx.MbxImage(width: norm.w, height: norm.h, data: norm.png),
                false,
                [],
                [],
                null,
              ),
            );
            if (!added) return;

            _addedStyleImages.add(id);
            debugPrint("addStyleImage OK id=$id w=${norm.w} h=${norm.h}");
            return;
          } catch (e) {
            if (_isDetachedChannelError(e) || !_isSessionActive(session)) return;
            debugPrint("addStyleImage fail id=$id attempt=$attempt err=$e");
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }

        if (_isSessionActive(session)) {
          throw Exception("addStyleImage failed after retries id=$id");
        }
      },
    );
  }
  // ================= STYLE =================

  Future<bool> _runStyleCreate({
    required int session,
    required String label,
    required Future<void>? Function() call,
  }) async {
    try {
      return await _runStyleWrite(
        session: session,
        label: label,
        call: call,
      );
    } catch (e) {
      if (_isStyleAlreadyExistsError(e)) {
        debugPrint("Skip duplicate style create: $label");
        return true;
      }
      rethrow;
    }
  }

  Future<void> onStyleLoaded() {
    final map = _map;
    final session = _mapSession;
    if (map == null) return Future.value();

    final inFlight = _styleInitInFlight;
    if (inFlight != null && _styleInitSession == session) {
      return inFlight;
    }

    final future = _onStyleLoadedImpl(map: map, session: session);
    _styleInitInFlight = future;
    _styleInitSession = session;
    return future.whenComplete(() {
      if (_styleInitSession == session && identical(_styleInitInFlight, future)) {
        _styleInitInFlight = null;
        _styleInitSession = null;
      }
    });
  }

  Future<void> _onStyleLoadedImpl({
    required mbx.MapboxMap map,
    required int session,
  }) async {

    _addedStyleImages.clear();
    _bubbleImageAdded = false;

    final hasChildrenSource = await _runStyleQuery<bool>(
      session: session,
      label: "styleSourceExists:children-source",
      call: () => map.style.styleSourceExists("children-source"),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;
    if (hasChildrenSource == null) return;
    if (!hasChildrenSource) {
      final added = await _runStyleCreate(
        session: session,
        label: "addSource:children-source",
        call: () => map.style.addSource(
          mbx.GeoJsonSource(
            id: "children-source",
            cluster: true,
            clusterRadius: 60,
            clusterMaxZoom: 14,
            data: jsonEncode({"type": "FeatureCollection", "features": []}),
          ),
        ),
      );
      if (!added) return;
    }

    final hasChildrenLayer = await _runStyleQuery<bool>(
      session: session,
      label: "styleLayerExists:children-layer",
      call: () => map.style.styleLayerExists("children-layer"),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;
    if (hasChildrenLayer == null) return;
    if (!hasChildrenLayer) {
      final added = await _runStyleCreate(
        session: session,
        label: "addLayer:children-layer",
        call: () => map.style.addLayer(
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
        ),
      );
      if (!added) return;
    }

    final hasNameLayer = await _runStyleQuery<bool>(
      session: session,
      label: "styleLayerExists:name-layer",
      call: () => map.style.styleLayerExists("name-layer"),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;
    if (hasNameLayer == null) return;
    if (!hasNameLayer) {
      final nameLayer = mbx.SymbolLayer(
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
        textAnchor: mbx.TextAnchor.BOTTOM,
        textOffset: [0, -2.6],
      );

      final added = await _runStyleCreate(
        session: session,
        label: "addLayerAt:name-layer",
        call: () => map.style.addLayerAt(
          nameLayer,
          mbx.LayerPosition(above: "children-layer"),
        ),
      );
      if (!added) return;
    }

    final hasBubbleSource = await _runStyleQuery<bool>(
      session: session,
      label: "styleSourceExists:focus-bubble-source",
      call: () => map.style.styleSourceExists(_bubbleSourceId),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;
    if (hasBubbleSource == null) return;
    if (!hasBubbleSource) {
      final added = await _runStyleCreate(
        session: session,
        label: "addSource:focus-bubble-source",
        call: () => map.style.addSource(
          mbx.GeoJsonSource(
            id: _bubbleSourceId,
            data: jsonEncode({"type": "FeatureCollection", "features": []}),
          ),
        ),
      );
      if (!added) return;
    }

    final hasBubbleLayer = await _runStyleQuery<bool>(
      session: session,
      label: "styleLayerExists:focus-bubble-layer",
      call: () => map.style.styleLayerExists(_bubbleLayerId),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;
    if (hasBubbleLayer == null) return;
    if (hasBubbleLayer) {
      await _runStyleWrite(
        session: session,
        label: "removeStyleLayer:focus-bubble-layer",
        call: () => map.style.removeStyleLayer(_bubbleLayerId),
      );
      if (!_isSessionActive(session) || !identical(_map, map)) return;
    }

    final bubbleLayer = mbx.SymbolLayer(
      id: _bubbleLayerId,
      sourceId: _bubbleSourceId,
      iconImageExpression: ["get", "bubble_img"],
      iconAllowOverlap: true,
      iconIgnorePlacement: true,
      iconAnchor: mbx.IconAnchor.BOTTOM,
      symbolSortKeyExpression: ["literal", 999999],
      iconSizeExpression: [
        "interpolate", ["linear"], ["zoom"],
        5, 0.48,
        10, 0.55,
        16, 0.62,
        18, 0.64,
      ],
      iconOffsetExpression: [
        "interpolate", ["linear"], ["zoom"],
        5, ["literal", [0, -80]],
        10, ["literal", [0, -80]],
        16, ["literal", [0, -80]],
        18, ["literal", [0, -80]],
      ],
    );

    final bubbleAdded = await _runStyleCreate(
      session: session,
      label: "addLayerAt:focus-bubble-layer",
      call: () => map.style.addLayerAt(
        bubbleLayer,
        mbx.LayerPosition(above: "name-layer"),
      ),
    );
    if (!bubbleAdded) return;
    if (!_isSessionActive(session) || !identical(_map, map)) return;

    _bubbleReady = true;
    _styleReady = true;
    notifyListeners();

    for (final entry in _avatarBytesById.entries) {
      if (!_isSessionActive(session) || !identical(_map, map)) return;
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
      // debugPrint("🟡 avatar none child=$childId -> default");
      _avatarCache.remove(childId);
      _avatarBytesById.remove(childId);
      _avatarKeyById.remove(childId);
      _normalizedStyleImageCache.remove(childId);
      return;
    }

    final key = _normalizeAvatarKey(photoUrlOrData);
    if (key != photoUrlOrData.trim()) {
      // debugPrint("🧹 avatar key normalized child=$childId");
      // debugPrint("   raw=${photoUrlOrData.trim()}");
      // debugPrint("   key=$key");
    }

    final oldKey = _avatarKeyById[childId];
    final cached = _avatarBytesById[childId];
    final now = DateTime.now();
    final blockedUntil = _avatarRetryBlockedUntil[childId];
    if (blockedUntil != null &&
        now.isBefore(blockedUntil) &&
        cached != null &&
        oldKey == key) {
      await _addPngStyleImageIfNeeded(childId, cached);
      _avatarCache[childId] = cached;
      return;
    }

    if (oldKey == key && cached != null) {
      _avatarRetryBlockedUntil.remove(childId);
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
      notifyListeners();
      await _refreshGeoJsonIfPossible();

      debugPrint("✅ avatar ready child=$childId (refreshed)");

      debugPrint("✅ avatar ready child=$childId bytes=${bytes.length}");
    } catch (e) {
      debugPrint("🔴 avatar fail child=$childId key=$key err=$e");
      _avatarRetryBlockedUntil[childId] = DateTime.now().add(
        const Duration(seconds: 45),
      );

      if (cached != null) {
        // Keep last good avatar to avoid flicker/default fallback storms.
        _avatarCache[childId] = cached;
        if (oldKey != null) {
          _avatarKeyById[childId] = oldKey;
        }
        _avatarBytesById[childId] = cached;
        await _addPngStyleImageIfNeeded(childId, cached);
        await _refreshGeoJsonIfPossible();
        debugPrint("avatar keep-last-success child=$childId");
        return;
      }

      _avatarCache.remove(childId);
      _avatarBytesById.remove(childId);
      _avatarKeyById.remove(childId);
      await setDefaultAvatar(defaultBytes);
    }
  }

  Future<void> clearFocusBubble() async {
    final map = _map;
    final session = _mapSession;
    if (map == null || !_styleReady) return;

    final source = await _runStyleQuery<Object?>(
      session: session,
      label: "getSource:focus-bubble-source",
      call: () => map.style.getSource(_bubbleSourceId),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;

    if (source is mbx.GeoJsonSource) {
      await _runStyleWrite(
        session: session,
        label: "updateGeoJSON:focus-bubble-source",
        call: () => source.updateGeoJSON(
          jsonEncode({"type": "FeatureCollection", "features": []}),
        ),
      );
    }
  }
  /// text: "đã ở nhà · 2g47 phút trước"
  /// icon: Icons.home / Icons.warning_amber_rounded ...
  Future<void> setFocusBubble({
    required String childId,
    required String text,
    required IconData icon,
  }) async {
    final map = _map;
    final session = _mapSession;
    if (map == null || !_styleReady || !_bubbleReady) return;

    final pos = getChildPosition(childId);
    if (pos == null) {
      debugPrint("setFocusBubble: pos null child=$childId");
      return;
    }

    final key = "${icon.codePoint}:${text.trim()}";
    if (_bubbleCacheKey != key) {
      _bubbleCacheKey = key;
      final png = await _makeBubblePng(text: text, icon: icon);
      if (!_isSessionActive(session) || !identical(_map, map)) return;

      if (_bubbleImageAdded) {
        try {
          await _runStyleWrite(
            session: session,
            label: "removeStyleImage:focus_bubble_img",
            call: () => map.style.removeStyleImage(_bubbleImageId),
          );
        } catch (e) {
          if (!_isStyleImageMissingError(e)) rethrow;
        } finally {
          _bubbleImageAdded = false;
        }
      }
      if (!_isSessionActive(session) || !identical(_map, map)) return;

      final added = await _runStyleWrite(
        session: session,
        label: "addStyleImage:focus_bubble_img",
        call: () => map.style.addStyleImage(
          _bubbleImageId,
          1.0,
          mbx.MbxImage(width: png.w, height: png.h, data: png.png),
          false,
          [],
          [],
          null,
        ),
      );
      if (!added) return;
      _bubbleImageAdded = true;
    }

    final feature = {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": [pos.lng, pos.lat],
      },
      "properties": {
        "bubble_img": _bubbleImageId,
      }
    };

    final source = await _runStyleQuery<Object?>(
      session: session,
      label: "getSource:focus-bubble-source",
      call: () => map.style.getSource(_bubbleSourceId),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;

    if (source is mbx.GeoJsonSource) {
      await _runStyleWrite(
        session: session,
        label: "updateGeoJSON:focus-bubble-source",
        call: () => source.updateGeoJSON(
          jsonEncode({
            "type": "FeatureCollection",
            "features": [feature],
          }),
        ),
      );
    }
  }
  // ================= UPDATE SOURCE =================

  Future<void> updateChildren({
    required Map<String, mbx.Position> positions,
    required Map<String, double> headings,
    required Map<String, String> names,
  }) async {
    final map = _map;
    final session = _mapSession;
    if (map == null || !_styleReady) return;

    _currentPositions
      ..clear()
      ..addAll(positions);

    final features = positions.entries.map((entry) {
      final id = entry.key;
      final pos = entry.value;

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

    final source = await _runStyleQuery<Object?>(
      session: session,
      label: "getSource:children-source",
      call: () => map.style.getSource("children-source"),
    );
    if (!_isSessionActive(session) || !identical(_map, map)) return;

    if (source is mbx.GeoJsonSource) {
      await _runStyleWrite(
        session: session,
        label: "updateGeoJSON:children-source",
        call: () => source.updateGeoJSON(
          jsonEncode({"type": "FeatureCollection", "features": features}),
        ),
      );
    }
  }
  Future<({Uint8List png, int w, int h})> _makeBubblePng({
    required String text,
    required IconData icon,
  }) async {
    const double fontSize = 18;
    const double iconSize = 20;
    const double padX = 14;
    const double padY = 10;
    const double gap = 8;
    const double radius = 999;

    // tail
    const double tailW = 16;
    const double tailH = 10;

    // measure text
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: fontSize, maxLines: 1, textDirection: ui.TextDirection.ltr),
    )
      ..pushStyle(ui.TextStyle(
        color: const ui.Color(0xFF111111),
        fontSize: fontSize,
        fontWeight: ui.FontWeight.w600,
      ))
      ..addText(text);

    final p = pb.build()..layout(const ui.ParagraphConstraints(width: 2000));
    final textW = p.maxIntrinsicWidth;
    final textH = p.height;

    // icon glyph
    final iconChar = String.fromCharCode(icon.codePoint);
    final ib = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: iconSize, maxLines: 1, textDirection: ui.TextDirection.ltr),
    )
      ..pushStyle(ui.TextStyle(
        color: const ui.Color(0xFF616161),
        fontSize: iconSize,
        fontFamily: icon.fontFamily ?? "MaterialIcons",
      ))
      ..addText(iconChar);

    final ip = ib.build()..layout(const ui.ParagraphConstraints(width: 2000));
    final iconW = ip.maxIntrinsicWidth;
    final iconH = ip.height;

    final bodyH = (max(textH, iconH) + padY * 2).ceil();
    final bodyW = (padX * 2 + iconW + gap + textW).ceil();

    // ✅ tổng height có thêm tailH
    final w = bodyW;
    final h = (bodyH + tailH).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final bodyRect = ui.Rect.fromLTWH(0, 0, w.toDouble(), bodyH.toDouble());
    final bodyRRect = ui.RRect.fromRectAndRadius(bodyRect, const ui.Radius.circular(radius));

    // shadow
    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x22000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

    canvas.drawRRect(bodyRRect.shift(const ui.Offset(0, 3)), shadowPaint);

    // tail shadow
    final cx = w / 2.0;
    final tailShadow = ui.Path()
      ..moveTo(cx - tailW / 2, bodyH - 1)
      ..lineTo(cx + tailW / 2, bodyH - 1)
      ..lineTo(cx, bodyH + tailH)
      ..close();
    canvas.drawPath(tailShadow.shift(const ui.Offset(0, 3)), shadowPaint);

    // bg
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRRect(bodyRRect, bgPaint);

    // tail
    final tail = ui.Path()
      ..moveTo(cx - tailW / 2, bodyH - 1)
      ..lineTo(cx + tailW / 2, bodyH - 1)
      ..lineTo(cx, bodyH + tailH)
      ..close();
    canvas.drawPath(tail, bgPaint);

    // icon + text
    final iconY = (bodyH - iconH) / 2;
    canvas.drawParagraph(ip, ui.Offset(padX, iconY));

    final textX = padX + iconW + gap;
    final textY = (bodyH - textH) / 2;
    canvas.drawParagraph(p, ui.Offset(textX, textY));

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception("bubble toByteData null");

    return (png: bd.buffer.asUint8List(), w: w, h: h);
  }

  // ================= CAMERA =================

  Future<int> zoomToChild(String childId) async {
    final map = _map;
    if (map == null) return 0;

    final pos = _currentPositions[childId] ?? _lastPositions[childId];
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

