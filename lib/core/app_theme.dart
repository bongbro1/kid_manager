import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'app_colors.dart';
import 'constants.dart';

@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  final TextStyle screenTitle;
  final TextStyle inlineHeaderTitle;
  final TextStyle title;
  final TextStyle itemTitle;
  final TextStyle body;
  final TextStyle sectionLabel;
  final TextStyle supporting;
  final TextStyle meta;

  const AppTypography({
    required this.screenTitle,
    required this.inlineHeaderTitle,
    required this.title,
    required this.itemTitle,
    required this.body,
    required this.sectionLabel,
    required this.supporting,
    required this.meta,
  });

  factory AppTypography.fromTextTheme(TextTheme textTheme) {
    return AppTypography(
      screenTitle:
          textTheme.titleMedium ??
          const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      inlineHeaderTitle:
          textTheme.titleSmall?.copyWith(fontSize: 17) ??
          const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      title:
          textTheme.titleSmall ??
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      itemTitle:
          textTheme.bodyLarge?.copyWith(fontSize: 15) ??
          const TextStyle(fontSize: 15),
      body: textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
      sectionLabel: textTheme.bodySmall ?? const TextStyle(fontSize: 13),
      supporting: textTheme.labelSmall ?? const TextStyle(fontSize: 12),
      meta:
          textTheme.labelSmall?.copyWith(fontSize: 11, height: 1.2) ??
          const TextStyle(fontSize: 11, height: 1.2),
    );
  }

  @override
  AppTypography copyWith({
    TextStyle? screenTitle,
    TextStyle? inlineHeaderTitle,
    TextStyle? title,
    TextStyle? itemTitle,
    TextStyle? body,
    TextStyle? sectionLabel,
    TextStyle? supporting,
    TextStyle? meta,
  }) {
    return AppTypography(
      screenTitle: screenTitle ?? this.screenTitle,
      inlineHeaderTitle: inlineHeaderTitle ?? this.inlineHeaderTitle,
      title: title ?? this.title,
      itemTitle: itemTitle ?? this.itemTitle,
      body: body ?? this.body,
      sectionLabel: sectionLabel ?? this.sectionLabel,
      supporting: supporting ?? this.supporting,
      meta: meta ?? this.meta,
    );
  }

  @override
  AppTypography lerp(ThemeExtension<AppTypography>? other, double t) {
    if (other is! AppTypography) {
      return this;
    }

    return AppTypography(
      screenTitle:
          TextStyle.lerp(screenTitle, other.screenTitle, t) ?? screenTitle,
      inlineHeaderTitle:
          TextStyle.lerp(inlineHeaderTitle, other.inlineHeaderTitle, t) ??
          inlineHeaderTitle,
      title: TextStyle.lerp(title, other.title, t) ?? title,
      itemTitle: TextStyle.lerp(itemTitle, other.itemTitle, t) ?? itemTitle,
      body: TextStyle.lerp(body, other.body, t) ?? body,
      sectionLabel:
          TextStyle.lerp(sectionLabel, other.sectionLabel, t) ?? sectionLabel,
      supporting: TextStyle.lerp(supporting, other.supporting, t) ?? supporting,
      meta: TextStyle.lerp(meta, other.meta, t) ?? meta,
    );
  }
}

extension AppThemeTypographyX on ThemeData {
  AppTypography get appTypography =>
      extension<AppTypography>() ?? AppTypography.fromTextTheme(textTheme);
}

class AppTheme {
  static const String _fontFamily = 'Poppins';

  static TextStyle _filledButtonTextStyle(TextTheme textTheme, Color color) {
    return (textTheme.titleSmall ??
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ))
        .copyWith(color: color, fontWeight: FontWeight.w600);
  }

  static TextStyle _textButtonTextStyle(TextTheme textTheme, Color color) {
    return (textTheme.labelLarge ??
            const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ))
        .copyWith(color: color, fontWeight: FontWeight.w600);
  }

  static TextTheme _textTheme(ColorScheme scheme, Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark(useMaterial3: true).textTheme
        : ThemeData.light(useMaterial3: true).textTheme;

    return base
        .copyWith(
          /// ===== DISPLAY =====
          displayLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.4,
          ),
          displayMedium: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.22,
            letterSpacing: -0.3,
          ),
          displaySmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.25,
            letterSpacing: -0.2,
          ),

          /// ===== HEADLINE / TITLE =====
          headlineLarge: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.27,
            letterSpacing: -0.2,
          ),
          headlineMedium: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.2,
          ),
          headlineSmall: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.33,
            letterSpacing: -0.1,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: -0.2,
          ),
          titleMedium: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.34,
            letterSpacing: -0.1,
          ),
          titleSmall: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),

          /// ===== BODY =====
          bodyLarge: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
          bodySmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),

          /// ===== LABEL =====
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          labelMedium: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
          labelSmall: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.25,
          ),
        )
        .apply(
          fontFamily: _fontFamily,
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
        );
  }

  /// LIGHT THEME
  static ThemeData light({Color seedColor = AppColors.primary}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final scheme = base.copyWith(
      primary: seedColor,
      secondary: seedColor,
      background: const Color(0xFFF7F7F7),
      surface: Colors.white,
      onPrimary: Colors.white,
      outline: const Color.fromARGB(255, 172, 173, 175),
    );

    final textTheme = _textTheme(scheme, Brightness.light);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      extensions: [AppTypography.fromTextTheme(textTheme)],
      scaffoldBackgroundColor: scheme.background,
      pageTransitionsTheme: AppPageTransitions.theme,

      /// ICON
      iconTheme: IconThemeData(color: scheme.onSurface),

      /// APPBAR
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
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
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.75),
        ),
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

      /// ELEVATED BUTTON
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: _filledButtonTextStyle(textTheme, scheme.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      /// OUTLINED BUTTON
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline),
          textStyle: _filledButtonTextStyle(textTheme, scheme.onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: _filledButtonTextStyle(textTheme, scheme.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      /// TEXT BUTTON
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: _textButtonTextStyle(textTheme, scheme.primary),
        ),
      ),

      /// SNACKBAR
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      /// FLOATING BUTTON
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      /// NAVIGATION BAR
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
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
      background: const Color(0xFF0F172A),
      surface: const Color(0xFF242E40),
      onPrimary: Colors.white,
      outline: const Color(0xFF334155),
    );

    final textTheme = _textTheme(scheme, Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: _fontFamily,
      textTheme: textTheme,
      extensions: [AppTypography.fromTextTheme(textTheme)],
      scaffoldBackgroundColor: scheme.background,
      pageTransitionsTheme: AppPageTransitions.theme,

      iconTheme: IconThemeData(color: scheme.onSurface),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
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
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.75),
        ),
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

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: _filledButtonTextStyle(textTheme, scheme.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.outline),
          textStyle: _filledButtonTextStyle(textTheme, scheme.onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: _filledButtonTextStyle(textTheme, scheme.onPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: _textButtonTextStyle(textTheme, scheme.primary),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
