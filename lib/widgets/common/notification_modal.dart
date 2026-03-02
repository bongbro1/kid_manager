import 'package:flutter/material.dart';

class NotificationModal extends StatefulWidget {
  final Widget child;
  final double width;

  /// Chiều cao tối đa của modal (không phải height cố định)
  final double maxHeight;

  final VoidCallback? onBackgroundTap;

  const NotificationModal({
    super.key,
    required this.child,
    this.width = 339,
    this.maxHeight = 320,
    this.onBackgroundTap,
  });

  static Future<void> show(
      BuildContext context, {
        required Widget child,
        double width = 339,
        double maxHeight = 320,
        VoidCallback? onBackgroundTap,
      }) {
    return showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (_) => NotificationModal(
        width: width,
        maxHeight: maxHeight,
        onBackgroundTap: onBackgroundTap,
        child: child,
      ),
    );
  }

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08), // nhẹ thôi cho đẹp
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
    final maxH = widget.maxHeight.clamp(200, 600).toDouble();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBackgroundTap ?? _close,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(color: const Color(0x66000000)),
            ),
          ),

          // Modal
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: widget.width,
                      maxHeight: maxH,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias, // ✅ bo góc + không tràn
                      elevation: 10,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}