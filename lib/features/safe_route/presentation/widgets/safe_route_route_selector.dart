import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

class SafeRouteRouteSelector extends StatelessWidget {
  const SafeRouteRouteSelector({
    super.key,
    required this.routes,
    required this.selectedRoute,
    required this.selectedAlternativeRouteIds,
    required this.onSelectPrimary,
    required this.onToggleAlternative,
    this.maxAlternativeRoutes = 2,
  });

  final List<SafeRoute> routes;
  final SafeRoute? selectedRoute;
  final List<String> selectedAlternativeRouteIds;
  final ValueChanged<SafeRoute> onSelectPrimary;
  final ValueChanged<SafeRoute> onToggleAlternative;
  final int maxAlternativeRoutes;

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        for (var index = 0; index < routes.length; index++) ...[
          _RouteTile(
            route: routes[index],
            highlightedLabel: _routeBadgeLabel(l10n, index, routes[index]),
            isPrimary: routes[index].id == selectedRoute?.id,
            isAlternative: selectedAlternativeRouteIds.contains(
              routes[index].id,
            ),
            canAddAlternative:
                selectedAlternativeRouteIds.length < maxAlternativeRoutes,
            onSelectPrimary: () => onSelectPrimary(routes[index]),
            onToggleAlternative: () => onToggleAlternative(routes[index]),
          ),
          if (index != routes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _routeBadgeLabel(AppLocalizations l10n, int index, SafeRoute route) {
    if (index == 0) return l10n.safeRouteBadgeSafest;
    if (route.hazards.isEmpty) return l10n.safeRouteBadgeFewerHazards;
    if (index == 1) return l10n.safeRouteBadgeFaster;
    return l10n.safeRouteBadgeAlternative;
  }
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.route,
    required this.highlightedLabel,
    required this.isPrimary,
    required this.isAlternative,
    required this.canAddAlternative,
    required this.onSelectPrimary,
    required this.onToggleAlternative,
  });

  final SafeRoute route;
  final String highlightedLabel;
  final bool isPrimary;
  final bool isAlternative;
  final bool canAddAlternative;
  final VoidCallback onSelectPrimary;
  final VoidCallback onToggleAlternative;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final safetyScore = _buildSafetyScore(route);
    final roleLabel = isPrimary
        ? l10n.safeRouteRolePrimary
        : isAlternative
        ? l10n.safeRouteRoleAlternative
        : null;

    return Material(
      color: isPrimary
          ? locationPanelHighlightColor(scheme)
          : isAlternative
          ? Color.alphaBlend(
              Colors.green.withOpacity(0.08),
              locationPanelMutedColor(scheme),
            )
          : locationPanelMutedColor(scheme),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onSelectPrimary,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary
                  ? locationPanelBorderColor(scheme)
                  : isAlternative
                  ? const Color(0xFFBBF7D0)
                  : locationPanelBorderColor(scheme),
              width: isPrimary || isAlternative ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.safeRouteDurationLabel(
                                route.durationSeconds,
                              ),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _LabelChip(
                              label: highlightedLabel,
                              color:
                                  highlightedLabel == l10n.safeRouteBadgeSafest
                                  ? const Color(0xFF1A73E8)
                                  : highlightedLabel ==
                                        l10n.safeRouteBadgeFaster
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF15803D),
                            ),
                            if (roleLabel != null) ...[
                              const SizedBox(width: 6),
                              _LabelChip(
                                label: roleLabel,
                                color: isPrimary
                                    ? const Color(0xFF1D4ED8)
                                    : const Color(0xFF15803D),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${l10n.safeRouteDistanceLabel(route.distanceMeters)} · ${l10n.safeRouteHazardCount(route.hazards.length)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: safetyScore >= 9
                          ? const Color(0xFFEAF8EF)
                          : safetyScore >= 8
                          ? const Color(0xFFFFF3E4)
                          : const Color(0xFFFFE9E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${safetyScore.toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: safetyScore >= 9
                            ? const Color(0xFF15803D)
                            : safetyScore >= 8
                            ? const Color(0xFFB45309)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetaPill(
                      icon: Icons.shield_outlined,
                      label: l10n.safeRouteCorridorLabel(
                        route.corridorWidthMeters.round(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaPill(
                      icon: Icons.warning_amber_rounded,
                      label: l10n.safeRouteHazardCount(route.hazards.length),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _routeDescription(l10n, route),
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RouteActionButton(
                      label: isPrimary
                          ? l10n.safeRouteActionPrimarySelected
                          : l10n.safeRouteActionSetPrimary,
                      icon: isPrimary
                          ? Icons.check_circle_rounded
                          : Icons.flag_rounded,
                      backgroundColor: isPrimary
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFFEFF6FF),
                      foregroundColor: isPrimary
                          ? Colors.white
                          : const Color(0xFF1D4ED8),
                      borderColor: isPrimary
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFFBFDBFE),
                      onTap: isPrimary ? null : onSelectPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RouteActionButton(
                      label: isAlternative
                          ? l10n.safeRouteActionRemoveAlternative
                          : canAddAlternative
                          ? l10n.safeRouteActionSelectAlternative
                          : l10n.safeRouteActionAlternativeLimitReached,
                      icon: isAlternative
                          ? Icons.remove_circle_outline_rounded
                          : Icons.alt_route_rounded,
                      backgroundColor: isAlternative
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFF8FAFC),
                      foregroundColor: isAlternative
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                      borderColor: isAlternative
                          ? const Color(0xFFBBF7D0)
                          : const Color(0xFFE2E8F0),
                      onTap: isPrimary || (!isAlternative && !canAddAlternative)
                          ? null
                          : onToggleAlternative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _buildSafetyScore(SafeRoute route) {
    final hazardPenalty = route.hazards.fold<double>(0, (sum, hazard) {
      switch (hazard.riskLevel.name) {
        case 'high':
          return sum + 1.2;
        case 'medium':
          return sum + 0.8;
        case 'low':
          return sum + 0.3;
      }
      return sum + 0.5;
    });
    final distancePenalty = route.distanceMeters > 2200 ? 0.3 : 0.0;
    final score = 10 - hazardPenalty - distancePenalty;
    return score.clamp(6.5, 9.8).toDouble();
  }

  String _routeDescription(AppLocalizations l10n, SafeRoute route) {
    if (route.hazards.isEmpty) {
      return l10n.safeRouteRouteDescriptionStable;
    }
    if (route.hazards.length == 1) {
      return l10n.safeRouteRouteDescriptionOneHazard;
    }
    return l10n.safeRouteRouteDescriptionMoreHazards;
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: locationPanelColor(scheme),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: locationPanelBorderColor(scheme)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteActionButton extends StatelessWidget {
  const _RouteActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: onTap == null ? 0.55 : 1,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foregroundColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
