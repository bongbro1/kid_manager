import 'package:flutter/material.dart';

class NotificationModal extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final VoidCallback? onBackgroundTap;

  const NotificationModal({
    super.key,
    required this.child,
    this.width = 339,
    this.height = 291,
    this.onBackgroundTap,
  });

  /// 👇 THÊM CÁI NÀY
  static Future<void> show(
    BuildContext context, {
    required Widget child,
    double width = 339,
    double height = 291,
    VoidCallback? onBackgroundTap,
  }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.transparent,
      builder: (_) => Center(
        child: child,
      ),
    );
  }

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // từ dưới lên
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  Future<void> _close() async {
    if (_isClosing) return;
    _isClosing = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      removeBottom: true,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// BACKGROUND
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBackgroundTap ?? _close,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0x66000000),
                ),
              ),
            ),

            /// MODAL BOX
            SlideTransition(
              position: _slideAnimation,
              child: AbsorbPointer(
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Cách gọi

// NotificationModal.show(
//   context,
//   child: AppNoticeCard(type: AppNoticeType.success),
// );