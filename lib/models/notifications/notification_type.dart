import 'package:flutter/material.dart';

enum DialogType { success, error, info, warning }

class NotificationConfig {
  final Color primary;
  final Color light;
  final Widget Function() iconBuilder;

  const NotificationConfig({
    required this.primary,
    required this.light,
    required this.iconBuilder,
  });

  static NotificationConfig from(DialogType type) {
    switch (type) {
      case DialogType.success:
        return NotificationConfig(
          primary: const Color(0xFF22C55E),
          light: const Color(0xFFDCFCE7),
          iconBuilder: () => const LayeredCircleIcon(
            outerColor: Color(0xFFDCFCE7),
            middleColor: Color(0xFFBBF7D0),
            innerColor: Color(0xFF22C55E),
            shadowColor: Color(0xFFBBF7D0),
            icon: Icons.check_rounded,
          ),
        );

      case DialogType.error:
        return NotificationConfig(
          primary: const Color(0xFFEF4444),
          light: const Color(0xFFFEE2E2),
          iconBuilder: () => const LayeredCircleIcon(
            outerColor: Color(0xFFFFF0F0),
            middleColor: Color(0xFFFEE2E2),
            innerColor: Color(0xFFEF4444),
            shadowColor: Color(0xFFFECACA),
            icon: Icons.close_rounded,
          ),
        );

      case DialogType.info:
        return NotificationConfig(
          primary: const Color(0xFF3B82F6),
          light: const Color(0xFFDBEAFE),
          iconBuilder: () => const LayeredCircleIcon(
            outerColor: Color(0xFFDBEAFE),
            middleColor: Color(0xFFBFDBFE),
            innerColor: Color(0xFF3B82F6),
            shadowColor: Color(0xFFBFDBFE),
            icon: Icons.info_rounded,
          ),
        );

      case DialogType.warning:
        return NotificationConfig(
          primary: const Color(0xFFF59E0B),
          light: const Color(0xFFFEF3C7),
          iconBuilder: () => const LayeredCircleIcon(
            outerColor: Color(0xFFFEF3C7),
            middleColor: Color(0xFFFDE68A),
            innerColor: Color(0xFFF59E0B),
            shadowColor: Color(0xFFFDE68A),
            icon: Icons.warning_amber_rounded,
          ),
        );
    }
  }
}

class LayeredCircleIcon extends StatelessWidget {
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;
  final Color shadowColor;
  final IconData icon;
  final double size;

  const LayeredCircleIcon({
    super.key,
    required this.outerColor,
    required this.middleColor,
    required this.innerColor,
    required this.shadowColor,
    required this.icon,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final outerSize = 140 * 0.72;
    final middleSize = 140 * 0.55;
    final innerSize = 140 * 0.375;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              color: outerColor,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: middleSize,
            height: middleSize,
            decoration: BoxDecoration(
              color: middleColor,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: innerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 8),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: innerSize * 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
