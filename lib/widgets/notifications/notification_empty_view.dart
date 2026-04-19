import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';

class NotificationEmptyView extends StatefulWidget {
  const NotificationEmptyView({super.key});

  @override
  State<NotificationEmptyView> createState() => _NotificationEmptyViewState();
}

class _NotificationEmptyViewState extends State<NotificationEmptyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: AppScrollEffects.physics,
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(constraints.maxHeight - 56, 280),
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final progress = _controller.value;
                  final floatY = math.sin(progress * math.pi * 2) * 7;
                  final floatX = math.cos(progress * math.pi * 2) * 3;
                  final pulse =
                      0.96 + (math.sin(progress * math.pi * 2) * 0.04);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: Offset(floatX, floatY),
                        child: Transform.scale(
                          scale: pulse,
                          child: _EmptyInboxArtwork(progress: progress),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.notificationsEmptyTitle,
                        textAlign: TextAlign.center,
                        style: typography.screenTitle.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          l10n.notificationsEmptySubtitle,
                          textAlign: TextAlign.center,
                          style: typography.body.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyInboxArtwork extends StatelessWidget {
  const _EmptyInboxArtwork({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final glow = 0.18 + ((math.sin(progress * math.pi * 2) + 1) * 0.03);
    final badgeOffset = math.sin(progress * math.pi * 2) * 5;
    final chipDrift = math.cos(progress * math.pi * 2) * 4;

    return SizedBox(
      width: 280,
      height: 214,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 12,
            child: Container(
              width: 214,
              height: 214,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withValues(alpha: glow),
                    scheme.primary.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 54,
            child: Transform.rotate(
              angle: -0.14,
              child: _NotificationGhostCard(
                color: scheme.primary.withValues(alpha: 0.08),
                borderColor: scheme.primary.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 40,
            child: Transform.rotate(
              angle: 0.12,
              child: _NotificationGhostCard(
                color: scheme.tertiary.withValues(alpha: 0.09),
                borderColor: scheme.tertiary.withValues(alpha: 0.16),
              ),
            ),
          ),
          Container(
            width: 220,
            height: 164,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 18,
                  right: 18,
                  top: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: scheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GhostLine(
                              width: 90,
                              color: scheme.onSurface.withValues(alpha: 0.10),
                            ),
                            const SizedBox(height: 9),
                            _GhostLine(
                              width: 132,
                              color: scheme.onSurface.withValues(alpha: 0.06),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 20,
                  child: Row(
                    children: [
                      _GhostChip(
                        icon: Icons.check_circle_rounded,
                        label: '',
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Transform.translate(
                        offset: Offset(chipDrift, 0),
                        child: _GhostChip(
                          icon: Icons.favorite_rounded,
                          label: '',
                          color: scheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -10 + badgeOffset,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6B6B),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF6B6B,
                          ).withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationGhostCard extends StatelessWidget {
  const _NotificationGhostCard({
    required this.color,
    required this.borderColor,
  });

  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GhostLine(width: 52, color: Colors.white.withValues(alpha: 0.78)),
          const SizedBox(height: 10),
          _GhostLine(width: 92, color: Colors.white.withValues(alpha: 0.48)),
          const SizedBox(height: 7),
          _GhostLine(width: 70, color: Colors.white.withValues(alpha: 0.34)),
        ],
      ),
    );
  }
}

class _GhostChip extends StatelessWidget {
  const _GhostChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (label.isNotEmpty) ...[const SizedBox(width: 6), Text(label)],
        ],
      ),
    );
  }
}

class _GhostLine extends StatelessWidget {
  const _GhostLine({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
