// lib/screens/zones/zone_circle_painter.dart
import 'dart:math';
import 'package:flutter/material.dart';

class ZoneCirclePainter extends CustomPainter {
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;

  ZoneCirclePainter({
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) / 2;

    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(c, r, fill);
    canvas.drawCircle(c, r, stroke);
  }

  @override
  bool shouldRepaint(covariant ZoneCirclePainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
          oldDelegate.fillColor != fillColor ||
          oldDelegate.strokeWidth != strokeWidth;
}