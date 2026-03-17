import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';

class AppTheme {
  /// LIGHT THEME
  static ThemeData light({Color seedColor = AppColors.primary}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      primary: seedColor,
      secondary: seedColor,

      /// nền app
      background: const Color(0xFFF7F7F7),

      /// card / container
      surface: Colors.white,

      /// border
      outline: const Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      scaffoldBackgroundColor: scheme.background,

      /// APPBAR
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),

      /// CARD
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: BorderSide(color: scheme.outline),
        ),
      ),

      /// DIVIDER
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),

      /// INPUT
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor),
        ),
      ),
    );
  }

  /// DARK THEME
  static ThemeData dark({Color seedColor = AppColors.primary}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    final scheme = base.copyWith(
      primary: seedColor,
      secondary: seedColor,

      /// nền tối chuẩn hơn
      background: const Color(0xFF0F172A),

      /// surface card
      surface: const Color(0xFF242E40),

      /// border
      outline: const Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      scaffoldBackgroundColor: scheme.background,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          side: BorderSide(color: scheme.outline),
        ),
      ),

      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seedColor),
        ),
      ),
    );
  }
}
