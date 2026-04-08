import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  final bool loading;
  final bool skeleton;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  final bool fullWidth;
  final bool outlined;

  final double? width;
  final double? height;

  final double? fontSize;
  final FontWeight? fontWeight;
  final String? fontFamily;

  final double? letterSpacing;
  final double? lineHeight;

  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.skeleton = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.fullWidth = true,
    this.outlined = false,
    this.width,
    this.height,
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.letterSpacing,
    this.lineHeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor =
        backgroundColor ??
        (outlined ? Colors.transparent : theme.colorScheme.primary);

    final fgColor =
        foregroundColor ??
        (outlined ? theme.colorScheme.primary : theme.colorScheme.onPrimary);

    final bool isDisabled = loading || onPressed == null;

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: fgColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: fontFamily ?? 'Poppins',
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        double? effectiveWidth = width;
        if (effectiveWidth != null && constraints.maxWidth.isFinite) {
          effectiveWidth = effectiveWidth.clamp(0, constraints.maxWidth);
        }
        Widget child;
        if (loading) {
          child = SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
          );
        } else if (skeleton) {
          child = Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 72,
                height: 14,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          );
        } else {
          child = IconTheme(
            data: IconThemeData(color: fgColor, size: 18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon case final iconWidget?) ...[
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: fgColor),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, animatedColor, child) {
                      return ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          animatedColor ?? fgColor,
                          BlendMode.srcIn,
                        ),
                        child: child,
                      );
                    },
                    child: iconWidget,
                  ),
                  const SizedBox(width: 8),
                ],
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  style:
                      textStyle ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        Widget button = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(30),
            border: outlined ? Border.all(color: fgColor) : null,
          ),
          child: ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: fgColor,
              disabledBackgroundColor: Colors.transparent,
              disabledForegroundColor: fgColor.withValues(alpha: 0.7),
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              splashFactory: NoSplash.splashFactory,
              padding:
                  padding ??
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              overlayColor: Colors.transparent,
            ),
            child: child,
          ),
        );

        button = AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled ? 0.8 : 1,
          child: button,
        );

        if (height != null) {
          button = ConstrainedBox(
            constraints: BoxConstraints(minHeight: height!),
            child: button,
          );
        }

        if (effectiveWidth != null) {
          button = SizedBox(width: effectiveWidth, child: button);
        } else if (fullWidth) {
          button = SizedBox(width: double.infinity, child: button);
        }

        return button;
      },
    );
  }
}
