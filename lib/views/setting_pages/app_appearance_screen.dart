import 'package:flutter/material.dart';
import 'package:kid_manager/app.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/views/setting_pages/change_password_screen.dart';
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
      final storage = context.read<StorageService>();

      final color = result["color"] as Color;
      final isDark = result["isDark"] as bool;

      await storage.setInt(StorageKeys.themeColor, color.value);
      await storage.setBool(StorageKeys.isDarkMode, isDark);

      /// đợi animation sheet đóng xong
      await Future.delayed(const Duration(milliseconds: 220));

      MyApp.of(context).updateTheme(color, isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: scheme.surface,
        centerTitle: true,
        title: Text(
          "Giao diện ứng dụng",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "ỨNG DỤNG",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      fontFamily: "Poppins",
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _settingItem(
                  icon: Icons.dark_mode_outlined,
                  title: "Giao diện",
                  subtitle: "Thay đổi giao diện sáng/tối",
                  onTap: _openThemeSelector,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isDark ? "Tối" : "Sáng",
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurface.withOpacity(.7),
                      ),
                    ],
                  ),
                ),

                _settingItem(
                  icon: Icons.language,
                  title: "Ngôn ngữ",
                  subtitle: "Chọn ngôn ngữ hiển thị",
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Tiếng Việt",
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurface.withOpacity(.7),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// ===== BẢO MẬT =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "BẢO MẬT",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.7,
                      fontFamily: "Poppins",
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _settingItem(
                  icon: Icons.lock_outline,
                  title: "Đổi mật khẩu",
                  subtitle: "Cập nhật mật khẩu mới",
                  trailing: Icon(
                    Icons.chevron_right,
                    color: scheme.onSurface.withOpacity(.7),
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
                  title: "Thông báo",
                  subtitle: "Quản lý các loại thông báo",
                  trailing: Switch(
                    value: notificationOn,
                    activeColor: scheme.primary,
                    onChanged: (v) {
                      setState(() {
                        notificationOn = v;
                      });
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Poppins",
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB6C4D7),
                        fontFamily: "Public Sans",
                      ),
                    ),
                  ],
                ),
              ),

              /// right widget
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeSelectorSheet extends StatefulWidget {
  const ThemeSelectorSheet({super.key});

  @override
  State<ThemeSelectorSheet> createState() => _ThemeSelectorSheetState();
}

class _ThemeSelectorSheetState extends State<ThemeSelectorSheet> {
  final List<Color> colors = const [
    Color(0xFFFF9EB7),
    Color(0xFFFCB022),
    Color(0xFF12B669),
    Color(0xFF2E90FA),
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
        storage.getInt(StorageKeys.themeColor) ?? colors[0].value;

    final savedDark = storage.getBool(StorageKeys.isDarkMode) ?? false;

    final index = colors.indexWhere((c) => c.value == savedColorValue);

    setState(() {
      selectedColor = index != -1 ? index : 0;
      isDark = savedDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// drag indicator
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 16),

          /// title
          Text(
            "Tùy chỉnh giao diện",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontFamily: "Poppins",
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Chọn màu chủ đạo và chế độ sáng/tối",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.6),
              fontFamily: "Public Sans",
            ),
          ),

          const SizedBox(height: 22),

          /// COLOR THEMES
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
                onTap: () {
                  setState(() {
                    selectedColor = index;
                  });
                },
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

          const SizedBox(height: 26),

          /// LIGHT / DARK MODE
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
                    "Chế độ tối",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                Switch(
                  value: isDark,
                  activeColor: colors[selectedColor], // thumb khi bật

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

          const SizedBox(height: 24),

          /// APPLY BUTTON
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors[selectedColor],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final color = colors[selectedColor];

                Navigator.pop(context, {"color": color, "isDark": isDark});
              },
              child: const Text(
                "Áp dụng giao diện",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
