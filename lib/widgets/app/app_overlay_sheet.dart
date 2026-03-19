import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppOverlaySheet extends StatefulWidget {
  final Widget child;

  /// Panel size
  final double height;
  final double? width;

  /// Styling
  final BorderRadius borderRadius;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  /// Behavior
  final VoidCallback? onClose;
  final bool dismissOnBarrierTap;
  final Color barrierColor;

  /// Optional header handle
  final bool showHandle;

  const AppOverlaySheet({
    super.key,
    required this.child,
    this.height = 681,
    this.width,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(32),
      topRight: Radius.circular(32),
    ),
    this.shadows,
    this.padding = const EdgeInsets.only(top: 16, bottom: 16),
    this.backgroundColor,
    this.onClose,
    this.showHandle = false,
    this.dismissOnBarrierTap = true,
    this.barrierColor = const Color(0x66000000),
  });

  @override
  State<AppOverlaySheet> createState() => _AppOverlaySheetState();
}

class _AppOverlaySheetState extends State<AppOverlaySheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (_isClosing) return;
    _isClosing = true;

    await _controller.reverse();
    if (!mounted) return;

    if (widget.onClose != null) {
      widget.onClose!.call();
    } else {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final screenSize = media.size;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: Stack(
          children: [
            /// Barrier / overlay
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.dismissOnBarrierTap ? close : null,
                child: Container(
                  color: widget.barrierColor,
                ),
              ),
            ),

            /// Bottom sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: SlideTransition(
                position: _slideAnimation,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: widget.width ?? screenSize.width,
                    constraints: BoxConstraints(
                      maxHeight: widget.height,
                    ),
                    decoration: ShapeDecoration(
                      color: widget.backgroundColor ?? scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: widget.borderRadius,
                      ),
                      shadows: widget.shadows ??
                          [
                            BoxShadow(
                              color: scheme.shadow.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 3),
                            ),
                          ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: widget.padding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.showHandle) ...[
                              Center(
                                child: Container(
                                  width: 55,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: scheme.onSurfaceVariant.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            widget.child,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}