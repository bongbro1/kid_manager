import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MapAvatarMarkerImage {
  const MapAvatarMarkerImage({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

class MapAvatarMarkerFactory {
  static final Map<String, Uint8List> _avatarBytesCache = {};
  static final Map<String, MapAvatarMarkerImage> _markerCache = {};

  static Future<MapAvatarMarkerImage> build({
    String? photoUrlOrData,
    required Color accentColor,
    double size = 72,
  }) async {
    final normalizedKey = photoUrlOrData?.trim() ?? '';
    final cacheKey =
        '$normalizedKey|${accentColor.alpha}-${accentColor.red}-${accentColor.green}-${accentColor.blue}|${size.round()}';
    final cached = _markerCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    Uint8List? avatarBytes;
    if (normalizedKey.isNotEmpty) {
      avatarBytes = _avatarBytesCache[normalizedKey];
      if (avatarBytes == null) {
        try {
          avatarBytes = await _fetchAvatarBytes(normalizedKey);
          _avatarBytesCache[normalizedKey] = avatarBytes;
        } catch (_) {
          avatarBytes = null;
        }
      }
    }

    final image = avatarBytes == null
        ? await _buildFallbackMarker(accentColor: accentColor, size: size)
        : await _buildAvatarMarker(
            avatarBytes: avatarBytes,
            accentColor: accentColor,
            size: size,
          );
    _markerCache[cacheKey] = image;
    return image;
  }

  static Uint8List? _tryDecodeDataUrl(String input) {
    const prefix = 'base64,';
    final index = input.indexOf(prefix);
    if (!input.startsWith('data:') || index < 0) {
      return null;
    }

    final raw = input.substring(index + prefix.length).trim();
    if (raw.isEmpty) {
      return null;
    }
    return base64Decode(raw);
  }

  static Future<Uint8List> _fetchAvatarBytes(String key) async {
    final dataBytes = _tryDecodeDataUrl(key);
    if (dataBytes != null) {
      return dataBytes;
    }

    final uri = Uri.tryParse(key);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      throw Exception('Invalid avatar url: $key');
    }

    final client = http.Client();
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Avatar fetch failed: HTTP ${response.statusCode}');
      }
      if (response.bodyBytes.isEmpty) {
        throw Exception('Avatar fetch returned empty bytes');
      }
      return response.bodyBytes;
    } finally {
      client.close();
    }
  }

  static Future<MapAvatarMarkerImage> _buildAvatarMarker({
    required Uint8List avatarBytes,
    required Color accentColor,
    required double size,
  }) async {
    final codec = await ui.instantiateImageCodec(
      avatarBytes,
      targetWidth: 160,
      targetHeight: 160,
    );
    final frame = await codec.getNextFrame();
    final avatarImage = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final outerRadius = size * 0.33;
    final avatarRadius = size * 0.27;

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: outerRadius + 2)),
      Colors.black.withOpacity(0.28),
      8,
      true,
    );

    canvas.drawCircle(
      center,
      outerRadius + 4,
      Paint()..color = accentColor.withOpacity(0.16),
    );
    canvas.drawCircle(center, outerRadius, Paint()..color = Colors.white);

    final avatarRect = Rect.fromCircle(center: center, radius: avatarRadius);
    canvas.save();
    canvas.clipPath(Path()..addOval(avatarRect));
    paintImage(
      canvas: canvas,
      rect: avatarRect,
      image: avatarImage,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    );
    canvas.restore();

    canvas.drawCircle(
      center,
      avatarRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accentColor,
    );
    canvas.drawCircle(
      center,
      avatarRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.92),
    );

    return _toMarkerImage(recorder, size);
  }

  static Future<MapAvatarMarkerImage> _buildFallbackMarker({
    required Color accentColor,
    required double size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    canvas.drawShadow(
      Path()..addOval(Rect.fromCircle(center: center, radius: size * 0.31)),
      Colors.black.withOpacity(0.28),
      8,
      true,
    );

    canvas.drawCircle(
      center,
      size * 0.31,
      Paint()..color = accentColor,
    );
    canvas.drawCircle(
      center,
      size * 0.31,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white.withOpacity(0.95),
    );

    final headCenter = Offset(size / 2, size * 0.38);
    final iconPaint = Paint()..color = Colors.white;
    canvas.drawCircle(headCenter, size * 0.11, iconPaint);

    final bodyPath = Path()
      ..moveTo(size * 0.33, size * 0.66)
      ..quadraticBezierTo(size * 0.50, size * 0.88, size * 0.67, size * 0.66)
      ..quadraticBezierTo(size * 0.50, size * 0.54, size * 0.33, size * 0.66)
      ..close();
    canvas.drawPath(bodyPath, iconPaint);

    return _toMarkerImage(recorder, size);
  }

  static Future<MapAvatarMarkerImage> _toMarkerImage(
    ui.PictureRecorder recorder,
    double size,
  ) async {
    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return MapAvatarMarkerImage(
      bytes: byteData!.buffer.asUint8List(),
      width: size.toInt(),
      height: size.toInt(),
    );
  }
}
