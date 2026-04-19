import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class MarkerIconFactory {
  static Future<Uint8List> makeCircleIcon({
    required IconData icon,
    required Color bg,
    required Color fg,
    double size = 48,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final r = size / 2;

    final paintBg = Paint()..color = bg;
    canvas.drawCircle(Offset(r, r), r, paintBg);

    final tp = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.62,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: fg,
        ),
      ),
    )..layout();

    tp.paint(canvas, Offset(r - tp.width / 2, r - tp.height / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}
