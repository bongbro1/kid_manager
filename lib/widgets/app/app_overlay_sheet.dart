import 'package:flutter/material.dart';

class AppOverlaySheet extends StatelessWidget {
  final Widget child;

  /// Panel size
  final double height;
  final double? width;

  /// Styling
  final Color overlayColor;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final EdgeInsetsGeometry padding;

  /// Behavior
  final bool dismissOnTapOutside;
  final VoidCallback? onClose;

  /// Optional header handle (thanh kéo)
  final bool showHandle;

  const AppOverlaySheet({
    super.key,
    required this.child,
    this.height = 681,
    this.width,
    this.overlayColor = const Color(0x604F4F4F),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(32),
      topRight: Radius.circular(32),
    ),
    this.shadows = const [
      BoxShadow(
        color: Color(0x29000000),
        blurRadius: 30,
        offset: Offset(0, 3),
        spreadRadius: 0,
      )
    ],
    this.padding = const EdgeInsets.only(top: 16, bottom: 16),
    this.dismissOnTapOutside = true,
    this.onClose,
    this.showHandle = false,
  });

  void _close(BuildContext context) {
    if (onClose != null) return onClose!.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Overlay
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismissOnTapOutside ? () => _close(context) : null,
              child: Container(
                decoration: BoxDecoration(color: overlayColor),
              ),
            ),
          ),

          // Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: width ?? MediaQuery.of(context).size.width,
              height: height,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: borderRadius),
                shadows: shadows,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: padding,
                  child: Column(
                    children: [
                      if (showHandle) ...[
                        Center(
                          child: Container(
                            width: 55,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF212121),
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Expanded(child: child),
                    ],
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
