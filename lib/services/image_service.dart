import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:kid_manager/models/user/user_types.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class PreparedUserPhoto {
  const PreparedUserPhoto({
    required this.bytes,
    required this.fileExtension,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileExtension;
  final String contentType;
}

class UserPhotoProcessingService {
  static const int _avatarMaxEdge = 720;
  static const int _coverMaxWidth = 1440;
  static const int _coverMaxHeight = 810;
  static const int _avatarTargetBytes = 180 * 1024;
  static const int _coverTargetBytes = 320 * 1024;
  static const int _minimumQuality = 56;

  static Future<File> createTempOptimizedFile({
    required Uint8List sourceBytes,
    required UserPhotoType type,
  }) async {
    final prepared = prepareFromBytes(sourceBytes: sourceBytes, type: type);
    final dir = await getTemporaryDirectory();
    final file = File(
      join(
        dir.path,
        '${type.name}_${DateTime.now().millisecondsSinceEpoch}.${prepared.fileExtension}',
      ),
    );

    await file.writeAsBytes(prepared.bytes, flush: false);
    return file;
  }

  static Future<PreparedUserPhoto> prepareFromFile({
    required File file,
    required UserPhotoType type,
  }) async {
    final bytes = await file.readAsBytes();
    final normalizedExtension = extension(file.path).toLowerCase();
    final targetBytes = type == UserPhotoType.avatar
        ? _avatarTargetBytes
        : _coverTargetBytes;

    if ((normalizedExtension == '.jpg' || normalizedExtension == '.jpeg') &&
        bytes.length <= targetBytes) {
      return PreparedUserPhoto(
        bytes: bytes,
        fileExtension: 'jpg',
        contentType: 'image/jpeg',
      );
    }

    return prepareFromBytes(sourceBytes: bytes, type: type);
  }

  static PreparedUserPhoto prepareFromBytes({
    required Uint8List sourceBytes,
    required UserPhotoType type,
  }) {
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) {
      throw StateError('Unsupported image format');
    }

    var processed = img.bakeOrientation(decoded);
    processed = _resizeForType(processed, type);

    final targetBytes = type == UserPhotoType.avatar
        ? _avatarTargetBytes
        : _coverTargetBytes;

    var quality = type == UserPhotoType.avatar ? 82 : 80;
    var encoded = img.encodeJpg(processed, quality: quality);

    while (encoded.length > targetBytes && quality > _minimumQuality) {
      quality -= 6;
      encoded = img.encodeJpg(processed, quality: quality);
    }

    return PreparedUserPhoto(
      bytes: Uint8List.fromList(encoded),
      fileExtension: 'jpg',
      contentType: 'image/jpeg',
    );
  }

  static img.Image _resizeForType(img.Image image, UserPhotoType type) {
    switch (type) {
      case UserPhotoType.avatar:
        final longEdge = math.max(image.width, image.height);
        if (longEdge <= _avatarMaxEdge) {
          return image;
        }

        final scale = _avatarMaxEdge / longEdge;
        return img.copyResize(
          image,
          width: math.max(1, (image.width * scale).round()),
          height: math.max(1, (image.height * scale).round()),
          interpolation: img.Interpolation.average,
        );

      case UserPhotoType.cover:
        if (image.width <= _coverMaxWidth && image.height <= _coverMaxHeight) {
          return image;
        }

        final widthScale = _coverMaxWidth / image.width;
        final heightScale = _coverMaxHeight / image.height;
        final scale = math.min(widthScale, heightScale);

        return img.copyResize(
          image,
          width: math.max(1, (image.width * scale).round()),
          height: math.max(1, (image.height * scale).round()),
          interpolation: img.Interpolation.average,
        );
    }
  }
}

class FirebaseStorageService {
  static Future<String> uploadUserPhoto({
    required File file,
    required String uid,
    required UserPhotoType type,
  }) async {
    final prepared = await UserPhotoProcessingService.prepareFromFile(
      file: file,
      type: type,
    );
    final updatedAt = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(uid)
        .child('${type.name}.${prepared.fileExtension}');

    await ref.putData(
      prepared.bytes,
      SettableMetadata(
        cacheControl: 'public,max-age=31536000,immutable',
        contentType: prepared.contentType,
        customMetadata: <String, String>{
          'uid': uid,
          'photoType': type.name,
          'updatedAt': '$updatedAt',
        },
      ),
    );

    final downloadUrl = await ref.getDownloadURL();
    final separator = downloadUrl.contains('?') ? '&' : '?';
    return '$downloadUrl${separator}v=$updatedAt';
  }
}
