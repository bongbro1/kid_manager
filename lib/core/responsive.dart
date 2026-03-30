import 'package:flutter/widgets.dart';

/// Shared responsive policy for mobile layouts.
class ResponsiveBreakpoints {
  static const double compactPhone = 360;
  static const double mediumPhone = 390;
  static const double largePhone = 411;
  static const double tablet = 600;

  static const List<double> qaWidths = <double>[320, 360, 390, 411];

  static const List<double> qaTextScales = <double>[1.0, 1.15, 1.3, 1.5];

  static const double compactHorizontalPadding = 12;
  static const double regularHorizontalPadding = 24;
}

extension ResponsiveContextX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isCompactPhone => screenWidth < ResponsiveBreakpoints.compactPhone;
  bool get isTabletOrLarger => screenWidth >= ResponsiveBreakpoints.tablet;

  double adaptiveHorizontalPadding({
    double compact = ResponsiveBreakpoints.compactHorizontalPadding,
    double regular = ResponsiveBreakpoints.regularHorizontalPadding,
  }) {
    return isCompactPhone ? compact : regular;
  }
}
