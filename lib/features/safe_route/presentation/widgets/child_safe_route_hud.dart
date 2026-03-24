import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/features/safe_route/presentation/states/child_safe_route_state.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

class ChildSafeRouteHud extends StatelessWidget {
  const ChildSafeRouteHud({
    super.key,
    required this.state,
    required this.languageCode,
    this.topOffset = 88,
    this.bottomOffset = 96,
    this.showBottomStatusPill = true,
  });

  final ChildSafeRouteState state;
  final String languageCode;
  final double topOffset;
  final double bottomOffset;
  final bool showBottomStatusPill;

  @override
  Widget build(BuildContext context) {
    final guidance = state.guidance;
    final location = state.currentLocation;
    if (guidance == null || location == null) {
      return const SizedBox.shrink();
    }

    final palette = _HudPalette.fromSeverity(guidance.severity);
    final strings = _HudStrings(runtimeL10n(languageCode));

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
          if (showBottomStatusPill)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomOffset,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: _BottomStatusPill(
                  palette: palette,
                  guidance: guidance,
                  speedLabel: strings.speedLabel(location.speedKmh),
                ),
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
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: locationPanelColor(scheme).withOpacity(0.94),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusChip(
              label: guidance.statusLabel,
              foregroundColor: palette.iconColor,
              backgroundColor: palette.badgeColor,
            ),
            const SizedBox(height: 10),
            Text(
              guidance.secondaryInstruction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: guidance.progress.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(palette.iconColor),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _TopMetaChip(
                  icon: Icons.route_rounded,
                  label: guidance.remainingDistanceLabel,
                ),
                _TopMetaChip(
                  icon: Icons.schedule_rounded,
                  label: guidance.etaLabel,
                ),
                Text(
                  updatedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final String label;
  final Color foregroundColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            color: foregroundColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 150),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: locationPanelMutedColor(scheme),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final maxWidth = MediaQuery.of(context).size.width - 32;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: locationPanelColor(scheme).withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(color: locationPanelBorderColor(scheme)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(palette.icon, size: 18, color: palette.iconColor),
              Text(
                guidance.statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Container(
                width: 1,
                height: 16,
                color: locationPanelBorderColor(scheme),
              ),
              Text(
                speedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
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
  const _HudStrings(this.l10n);

  final AppLocalizations l10n;

  String speedLabel(double speedKmh) {
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  String updatedLabel(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) return l10n.childLocationUpdatedJustNow;
    if (diff.inMinutes == 1) return l10n.childLocationUpdatedOneMinuteAgo;
    if (diff.inMinutes < 60) {
      return l10n.childLocationUpdatedMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours == 1) return l10n.childLocationUpdatedOneHourAgo;
    return l10n.childLocationUpdatedHoursAgo(diff.inHours);
  }
}
