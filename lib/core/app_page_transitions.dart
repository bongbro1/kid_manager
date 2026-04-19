import 'package:flutter/material.dart';

class AppPageTransitions {
  static const Duration forwardDuration = Duration(milliseconds: 360);
  static const Duration reverseDuration = Duration(milliseconds: 280);

  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: SocialPageTransitionsBuilder(),
      TargetPlatform.iOS: SocialPageTransitionsBuilder(),
      TargetPlatform.macOS: SocialPageTransitionsBuilder(),
      TargetPlatform.windows: SocialPageTransitionsBuilder(),
      TargetPlatform.linux: SocialPageTransitionsBuilder(),
      TargetPlatform.fuchsia: SocialPageTransitionsBuilder(),
    },
  );

  static Route<T> modalRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool opaque = true,
    bool barrierDismissible = false,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      opaque: opaque,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      transitionDuration: forwardDuration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: buildModalTransition,
    );
  }

  static Route<T> route<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
    bool fullscreenDialog = false,
    bool maintainState = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      fullscreenDialog: fullscreenDialog,
      maintainState: maintainState,
      transitionDuration: forwardDuration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: buildSocialTransition,
    );
  }

  static Widget buildSocialTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = animation.drive(
      Tween<double>(begin: 0.82, end: 1).chain(
        CurveTween(curve: const Interval(0, 1, curve: Curves.easeOutCubic)),
      ),
    );
    final slide = animation.drive(
      Tween<Offset>(
        begin: const Offset(0.14, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final scale = animation.drive(
      Tween<double>(
        begin: 0.972,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final outgoingSlide = secondaryAnimation.drive(
      Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.05, 0),
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final outgoingFade = secondaryAnimation.drive(
      Tween<double>(
        begin: 1,
        end: 0.94,
      ).chain(CurveTween(curve: Curves.easeOut)),
    );

    return SlideTransition(
      position: outgoingSlide,
      child: FadeTransition(
        opacity: outgoingFade,
        child: SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          ),
        ),
      ),
    );
  }

  static Widget buildModalTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = animation.drive(
      Tween<double>(begin: 0.86, end: 1).chain(
        CurveTween(curve: const Interval(0, 1, curve: Curves.easeOutCubic)),
      ),
    );
    final slide = animation.drive(
      Tween<Offset>(
        begin: const Offset(0, 0.035),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );
    final scale = animation.drive(
      Tween<double>(
        begin: 0.992,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ScaleTransition(scale: scale, child: child),
      ),
    );
  }
}

class SocialPageTransitionsBuilder extends PageTransitionsBuilder {
  const SocialPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppPageTransitions.forwardDuration;

  @override
  Duration get reverseTransitionDuration => AppPageTransitions.reverseDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions.buildSocialTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}
