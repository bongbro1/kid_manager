import 'package:flutter/material.dart';
import 'package:kid_manager/app.dart';
import 'package:kid_manager/core/app_languages.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/locale_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/change_password_screen.dart';
import 'package:kid_manager/views/setting_pages/widgets/language_selector_sheet.dart';
import 'package:kid_manager/views/setting_pages/widgets/theme_selector_sheet.dart';
import 'package:provider/provider.dart';

enum AppLanguageMode { en, vn, cn }

class AppAppearanceScreen extends StatefulWidget {
  const AppAppearanceScreen({super.key});

  @override
  State<AppAppearanceScreen> createState() => _AppAppearanceScreenState();
}

class _AppAppearanceScreenState extends State<AppAppearanceScreen> {
  bool isDarkMode = false;
  bool notificationOn = true;

  void _openThemeSelector() async {
    final result = await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const ThemeSelectorSheet();
      },
    );

    if (result != null) {
      if (!mounted) return;
      final storage = context.read<StorageService>();
      final color = result['color'] as Color;
      final isDark = result['isDark'] as bool;

      await storage.setInt(StorageKeys.themeColor, color.toARGB32());
      await storage.setBool(StorageKeys.isDarkMode, isDark);

      /// đợi animation sheet đóng xong
      await Future.delayed(const Duration(milliseconds: 220));

      if (!mounted) return;
      MyApp.of(context).updateTheme(color, isDark);
    }
  }

  void _openLanguageSelector() async {
    final result = await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return const LanguageSelectorSheet();
      },
    );

    if (result != null) {
      if (!mounted) return;
      final storage = context.read<StorageService>();
      final lang = result['lang'] as String;

      await storage.setString(StorageKeys.language, lang);

      /// đợi animation sheet đóng
      await Future.delayed(const Duration(milliseconds: 220));

      if (!mounted) return;
      MyApp.of(context).updateLanguage(lang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 20,
    );
    final itemHorizontalMargin = (horizontalPadding - 4)
        .clamp(8.0, 20.0)
        .toDouble();

    final localeVm = context.watch<LocaleVm>();
    final userVm = context.watch<UserVm>();
    final currentLang = localeVm.locale.languageCode;
    final langName = AppLanguages.getName(currentLang);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        centerTitle: true,
        title: Text(
          l10n.appAppearanceTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20
          ),
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ===== ỨNG DỤNG =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    l10n.appAppearanceSectionApp,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: .6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      fontFamily: 'Poppins',
                      fontSize: 13
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _settingItem(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.appAppearanceThemeLabel,
                  subtitle: l10n.appAppearanceThemeSubtitle,
                  onTap: _openThemeSelector,
                  horizontalMargin: itemHorizontalMargin,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDark
                            ? l10n.appAppearanceThemeDark
                            : l10n.appAppearanceThemeLight,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurface.withValues(alpha: .7),
                      ),
                    ],
                  ),
                ),
                _settingItem(
                  icon: Icons.language,
                  title: l10n.languageSetting,
                  subtitle: l10n.changeLanguagePrompt,
                  onTap: _openLanguageSelector,
                  horizontalMargin: itemHorizontalMargin,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        langName,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurface.withValues(alpha: .7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                /// ===== BẢO MẬT =====
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Text(
                    l10n.appAppearanceSectionSecurity,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: .6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      fontFamily: 'Poppins',
                      fontSize: 13
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (userVm.canChangePassword)
                  _settingItem(
                    icon: Icons.lock_outline,
                    title: l10n.appAppearanceChangePasswordTitle,
                    subtitle: l10n.appAppearanceChangePasswordSubtitle,
                    horizontalMargin: itemHorizontalMargin,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: scheme.onSurface.withValues(alpha: .7),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                _settingItem(
                  icon: Icons.notifications_none,
                  title: l10n.appAppearanceNotificationsTitle,
                  subtitle: l10n.appAppearanceNotificationsSubtitle,
                  horizontalMargin: itemHorizontalMargin,
                  trailing: Switch(
                    value: notificationOn,
                    activeThumbColor: scheme.primary,
                    onChanged: (value) {
                      setState(() => notificationOn = value);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ===== Setting Item Widget =====
  Widget _settingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required double horizontalMargin,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: 6,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              /// icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),

              /// text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB6C4D7),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
