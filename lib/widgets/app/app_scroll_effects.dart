import 'dart:async';

import 'package:flutter/material.dart';

class AppScrollEffects {
  static const ScrollPhysics physics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
}

class AppScrollReveal extends StatefulWidget {
  const AppScrollReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.stagger = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 420),
    this.beginOffset = const Offset(0, 0.06),
    this.beginScale = 0.985,
    this.curve = Curves.easeOutCubic,
    this.enabled = true,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration stagger;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;
  final Curve curve;
  final bool enabled;

  @override
  State<AppScrollReveal> createState() => _AppScrollRevealState();
}

class _AppScrollRevealState extends State<AppScrollReveal> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.enabled) {
      _visible = true;
      return;
    }

    final delay = widget.delay + (widget.stagger * widget.index);
    _timer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : widget.beginOffset,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedScale(
        scale: _visible ? 1 : widget.beginScale,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
