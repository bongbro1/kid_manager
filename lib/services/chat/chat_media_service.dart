import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:kid_manager/services/chat/family_chat_storage_path.dart';

class PreparedChatImage {
  const PreparedChatImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesLength,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesLength;
}

class UploadedChatImage {
  const UploadedChatImage({
    required this.downloadUrl,
    required this.storagePath,
  });

  final String downloadUrl;
  final String storagePath;
}

class ChatMediaService {
  ChatMediaService._();

  static final ImagePicker _picker = ImagePicker();
  static const int _maxLongEdge = 1280;
  static const int _targetBytes = 420 * 1024;

  static Future<PreparedChatImage?> pickCompressedImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final xfile = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (xfile == null) return null;

    return compressImage(File(xfile.path));
  }

  static Future<PreparedChatImage> compressImage(File inputFile) async {
    final bytes = await inputFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      return PreparedChatImage(
        bytes: bytes,
        width: 0,
        height: 0,
        bytesLength: bytes.length,
      );
    }

    img.Image processed = decoded;
    final longEdge = math.max(decoded.width, decoded.height);
    if (longEdge > _maxLongEdge) {
      final scale = _maxLongEdge / longEdge;
      processed = img.copyResize(
        decoded,
        width: math.max(1, (decoded.width * scale).round()),
        height: math.max(1, (decoded.height * scale).round()),
        interpolation: img.Interpolation.cubic,
      );
    }

    var quality = 82;
    var encoded = img.encodeJpg(processed, quality: quality);
    while (encoded.length > _targetBytes && quality > 60) {
      quality -= 8;
      encoded = img.encodeJpg(processed, quality: quality);
    }

    return PreparedChatImage(
      bytes: Uint8List.fromList(encoded),
      width: processed.width,
      height: processed.height,
      bytesLength: encoded.length,
    );
  }

  static Future<UploadedChatImage> uploadFamilyChatImage({
    required PreparedChatImage image,
    required String familyId,
    required String senderUid,
    required String messageId,
  }) async {
    final normalizedFamilyId = familyId.trim();
    final normalizedSenderUid = senderUid.trim();
    final normalizedMessageId = messageId.trim();

    final storagePath = buildFamilyChatImageStoragePath(
      familyId: normalizedFamilyId,
      senderUid: normalizedSenderUid,
      messageId: normalizedMessageId,
    );
    final ref = FirebaseStorage.instance.ref().child(storagePath);

    await ref.putData(
      image.bytes,
      SettableMetadata(
        cacheControl: 'public,max-age=3600',
        contentType: 'image/jpeg',
        customMetadata: <String, String>{
          'familyId': normalizedFamilyId,
          'senderUid': normalizedSenderUid,
          'messageId': normalizedMessageId,
          'kind': 'familyChatImage',
        },
      ),
    );

    final downloadUrl = await ref.getDownloadURL();
    return UploadedChatImage(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
    );
  }
}
