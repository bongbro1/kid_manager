import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';

enum AppThemeMode { system, light, dark }

class AppAppearanceScreen extends StatefulWidget {
  const AppAppearanceScreen({super.key});

  @override
  State<AppAppearanceScreen> createState() => _AppAppearanceScreenState();
}

class _AppAppearanceScreenState extends State<AppAppearanceScreen> {
  AppThemeMode _selectedTheme = AppThemeMode.system;

  String _themeLabel(AppLocalizations l10n, AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.system:
        return l10n.appAppearanceThemeSystem;
      case AppThemeMode.light:
        return l10n.appAppearanceThemeLight;
      case AppThemeMode.dark:
        return l10n.appAppearanceThemeDark;
    }
  }

  Future<void> _showThemeSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<AppThemeMode>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeOptionSheet<AppThemeMode>(
        title: l10n.appAppearanceSelectThemeTitle,
        initialValue: _selectedTheme,
        options: [
          OptionItem(l10n.appAppearanceThemeSystem, AppThemeMode.system),
          OptionItem(l10n.appAppearanceThemeLight, AppThemeMode.light),
          OptionItem(l10n.appAppearanceThemeDark, AppThemeMode.dark),
        ],
        onConfirm: (theme) {
          setState(() => _selectedTheme = theme);
        },
      ),
    );

    if (result != null) {
      debugPrint('Theme selected: $result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: AppIcon(
                        path: 'assets/icons/back.svg',
                        type: AppIconType.svg,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.appAppearanceTitle,
                        style: const TextStyle(
                          color: Color(0xFF222B45),
                          fontSize: 20,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showThemeSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.appAppearanceThemeLabel,
                      style: const TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.38,
                        letterSpacing: -0.41,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _themeLabel(l10n, _selectedTheme),
                      style: const TextStyle(
                        color: Color(0xFF212121),
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.38,
                        letterSpacing: -0.41,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF9E9E9E),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }
}

class OptionRadioRow<T> extends StatelessWidget {
  final String title;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  const OptionRadioRow({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      child: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: (next) {
                if (next != null) {
                  onChanged(next);
                }
              },
              activeColor: const Color(0xFF3366FF),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF212121)
                    : const Color(0xFF4C4C4C),
                fontSize: 16,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptionItem<T> {
  final String label;
  final T value;

  const OptionItem(this.label, this.value);
}

class ChangeOptionSheet<T> extends StatefulWidget {
  final String title;
  final T initialValue;
  final List<OptionItem<T>> options;
  final ValueChanged<T> onConfirm;

  const ChangeOptionSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.options,
    required this.onConfirm,
  });

  @override
  State<ChangeOptionSheet<T>> createState() => _ChangeOptionSheetState<T>();
}

class _ChangeOptionSheetState<T> extends State<ChangeOptionSheet<T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppOverlaySheet(
      height: 300,
      showHandle: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.options.map(
              (option) => OptionRadioRow<T>(
                title: option.label,
                value: option.value,
                groupValue: _selected,
                onChanged: (next) {
                  setState(() => _selected = next);
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  width: 167,
                  height: 50,
                  text: l10n.cancelButton,
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: const Color(0xFFE6F5FF),
                  foregroundColor: const Color(0xFF3A7DFF),
                ),
                AppButton(
                  width: 167,
                  height: 50,
                  text: l10n.confirmButton,
                  onPressed: () {
                    widget.onConfirm(_selected);
                    Navigator.pop(context, _selected);
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
