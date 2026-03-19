import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/features/safe_route/presentation/states/child_safe_route_state.dart';

class ChildSafeRouteHud extends StatelessWidget {
  const ChildSafeRouteHud({
    super.key,
    required this.state,
    required this.languageCode,
    this.topOffset = 88,
    this.bottomOffset = 96,
  });

  final ChildSafeRouteState state;
  final String languageCode;
  final double topOffset;
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    final guidance = state.guidance;
    final location = state.currentLocation;
    if (guidance == null || location == null) {
      return const SizedBox.shrink();
    }

    final palette = _HudPalette.fromSeverity(guidance.severity);
    final strings = _HudStrings(languageCode);

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        children: [
          Positioned(
            left: 16,
            right: 16,
            top: topOffset,
            child: _TopInstructionBanner(
              palette: palette,
              guidance: guidance,
              updatedLabel: strings.updatedLabel(location.dateTime),
            ),
          ),
          Positioned(
            left: 16,
            bottom: bottomOffset,
            child: _BottomStatusPill(
              palette: palette,
              guidance: guidance,
              speedLabel: strings.speedLabel(location.speedKmh),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopInstructionBanner extends StatelessWidget {
  const _TopInstructionBanner({
    required this.palette,
    required this.guidance,
    required this.updatedLabel,
  });

  final _HudPalette palette;
  final ChildSafeRouteGuidance guidance;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: palette.badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(palette.icon, size: 18, color: palette.iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    guidance.primaryInstruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.badgeColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    guidance.statusLabel,
                    style: TextStyle(
                      color: palette.iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              guidance.secondaryInstruction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: guidance.progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(palette.iconColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TopMetaChip(
                  icon: Icons.route_rounded,
                  label: guidance.remainingDistanceLabel,
                ),
                const SizedBox(width: 8),
                _TopMetaChip(
                  icon: Icons.schedule_rounded,
                  label: guidance.etaLabel,
                ),
                const Spacer(),
                Text(
                  updatedLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMetaChip extends StatelessWidget {
  const _TopMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomStatusPill extends StatelessWidget {
  const _BottomStatusPill({
    required this.palette,
    required this.guidance,
    required this.speedLabel,
  });

  final _HudPalette palette;
  final ChildSafeRouteGuidance guidance;
  final String speedLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(palette.icon, size: 18, color: palette.iconColor),
            const SizedBox(width: 8),
            Text(
              guidance.statusLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 1, height: 16, color: const Color(0xFFE5E7EB)),
            const SizedBox(width: 10),
            Text(
              speedLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudPalette {
  const _HudPalette({
    required this.icon,
    required this.iconColor,
    required this.badgeColor,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color badgeColor;
  final Color borderColor;

  factory _HudPalette.fromSeverity(ChildSafeRouteSeverity severity) {
    switch (severity) {
      case ChildSafeRouteSeverity.danger:
        return const _HudPalette(
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFDC2626),
          badgeColor: Color(0xFFFFE4E6),
          borderColor: Color(0xFFFECDD3),
        );
      case ChildSafeRouteSeverity.offRoute:
        return const _HudPalette(
          icon: Icons.alt_route_rounded,
          iconColor: Color(0xFFEA580C),
          badgeColor: Color(0xFFFFEDD5),
          borderColor: Color(0xFFFED7AA),
        );
      case ChildSafeRouteSeverity.arrived:
        return const _HudPalette(
          icon: Icons.flag_rounded,
          iconColor: Color(0xFF059669),
          badgeColor: Color(0xFFD1FAE5),
          borderColor: Color(0xFFA7F3D0),
        );
      case ChildSafeRouteSeverity.safe:
        return const _HudPalette(
          icon: Icons.navigation_rounded,
          iconColor: Color(0xFF2563EB),
          badgeColor: Color(0xFFDBEAFE),
          borderColor: Color(0xFFBFDBFE),
        );
    }
  }
}

class _HudStrings {
  _HudStrings(String languageCode)
    : _isEnglish = languageCode.toLowerCase().startsWith('en');
  final bool _isEnglish;

  String speedLabel(double speedKmh) {
    return _isEnglish
        ? '${speedKmh.toStringAsFixed(1)} km/h'
        : '${speedKmh.toStringAsFixed(1)} km/h';
  }

  String updatedLabel(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (_isEnglish) {
      if (diff.inSeconds < 60) return 'Updated just now';
      if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
      return 'Updated ${diff.inHours}h ago';
    }
    if (diff.inSeconds < 60) return 'Vừa cập nhật';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes}p trước';
    return 'Cập nhật ${diff.inHours}h trước';
  }
}
