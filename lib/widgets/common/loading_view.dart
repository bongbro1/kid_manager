import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasMessage = message != null && message!.trim().isNotEmpty;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final scale = 0.96 + (0.04 * value);

        return Material(
          color: scheme.scrim.withValues(alpha: 0.14 * value),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10 * value,
                      sigmaY: 10 * value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: scale,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.surface.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: scheme.outline.withValues(alpha: 0.12),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 22,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            hasMessage ? 24 : 26,
                            24,
                            hasMessage ? 20 : 26,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SvgLoading(
                                    size: 40,
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              if (hasMessage) ...[
                                const SizedBox(height: 16),
                                Text(
                                  message!,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }
}

class SvgLoading extends StatefulWidget {
  const SvgLoading({super.key, this.size = 60, this.color});

  final double size;
  final Color? color;

  @override
  State<SvgLoading> createState() => _SvgLoadingState();
}

class _SvgLoadingState extends State<SvgLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.color ?? scheme.primary;

    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        'assets/icons/loading.svg',
        width: widget.size,
        height: widget.size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
