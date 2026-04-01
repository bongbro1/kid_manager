import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kid_manager/core/responsive.dart';

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

    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final size = media.size;
    final horizontalGap = context.adaptiveHorizontalPadding(
      compact: 12,
      regular: 24,
    );
    final availableWidth = math.max(0, size.width - (horizontalGap * 2));
    final availableHeight = math.max(
      0,
      size.height - media.padding.vertical - 24,
    );
    final dialogMaxWidth = math.min(widget.width, availableWidth).toDouble();
    final dialogMaxHeight = math
        .min(widget.maxHeight, availableHeight)
        .toDouble();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          /// BACKGROUND OVERLAY
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onBackgroundTap ?? _close,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.4),
              ),
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
                      maxWidth: dialogMaxWidth,
                      maxHeight: dialogMaxHeight,
                    ),
                    child: Material(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      clipBehavior: Clip.antiAlias,
                      elevation: theme.brightness == Brightness.light ? 16 : 0,
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
