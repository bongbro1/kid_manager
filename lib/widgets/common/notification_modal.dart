import 'package:flutter/material.dart';

class NotificationModal extends StatefulWidget {
  final Widget child;
  final double width;
  final double maxHeight;
  final VoidCallback? onBackgroundTap;

  const NotificationModal({
    super.key,
    required this.child,
    this.width = 339,
    this.maxHeight = 400,
    this.onBackgroundTap,
  });

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final curved =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

    _fade = curved;

    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBackgroundTap ?? _close,
            child: FadeTransition(
              opacity: _fade,
              child: Container(color: const Color(0x66000000)),
            ),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: widget.width,
                      maxHeight: widget.maxHeight,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      elevation: 16,
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