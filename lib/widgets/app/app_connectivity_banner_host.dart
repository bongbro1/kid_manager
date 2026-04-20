import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kid_manager/viewmodels/app_connectivity_vm.dart';
import 'package:provider/provider.dart';

const _offlineBackdropHeight = 70.0;
const _offlineAnimationDuration = Duration(milliseconds: 280);
const _offlineAnimationCurve = Curves.easeOutCubic;
const _offlineBackdropBlurSigma = 16.0;

class AppConnectivityBannerHost extends StatelessWidget {
  const AppConnectivityBannerHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isOffline = context.select<AppConnectivityVm, bool>(
      (vm) => vm.state == AppConnectivityState.offline,
    );
    final animationTarget = isOffline ? 1.0 : 0.0;
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + _offlineBackdropHeight,
          child: IgnorePointer(
            ignoring: true,
            child: const _ConnectivityTopBackdrop()
                .animate(target: animationTarget)
                .fade(
                  begin: 0,
                  end: 1,
                  duration: _offlineAnimationDuration,
                  curve: _offlineAnimationCurve,
                )
                .slideY(
                  begin: -0.10,
                  end: 0,
                  duration: _offlineAnimationDuration,
                  curve: _offlineAnimationCurve,
                ),
          ),
        ),
        Positioned(
          top: 0,
          left: 18,
          right: 18,
          child: IgnorePointer(
            ignoring: !isOffline,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _OfflineNetworkBanner(message: _messageFor(context))
                    .animate(target: animationTarget)
                    .fade(
                      begin: 0,
                      end: 1,
                      duration: _offlineAnimationDuration,
                      curve: _offlineAnimationCurve,
                    )
                    .slideY(
                      begin: -0.18,
                      end: 0,
                      duration: _offlineAnimationDuration,
                      curve: _offlineAnimationCurve,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _messageFor(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'vi') {
      return 'B\u1ea1n kh\u00f4ng c\u00f3 internet, vui l\u00f2ng ki\u1ec3m tra k\u1ebft n\u1ed1i';
    }
    return 'No internet connection. Please check your network.';
  }
}

class _ConnectivityTopBackdrop extends StatelessWidget {
  const _ConnectivityTopBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _OfflineBackdropOuterGlowPainter()),
          ),
        ),
        ClipPath(
          clipper: const _OfflineBackdropClipper(),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            fit: StackFit.expand,
            children: const [
              Positioned.fill(child: _OfflineBackdropBlurLayer()),
              Positioned.fill(child: _OfflineBackdropTintLayer()),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _OfflineBackdropPainter(),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Path _buildOfflineBackdropPath(Size size) {
  final w = size.width;
  final h = size.height;
  final sideY = h * 0.65;

  return Path()
    ..moveTo(0, 0)
    ..lineTo(0, sideY)
    ..quadraticBezierTo(w * 0.5, h + 10, w, sideY)
    ..lineTo(w, 0)
    ..close();
}

class _OfflineBackdropBlurLayer extends StatelessWidget {
  const _OfflineBackdropBlurLayer();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: _offlineBackdropBlurSigma,
        sigmaY: _offlineBackdropBlurSigma,
      ),
      child: const ColoredBox(color: Color(0x12FFFFFF)),
    );
  }
}

class _OfflineBackdropTintLayer extends StatelessWidget {
  const _OfflineBackdropTintLayer();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xC8F23F54),
            Color(0xE0E94C61),
            Color(0x80F06D7B),
            Color(0x14F59AA3),
          ],
          stops: [0.0, 0.34, 0.72, 1.0],
        ),
      ),
    );
  }
}

class _OfflineBackdropClipper extends CustomClipper<Path> {
  const _OfflineBackdropClipper();

  @override
  Path getClip(Size size) => _buildOfflineBackdropPath(size);

  @override
  bool shouldReclip(covariant _OfflineBackdropClipper oldClipper) => false;
}

class _OfflineBackdropOuterGlowPainter extends CustomPainter {
  const _OfflineBackdropOuterGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildOfflineBackdropPath(size);

    canvas.drawPath(
      path.shift(const Offset(0, 4)),
      Paint()
        ..color = const Color(0x22FF8E9B)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );

    canvas.drawPath(
      path.shift(const Offset(0, 8)),
      Paint()
        ..color = const Color(0x12FFD5DB)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 34),
    );
  }

  @override
  bool shouldRepaint(covariant _OfflineBackdropOuterGlowPainter oldDelegate) {
    return false;
  }
}

class _OfflineBackdropPainter extends CustomPainter {
  const _OfflineBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -1.08),
          radius: 1.04,
          colors: [Color(0x60FF8A96), Color(0x24FF9FAA), Color(0x00FFFFFF)],
          stops: [0.0, 0.42, 1.0],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [Color(0x20FFFFFF), Color(0x10FFFFFF), Color(0x00FFFFFF)],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
          stops: [0.0, 0.28],
        ).createShader(rect),
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00FFFFFF),
            Color(0x00FFFFFF),
            Color(0x0FFFFFFF),
            Color(0x22FFFFFF),
          ],
          stops: [0.0, 0.48, 0.78, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _OfflineBackdropPainter oldDelegate) => false;
}

class _OfflineNetworkBanner extends StatelessWidget {
  const _OfflineNetworkBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7F8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE44B62), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE44B62).withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                size: 20,
                color: Color(0xFFE44B62),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      message,
                      maxLines: 1,
                      softWrap: false,
                      style: (textTheme.titleSmall ?? const TextStyle())
                          .copyWith(
                            color: const Color(0xFFE44B62),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 1.0,
                            decoration: TextDecoration.none,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
