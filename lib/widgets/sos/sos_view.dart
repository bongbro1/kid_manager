import 'package:flutter/material.dart';

class SosCircleButton extends StatefulWidget {
  final VoidCallback onPressed;
  const SosCircleButton({super.key, required this.onPressed});

  @override
  State<SosCircleButton> createState() => _SosCircleButtonState();
}

class _SosCircleButtonState extends State<SosCircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double core = 52;
    const Color blue = Color(0xFF2F6BFF);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final pulseScale = 1.0 + t * 0.55;
        final pulseOpacity = (1.0 - t).clamp(0.0, 1.0) * 0.35;

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: pulseScale,
              child: Container(
                width: core,
                height: core,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: blue.withOpacity(pulseOpacity),
                    width: 3,
                  ),
                ),
              ),
            ),
            Container(
              width: core + 22,
              height: core + 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: blue.withOpacity(0.35), width: 2),
              ),
            ),
            Container(
              width: core + 10,
              height: core + 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: blue.withOpacity(0.60), width: 2),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                customBorder: const CircleBorder(),
                child: Ink(
                  width: core,
                  height: core,
                  decoration: const BoxDecoration(
                    color: blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        color: Color(0x33000000),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}