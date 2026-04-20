import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';

class ThemeSelectorSheet extends StatefulWidget {
  const ThemeSelectorSheet({super.key});

  @override
  State<ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<ThemeSelectorSheet> {
  final List<Color> colors = const [
    Color(0xFFFF9EB7),
    Color(0xFFFCB022),
    Color.fromARGB(255, 62, 179, 124),
    Color(0xFF4BA2FF),
  ];

  int selectedColor = 0;
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final storage = context.read<StorageService>();
    final savedColorValue =
        storage.getInt(StorageKeys.themeColor) ??
        colors[colors.length - 1].value;
    final savedDark = storage.getBool(StorageKeys.isDarkMode) ?? false;

    final index = colors.indexWhere((c) => c.value == savedColorValue);

    setState(() {
      selectedColor = index != -1 ? index : colors.length - 1;
      isDark = savedDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        bottomInset > 0 ? bottomInset + 10 : 28,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            l10n.themeSelectorTitle,
            style: theme.textTheme.titleMedium?.copyWith(),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.themeSelectorSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.6),
            ),
          ),
          const SizedBox(height: 22),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: colors.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final color = colors[index];
              final selected = selectedColor == index;

              return GestureDetector(
                onTap: () => setState(() => selectedColor = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (selected)
                        BoxShadow(
                          color: color.withOpacity(.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: selected
                      ? Icon(Icons.check, color: theme.colorScheme.surface)
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                colors[selectedColor].withOpacity(.08),
                theme.colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: colors[selectedColor],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.themeSelectorDarkMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: Theme.of(
                        context,
                      ).appTypography.itemTitle.fontSize!,
                    ),
                  ),
                ),
                Switch(
                  value: isDark,
                  activeColor: colors[selectedColor],
                  activeTrackColor: colors[selectedColor].withOpacity(.45),
                  inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(
                    .7,
                  ),
                  inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                  onChanged: (v) {
                    setState(() {
                      isDark = v;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors[selectedColor],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final color = colors[selectedColor];
                Navigator.pop(context, {'color': color, 'isDark': isDark});
              },
              child: Text(
                l10n.themeSelectorApplyButton,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
