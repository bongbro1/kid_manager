import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class FamilyChatSticker {
  const FamilyChatSticker({
    required this.id,
    required this.assetPath,
    required this.label,
  });

  final String id;
  final String assetPath;
  final String label;
}

const List<String> kFamilyChatQuickEmojis = <String>[
  '\u{1F600}',
  '\u{1F602}',
  '\u{1F60D}',
  '\u{1F973}',
  '\u{1F44D}',
  '\u{2764}\u{FE0F}',
  '\u{1F64F}',
  '\u{1F389}',
  '\u{1F44F}',
  '\u{1F525}',
  '\u{1F917}',
  '\u{1F60E}',
];

const List<FamilyChatSticker> kFamilyChatFallbackStickers = <FamilyChatSticker>[
  FamilyChatSticker(
    id: 'celebrate',
    assetPath: 'assets/stickers/family_chat/celebrate.webp',
    label: 'Celebrate',
  ),
  // FamilyChatSticker(
  //   id: 'party',
  //   assetPath: 'assets/stickers/family_chat/party.webp',
  //   label: 'Party',
  // ),
  // FamilyChatSticker(
  //   id: 'love',
  //   assetPath: 'assets/stickers/family_chat/love.webp',
  //   label: 'Love',
  // ),
  // FamilyChatSticker(
  //   id: 'clap',
  //   assetPath: 'assets/stickers/family_chat/clap.webp',
  //   label: 'Clap',
  // ),
  // FamilyChatSticker(
  //   id: 'fire',
  //   assetPath: 'assets/stickers/family_chat/fire.webp',
  //   label: 'Fire',
  // ),
  // FamilyChatSticker(
  //   id: 'star',
  //   assetPath: 'assets/stickers/family_chat/star.webp',
  //   label: 'Star',
  // ),
  // FamilyChatSticker(
  //   id: 'perfect',
  //   assetPath: 'assets/stickers/family_chat/perfect.webp',
  //   label: 'Perfect',
  // ),
  // FamilyChatSticker(
  //   id: 'wow',
  //   assetPath: 'assets/stickers/family_chat/wow.webp',
  //   label: 'Wow',
  // ),
];

List<FamilyChatSticker>? _cachedFamilyChatStickers;

Future<List<FamilyChatSticker>> loadFamilyChatStickers() async {
  final cached = _cachedFamilyChatStickers;
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  try {
    final manifestRaw = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestRaw);
    if (manifest is! Map<String, dynamic>) {
      _cachedFamilyChatStickers = kFamilyChatFallbackStickers;
      return kFamilyChatFallbackStickers;
    }

    final discovered =
        manifest.keys
            .where(_isFamilyChatStickerAssetPath)
            .map(_stickerFromAssetPath)
            .toList(growable: false)
          ..sort((a, b) => a.label.compareTo(b.label));

    if (discovered.isNotEmpty) {
      _cachedFamilyChatStickers = discovered;
      return discovered;
    }
  } catch (_) {
    // Fall back to the curated list if asset manifest parsing fails.
  }

  _cachedFamilyChatStickers = kFamilyChatFallbackStickers;
  return kFamilyChatFallbackStickers;
}

FamilyChatSticker? findFamilyChatStickerById(
  String? stickerId, {
  List<FamilyChatSticker>? catalog,
}) {
  final normalized = stickerId?.trim() ?? '';
  if (normalized.isEmpty) {
    return null;
  }

  final source =
      catalog ?? _cachedFamilyChatStickers ?? kFamilyChatFallbackStickers;
  for (final sticker in source) {
    if (sticker.id == normalized) {
      return sticker;
    }
  }
  return null;
}

bool _isFamilyChatStickerAssetPath(String assetPath) {
  if (!assetPath.startsWith('assets/stickers/family_chat/')) {
    return false;
  }

  final extension = p.extension(assetPath).toLowerCase();
  return extension == '.webp' ||
      extension == '.png' ||
      extension == '.jpg' ||
      extension == '.jpeg';
}

FamilyChatSticker _stickerFromAssetPath(String assetPath) {
  final id = p.basenameWithoutExtension(assetPath).trim();
  final words = id
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.trim().isNotEmpty)
      .map((part) {
        final normalized = part.trim();
        final lower = normalized.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .toList(growable: false);

  return FamilyChatSticker(
    id: id,
    assetPath: assetPath,
    label: words.isEmpty ? id : words.join(' '),
  );
}
