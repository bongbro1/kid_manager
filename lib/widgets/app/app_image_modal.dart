import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Gọi hàm này để mở modal
Future<void> showImageModal(
  BuildContext context, {
  required List<ImageProvider> images,
  int initialIndex = 0,
  Future<void> Function(int index, File file)? onReplace, // <- thêm
}) {
  assert(images.isNotEmpty);
  final safeIndex = initialIndex.clamp(0, images.length - 1);

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'image_modal',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, __) {
      return _ImageModal(
        images: images,
        initialIndex: safeIndex,
        onReplace: onReplace,
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _ImageModal extends StatefulWidget {
  const _ImageModal({
    required this.images,
    required this.initialIndex,
    this.onReplace,
  });

  final List<ImageProvider> images;
  final int initialIndex;
  final Future<void> Function(int index, File file)? onReplace;

  @override
  State<_ImageModal> createState() => _ImageModalState();
}

class _ImageModalState extends State<_ImageModal> {
  late final PageController _controller;
  late int _index;
  late List<ImageProvider> _images;

  final _picker = ImagePicker();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _images = List<ImageProvider>.from(widget.images);
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  Future<void> _openMenu() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Thay đổi ảnh'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickAndReplace();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Đóng'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndReplace() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final XFile? xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (xfile == null) return;

      final file = File(xfile.path);

      // Update UI ngay
      setState(() {
        _images[_index] = FileImage(file);
      });

      // Gọi callback để bạn lưu/upload
      if (widget.onReplace != null) {
        await widget.onReplace!(_index, file);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overlay = const Color(0xB2696969); // #696969B2

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Overlay bắt tap để đóng
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: Container(color: overlay),
            ),
          ),

          if (widget.onReplace != null)
            // ✅ Nút ... ở góc trên-trái của overlay
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _busy ? null : _openMenu,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // Nội dung modal
          Center(
            child: GestureDetector(
              onTap: () {},
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.transparent,
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.92,
                        maxHeight: MediaQuery.of(context).size.height * 0.75,
                      ),
                      child: (_images.length == 1)
                          ? _ZoomableImage(image: _images.first)
                          : PageView.builder(
                              controller: _controller,
                              itemCount: _images.length,
                              onPageChanged: (i) => setState(() => _index = i),
                              itemBuilder: (_, i) =>
                                  _ZoomableImage(image: _images[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_busy)
            const Positioned.fill(
              child: IgnorePointer(
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ảnh có hỗ trợ pinch-to-zoom + pan (InteractiveViewer)
class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Image(image: image, fit: BoxFit.contain),
    );
  }
}


// cách dùng

// 1 ảnh
// showImageModal(
//   context,
//   images: [NetworkImage('https://...')],
// );

// // nhiều ảnh + mở từ ảnh thứ 2
// showImageModal(
//   context,
//   images: [
//     NetworkImage('https://.../1.jpg'),
//     NetworkImage('https://.../2.jpg'),
//     AssetImage('assets/3.png'),
//   ],
//   initialIndex: 1,
// );