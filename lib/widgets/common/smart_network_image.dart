import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SmartNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int maxRetries;
  final Duration requestTimeout;
  final Duration retryDelay;

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

  @override
  State<SmartNetworkImage> createState() => _SmartNetworkImageState();
}

class _SmartNetworkImageState extends State<SmartNetworkImage> {
  static final Map<String, Uint8List> _bytesCache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List?>> _inFlight =
      <String, Future<Uint8List?>>{};

  Uint8List? _bytes;
  bool _isLoading = false;
  bool _hasError = false;
  int _ticket = 0;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant SmartNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveImage();
    }
  }

  String? _normalizeUrl(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return value;
  }

  Future<void> _resolveImage() async {
    final currentTicket = ++_ticket;
    final raw = (widget.imageUrl ?? '').trim();
    final url = _normalizeUrl(raw);

    // local file
    if (raw.startsWith('/')) {
      if (!mounted || currentTicket != _ticket) return;
      setState(() {
        _bytes = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // invalid / empty url => fallback thật sự
    if (url == null) {
      if (!mounted || currentTicket != _ticket) return;
      setState(() {
        _bytes = null;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    final cached = _bytesCache[url];
    if (cached != null) {
      if (!mounted || currentTicket != _ticket) return;
      setState(() {
        _bytes = cached;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    if (!mounted || currentTicket != _ticket) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      // giữ _bytes cũ nếu có để tránh flicker khi đổi ảnh cùng URL
    });

    final pending = _inFlight[url] ??= _fetchWithRetry(url);
    final result = await pending;

    if (identical(_inFlight[url], pending)) {
      _inFlight.remove(url);
    }

    if (!mounted || currentTicket != _ticket) return;

    if (result != null) {
      _bytesCache[url] = result;
      setState(() {
        _bytes = result;
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    setState(() {
      _bytes = null;
      _isLoading = false;
      _hasError = true;
    });
  }

  Future<Uint8List?> _fetchWithRetry(String url) async {
    final uri = Uri.parse(url);
    final client = http.Client();
    Object? lastError;

    try {
      for (var attempt = 0; attempt <= widget.maxRetries; attempt++) {
        try {
          final resp = await client.get(uri).timeout(widget.requestTimeout);
          final bytes = resp.bodyBytes;

          if (resp.statusCode >= 200 &&
              resp.statusCode < 300 &&
              bytes.isNotEmpty) {
            return bytes;
          }

          lastError =
              'HTTP ${resp.statusCode} (bytes=${bytes.length}) for $url';
        } catch (e) {
          lastError = e;
        }

        if (attempt < widget.maxRetries) {
          await Future.delayed(widget.retryDelay * (attempt + 1));
        }
      }

      debugPrint('SmartNetworkImage fail url=$url err=$lastError');
      return null;
    } finally {
      client.close();
    }
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: widget.width,
      height: widget.height,
      color: scheme.surfaceContainerHighest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = (widget.imageUrl ?? '').trim();

    if (raw.startsWith('/')) {
      return Image.file(
        File(raw),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => Image.asset(
          widget.fallbackAsset,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.asset(
          widget.fallbackAsset,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }

    if (_isLoading) {
      return _buildLoadingPlaceholder(context);
    }

    if (_hasError || _normalizeUrl(raw) == null) {
      return Image.asset(
        widget.fallbackAsset,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
      );
    }

    return _buildLoadingPlaceholder(context);
  }
}