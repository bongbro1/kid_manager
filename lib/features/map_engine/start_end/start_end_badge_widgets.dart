import 'package:flutter/material.dart';

class StartBadgeWidget extends StatelessWidget {
  const StartBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MapMarkerBadge(
      text: 'START',
      textBg: Color(0xFFDDF5E3),
      textColor: Color(0xFF188038),
      iconBg: Color(0xFF1A73E8),
      icon: Icons.home_rounded,
      iconColor: Colors.white,
    );
  }
}

class FinishBadgeWidget extends StatelessWidget {
  const FinishBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MapMarkerBadge(
      text: 'FINISH',
      textBg: Color(0xFFFDE2E1),
      textColor: Color(0xFFC5221F),
      iconBg: Color(0xFF1A73E8),
      icon: Icons.location_on_rounded,
      iconColor: Colors.white,
    );
  }
}

class _MapMarkerBadge extends StatelessWidget {
  final String text;
  final Color textBg;
  final Color textColor;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;

  const _MapMarkerBadge({
    required this.text,
    required this.textBg,
    required this.textColor,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 92,
        height: 108,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: textBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 23,
                color: iconColor,
              ),
            ),
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(99),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}