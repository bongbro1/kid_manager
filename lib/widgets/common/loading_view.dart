import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.scrim.withOpacity(0.6), // 👈 thay overlay màu xám
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 345,
            ),
            child: Container(
              height: 201,
              decoration: BoxDecoration(
                color: scheme.surface, // 👈 thay trắng
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(child: SvgLoading()),
            ),
          ),
        ),
      ),
    );
  }
}

class SvgLoading extends StatefulWidget {
  const SvgLoading({super.key});

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
      duration: const Duration(seconds: 1),
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

    return RotationTransition(
      turns: _controller,
      child: SvgPicture.asset(
        'assets/icons/loading.svg',
        width: 60,
        height: 60,
        colorFilter: ColorFilter.mode(
          scheme.primary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}