import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/image_service.dart';

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

  String _title(AppLocalizations l10n) {
    switch (widget.type) {
      case CropPhotoType.avatar:
        return l10n.cropPhotoAvatarTitle;
      case CropPhotoType.cover:
        return l10n.cropPhotoCoverTitle;
    }
  }

  Future<File> _saveCropped(Uint8List bytes) async {
    return UserPhotoProcessingService.createTempOptimizedFile(
      sourceBytes: bytes,
      type: widget.type == CropPhotoType.avatar
          ? UserPhotoType.avatar
          : UserPhotoType.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final radius = BorderRadius.circular(20);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          _title(l10n),
          style: theme.textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isCropping || _imageData == null
                ? null
                : () {
                    setState(() => _isCropping = true);
                    _controller.crop();
                  },
            child: Text(l10n.cropPhotoDoneButton),
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
                          maskColor: Colors.black.withValues(alpha: 0.55),
                          radius: 20,
                          cornerDotBuilder: (_, _) {
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

                              if (!context.mounted) return;
                              Navigator.of(context).pop(file);
                            } catch (e) {
                              if (!context.mounted) return;
                              setState(() => _isCropping = false);

                              final l10n = AppLocalizations.of(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.cropPhotoFailedMessage),
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
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: radius,
                                    ),
                                  ),
                                  child: Text(l10n.cancelButton),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {
                                    setState(() => _isCropping = true);
                                    _controller.crop();
                                  },
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: radius,
                                    ),
                                  ),
                                  child: Text(l10n.confirmButton),
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
