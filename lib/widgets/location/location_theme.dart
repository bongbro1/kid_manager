import 'package:flutter/material.dart';

bool _isDarkLocationScheme(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark;

Color locationPanelColor(ColorScheme scheme) {
  return Color.alphaBlend(
    scheme.primary.withAlpha(_isDarkLocationScheme(scheme) ? 20 : 10),
    scheme.surface,
  );
}

Color locationPanelMutedColor(ColorScheme scheme) {
  return Color.alphaBlend(
    scheme.primary.withAlpha(_isDarkLocationScheme(scheme) ? 28 : 12),
    scheme.background,
  );
}

Color locationPanelHighlightColor(ColorScheme scheme) {
  return Color.alphaBlend(
    scheme.primary.withAlpha(_isDarkLocationScheme(scheme) ? 40 : 18),
    scheme.surface,
  );
}

Color locationPanelBorderColor(ColorScheme scheme) {
  return Color.alphaBlend(
    scheme.primary.withAlpha(_isDarkLocationScheme(scheme) ? 56 : 22),
    scheme.outline,
  );
}
