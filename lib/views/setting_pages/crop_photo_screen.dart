import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum CropPhotoType { avatar, cover }

class CropPhotoScreen extends StatefulWidget {
  const CropPhotoScreen({super.key, required this.file, required this.type});

  final File file;
  final CropPhotoType type;

  @override
  State<CropPhotoScreen> createState() => _CropPhotoScreenState();
}

class _CropPhotoScreenState extends State<CropPhotoScreen> {
  final CropController _controller = CropController();

  Uint8List? _imageData;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    final bytes = await widget.file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageData = bytes;
    });
  }

  double get _aspectRatio {
    switch (widget.type) {
      case CropPhotoType.avatar:
        return 1;
      case CropPhotoType.cover:
        return 16 / 9;
    }
  }

  String get _title {
    switch (widget.type) {
      case CropPhotoType.avatar:
        return 'Chỉnh ảnh đại diện';
      case CropPhotoType.cover:
        return 'Chỉnh ảnh bìa';
    }
  }

  Future<File> _saveCropped(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: _isCropping || _imageData == null
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _controller.crop();
                  },
            child: const Text('Xong'),
          ),
        ],
      ),
      body: _imageData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                if (!_isCropping)
                  Column(
                    children: [
                      Expanded(
                        child: Crop(
                          image: _imageData!,
                          controller: _controller,
                          aspectRatio: _aspectRatio,
                          withCircleUi: widget.type == CropPhotoType.avatar,
                          baseColor: Colors.black,
                          maskColor: Colors.black.withOpacity(0.55),
                          radius: 20,
                          cornerDotBuilder: (_, __) {
                            return Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            );
                          },
                          onCropped: (croppedData) async {
                            if (!mounted) return;

                            try {
                              final file = await _saveCropped(croppedData);

                              if (!mounted) return;
                              Navigator.pop(context, file);
                            } catch (e) {
                              setState(() => _isCropping = false);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Không thể crop ảnh'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Hủy'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    setState(() => _isCropping = true);
                                    _controller.crop();
                                  },
                                  child: const Text('Xác nhận'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                if (_isCropping)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }
}
