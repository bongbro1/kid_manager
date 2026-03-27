const String familyChatImageFileExtension = 'jpg';

String buildFamilyChatImageStoragePath({
  required String familyId,
  required String senderUid,
  required String messageId,
}) {
  final normalizedFamilyId = familyId.trim();
  final normalizedSenderUid = senderUid.trim();
  final normalizedMessageId = messageId.trim();

  return 'families/$normalizedFamilyId/chat/$normalizedSenderUid/'
      '$normalizedMessageId.$familyChatImageFileExtension';
}

bool matchesFamilyChatImageStoragePath({
  required String imagePath,
  required String familyId,
  required String senderUid,
  required String messageId,
}) {
  return imagePath.trim() ==
      buildFamilyChatImageStoragePath(
        familyId: familyId,
        senderUid: senderUid,
        messageId: messageId,
      );
}

String? extractStoragePathFromFirebaseDownloadUrl(String imageUrl) {
  final normalizedUrl = imageUrl.trim();
  if (normalizedUrl.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(normalizedUrl);
  if (uri == null) {
    return null;
  }

  if (uri.scheme == 'gs') {
    final path = uri.path.replaceFirst(RegExp(r'^/'), '');
    return path.isEmpty ? null : path;
  }

  const marker = '/o/';
  final markerIndex = uri.path.indexOf(marker);
  if (markerIndex < 0) {
    return null;
  }

  final encodedPath = uri.path.substring(markerIndex + marker.length);
  if (encodedPath.isEmpty) {
    return null;
  }

  return Uri.decodeComponent(encodedPath);
}

String? resolveFamilyChatImageStoragePath({
  required String familyId,
  required String senderUid,
  required String messageId,
  String? imagePath,
  String? imageUrl,
}) {
  final normalizedImagePath = imagePath?.trim() ?? '';
  if (normalizedImagePath.isNotEmpty &&
      matchesFamilyChatImageStoragePath(
        imagePath: normalizedImagePath,
        familyId: familyId,
        senderUid: senderUid,
        messageId: messageId,
      )) {
    return normalizedImagePath;
  }

  final extractedPath = extractStoragePathFromFirebaseDownloadUrl(
    imageUrl ?? '',
  );
  if (extractedPath == null) {
    return null;
  }

  if (!matchesFamilyChatImageStoragePath(
    imagePath: extractedPath,
    familyId: familyId,
    senderUid: senderUid,
    messageId: messageId,
  )) {
    return null;
  }

  return extractedPath;
}
