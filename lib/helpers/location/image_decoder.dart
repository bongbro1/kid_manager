import 'dart:typed_data';
import 'dart:ui' as ui;

class ImageDecoder {
  static Future<DecodedImage> decode(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    return DecodedImage(
      bytes: byteData!.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    );
  }
}

class DecodedImage {
  final Uint8List bytes;
  final int width;
  final int height;

  DecodedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });
}