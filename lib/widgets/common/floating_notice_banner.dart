import 'package:flutter/material.dart';

enum NoticeBannerTone {
  error,
  warning,
  success,
  info,
}

class AnimatedFloatingNoticeBanner extends StatelessWidget {
  const AnimatedFloatingNoticeBanner({
    super.key,
    required this.visible,
    required this.message,
    this.icon,
    this.tone = NoticeBannerTone.info,
    this.maxWidth = 560,
    this.iconColor,
    this.shellColor,
    this.surfaceColor,
  });

  final bool visible;
  final String message;
  final IconData? icon;
  final NoticeBannerTone tone;
  final double maxWidth;
  final Color? iconColor;
  final Color? shellColor;
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, -1.1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: visible ? 1 : 0,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            scale: visible ? 1 : 0.98,
            child: FloatingNoticeBanner(
              message: message,
              icon: icon,
              tone: tone,
              maxWidth: maxWidth,
              iconColor: iconColor,
              shellColor: shellColor,
              surfaceColor: surfaceColor,
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingNoticeBanner extends StatelessWidget {
  const FloatingNoticeBanner({
    super.key,
    required this.message,
    this.icon,
    this.tone = NoticeBannerTone.info,
    this.maxWidth = 560,
    this.iconColor,
    this.shellColor,
    this.surfaceColor,
  });

  final String message;
  final IconData? icon;
  final NoticeBannerTone tone;
  final double maxWidth;
  final Color? iconColor;
  final Color? shellColor;
  final Color? surfaceColor;

  IconData _defaultIcon() {
    switch (tone) {
      case NoticeBannerTone.error:
        return Icons.error_outline_rounded;
      case NoticeBannerTone.warning:
        return Icons.warning_amber_rounded;
      case NoticeBannerTone.success:
        return Icons.check_circle_outline_rounded;
      case NoticeBannerTone.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _defaultIconColor() {
    switch (tone) {
      case NoticeBannerTone.error:
        return const Color(0xFFE11D48);
      case NoticeBannerTone.warning:
        return const Color(0xFFD97706);
      case NoticeBannerTone.success:
        return const Color(0xFF15803D);
      case NoticeBannerTone.info:
        return const Color(0xFF2563EB);
    }
  }

  Color _defaultShellColor() {
    switch (tone) {
      case NoticeBannerTone.error:
        return const Color(0xFFFFD6DB);
      case NoticeBannerTone.warning:
        return const Color(0xFFFFE7C2);
      case NoticeBannerTone.success:
        return const Color(0xFFDDF6E7);
      case NoticeBannerTone.info:
        return const Color(0xFFDCEBFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedIcon = icon ?? _defaultIcon();
    final resolvedIconColor = iconColor ?? _defaultIconColor();
    final resolvedShellColor = shellColor ?? _defaultShellColor();
    final resolvedSurfaceColor = surfaceColor ?? Colors.white;

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: resolvedShellColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0x33B91C1C),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: resolvedSurfaceColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: resolvedIconColor.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        resolvedIcon,
                        size: 14,
                        color: resolvedIconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
