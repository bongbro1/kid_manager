import 'package:flutter/material.dart';

enum AppPopupType { success, info, warning, error }

class AppPopup {
  /// Trả về giá trị khi user bấm nút (primaryResult/secondaryResult)
  static Future<T?> show<T>(
    BuildContext context, {
    required AppPopupType type,
    required String title,
    required String message,
    String primaryText = 'Tiếp tục',
    T? primaryResult,
    String? secondaryText,
    T? secondaryResult,
    bool barrierDismissible = false,
  }) {
    return showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Popup',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, __, ___) {
        return Center(
          child: _PopupCard<T>(
            type: type,
            title: title,
            message: message,
            primaryText: primaryText,
            onPrimary: () => Navigator.of(dialogContext, rootNavigator: true).pop(primaryResult),
            secondaryText: secondaryText,
            onSecondary: secondaryText == null
                ? null
                : () => Navigator.of(dialogContext, rootNavigator: true).pop(secondaryResult),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }
}

class _PopupCard<T> extends StatelessWidget {
  final AppPopupType type;
  final String title;
  final String message;
  final String primaryText;
  final VoidCallback onPrimary;
  final String? secondaryText;
  final VoidCallback? onSecondary;

  const _PopupCard({
    required this.type,
    required this.title,
    required this.message,
    required this.primaryText,
    required this.onPrimary,
    this.secondaryText,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final style = _style(type);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(dotColor: style.dotColor, bgColor: style.bgColor, icon: style.icon),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF6B7280))),
            const SizedBox(height: 18),

            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: style.primaryBtn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(primaryText, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),

            if (secondaryText != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    secondaryText!,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Color dotColor;
  final Color bgColor;
  final IconData icon;

  const _IconBadge({
    required this.dotColor,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _PopupStyle {
  final Color dotColor;
  final Color bgColor;
  final Color primaryBtn;
  final IconData icon;

  const _PopupStyle({
    required this.dotColor,
    required this.bgColor,
    required this.primaryBtn,
    required this.icon,
  });
}

_PopupStyle _style(AppPopupType t) {
  switch (t) {
    case AppPopupType.success:
      return const _PopupStyle(
        dotColor: Color(0xFF22C55E),
        bgColor: Color(0xFFEAF7EF),
        primaryBtn: Color.fromARGB(255, 211, 211, 211), 
        icon: Icons.check,
      );
    case AppPopupType.info:
      return const _PopupStyle(
        dotColor: Color(0xFF3F7CFF),
        bgColor: Color(0xFFE8F1FF),
        primaryBtn: Color.fromARGB(255, 211, 211, 211), 
        icon: Icons.info_outline,
      );
    case AppPopupType.warning:
      return const _PopupStyle(
        dotColor: Color(0xFFF59E0B),
        bgColor: Color(0xFFFFF4DF),
        primaryBtn: Color.fromARGB(255, 211, 211, 211), 
        icon: Icons.warning_amber_rounded,
      );
    case AppPopupType.error:
      return const _PopupStyle(
        dotColor: Color(0xFFEF4444),
        bgColor: Color(0xFFFDECEC),
        primaryBtn: Color.fromARGB(255, 211, 211, 211), 
        icon: Icons.close,
      );
  }
}