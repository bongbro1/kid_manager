import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SmartNetworkImage extends StatelessWidget {
  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.maxRetries = 2,
    this.requestTimeout = const Duration(seconds: 12),
    this.retryDelay = const Duration(milliseconds: 700),
  });

  final String? imageUrl;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int maxRetries;
  final Duration requestTimeout;
  final Duration retryDelay;

  String? _resolveLocalPath(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri?.scheme == 'file') {
      return uri!.toFilePath();
    }

    if (raw.startsWith('/') ||
        raw.startsWith(r'\\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(raw)) {
      return raw;
    }

    return null;
  }

  String? _resolveRemoteUrl(String raw) {
    if (raw.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.isEmpty) {
      return null;
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return null;
    }

    return raw;
  }

  int? _toCacheDimension(BuildContext context, double? logicalSize) {
    if (logicalSize == null || logicalSize <= 0) {
      return null;
    }

    double size = logicalSize;
    // Nếu size là vô hạn (như double.infinity cho cover photo),
    // sử dụng kích thước màn hình để giới hạn cache width/height.
    if (!size.isFinite) {
      final screenSize = MediaQuery.sizeOf(context);
      // Giả sử lấy width nếu size là width vô hạn
      size = screenSize.width;
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final pixels = (size * dpr).round();
    return pixels > 0 ? pixels : null;
  }

  Widget _buildFallback() {
    return Image.asset(fallbackAsset, width: width, height: height, fit: fit);
  }

  Widget _buildPlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.8),
        );
  }

  @override
  Widget build(BuildContext context) {
    final raw = (imageUrl ?? '').trim();
    final localPath = _resolveLocalPath(raw);
    final remoteUrl = _resolveRemoteUrl(raw);
    final cacheWidth = _toCacheDimension(context, width);
    final cacheHeight = _toCacheDimension(context, height);

    if (localPath != null) {
      return Image.file(
        File(localPath),
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildFallback(),
      );
    }

    if (remoteUrl != null) {
      return CachedNetworkImage(
        imageUrl: remoteUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        maxWidthDiskCache: cacheWidth,
        maxHeightDiskCache: cacheHeight,
        fadeInDuration: 300.ms,
        placeholder: (context, _) => _buildPlaceholder(context),
        errorWidget: (_, _, _) => _buildFallback(),
      );
    }

    return _buildFallback();
  }
}
