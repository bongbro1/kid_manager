import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class StartEndMarkerRenderer {
  final MapboxMap map;

  PointAnnotationManager? _manager;
  PointAnnotation? _startMarker;
  PointAnnotation? _endMarker;

  Uint8List? _startIconBytes;
  Uint8List? _endIconBytes;
  int _generation = 0;
  bool _disposed = false;

  static const double _markerSize = 0.5;

  StartEndMarkerRenderer(this.map);

  bool _isActive(int generation) => !_disposed && generation == _generation;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _manager = null;
    _startMarker = null;
    _endMarker = null;
  }

  Future<void> init() async {
    if (_disposed) return;
    final generation = _generation;
    if (_manager == null) {
      try {
        _manager = await map.annotations.createPointAnnotationManager();
      } catch (error) {
        if (isMapLifecycleError(error) || !_isActive(generation)) {
          return;
        }
        rethrow;
      }
    }
    if (!_isActive(generation)) return;

    _startIconBytes ??= await _buildBadgeBytes(
      text: 'START',
      textBg: const Color(0xFFDDF5E3),
      textColor: const Color(0xFF188038),
      iconBg: const Color(0xFF1A73E8),
      icon: Icons.home_rounded,
      iconColor: Colors.white,
    );
    if (!_isActive(generation)) return;

    _endIconBytes ??= await _buildBadgeBytes(
      text: 'FINISH',
      textBg: const Color(0xFFFDE2E1),
      textColor: const Color(0xFFC5221F),
      iconBg: const Color(0xFF1A73E8),
      icon: Icons.flag_rounded,
      iconColor: Colors.white,
    );
  }

  Future<Uint8List> _buildBadgeBytes({
    required String text,
    required Color textBg,
    required Color textColor,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
  }) async {
    const double width = 92;
    const double height = 108;
    const double pixelRatio = 3.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = pixelRatio;
    canvas.scale(scale, scale);

    final Paint shadowPaint = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    final Paint pillPaint = Paint()..color = textBg;
    final Paint iconPaint = Paint()..color = iconBg;
    final Paint stemPaint = Paint()..color = Colors.white;

    final RRect pillRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 2, 68, 26),
      const Radius.circular(999),
    );

    final RRect iconRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(25, 34, 42, 42),
      const Radius.circular(14),
    );

    final RRect stemRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(44, 78, 4, 18),
      const Radius.circular(99),
    );

    canvas.drawRRect(pillRRect.shift(const Offset(0, 2)), shadowPaint);
    canvas.drawRRect(pillRRect, pillPaint);

    final pillBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(pillRRect, pillBorder);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    textPainter.paint(canvas, Offset((width - textPainter.width) / 2, 8));

    canvas.drawRRect(iconRRect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(iconRRect, iconPaint);

    final iconBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(iconRRect, iconBorder);

    final iconTextPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          fontSize: 23,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconTextPainter.paint(
      canvas,
      Offset((width - iconTextPainter.width) / 2, 43),
    );

    canvas.drawRRect(stemRRect.shift(const Offset(0, 1)), shadowPaint);
    canvas.drawRRect(stemRRect, stemPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * pixelRatio).toInt(),
      (height * pixelRatio).toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> clear() async {
    if (_disposed) return;
    final generation = _generation;
    final manager = _manager;
    if (manager == null) return;

    if (_startMarker != null) {
      try {
        await manager.delete(_startMarker!);
      } catch (error) {
        if (!isMapLifecycleError(error) && _isActive(generation)) {
          rethrow;
        }
      }
      _startMarker = null;
    }
    if (!_isActive(generation)) return;

    if (_endMarker != null) {
      try {
        await manager.delete(_endMarker!);
      } catch (error) {
        if (!isMapLifecycleError(error) && _isActive(generation)) {
          rethrow;
        }
      }
      _endMarker = null;
    }
  }

  Future<void> render(List<LocationData> data) async {
    if (_disposed) return;
    final generation = _generation;
    final manager = _manager;
    if (manager == null) return;

    await clear();
    if (!_isActive(generation)) return;
    if (data.isEmpty) return;

    final sorted = [...data]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final start = sorted.first;
    final end = sorted.last;

    try {
      _startMarker = await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(start.longitude, start.latitude),
          ),
          image: _startIconBytes,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: _markerSize,
        ),
      );
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
    if (!_isActive(generation)) return;

    if (sorted.length > 1) {
      try {
        _endMarker = await manager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(end.longitude, end.latitude)),
            image: _endIconBytes,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: _markerSize,
          ),
        );
      } catch (error) {
        if (isMapLifecycleError(error) || !_isActive(generation)) {
          return;
        }
        rethrow;
      }
    }
  }

  Future<void> renderSinglePoint(LocationData loc) async {
    if (_disposed) return;
    final generation = _generation;
    final manager = _manager;
    if (manager == null) return;

    await clear();
    if (!_isActive(generation)) return;

    try {
      _startMarker = await manager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(loc.longitude, loc.latitude)),
          image: _startIconBytes,
          iconAnchor: IconAnchor.BOTTOM,
          iconSize: _markerSize,
        ),
      );
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }

  Future<void> updateEndMarker(LocationData loc) async {
    if (_disposed) return;
    final generation = _generation;
    final manager = _manager;
    if (manager == null) return;

    final point = Point(coordinates: Position(loc.longitude, loc.latitude));

    if (_endMarker == null) {
      try {
        _endMarker = await manager.create(
          PointAnnotationOptions(
            geometry: point,
            image: _endIconBytes,
            iconAnchor: IconAnchor.BOTTOM,
            iconSize: _markerSize,
          ),
        );
      } catch (error) {
        if (isMapLifecycleError(error) || !_isActive(generation)) {
          return;
        }
        rethrow;
      }
      return;
    }
    if (!_isActive(generation)) return;

    _endMarker!.geometry = point;
    _endMarker!.iconSize = _markerSize;
    try {
      await manager.update(_endMarker!);
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return;
      }
      rethrow;
    }
  }
}
