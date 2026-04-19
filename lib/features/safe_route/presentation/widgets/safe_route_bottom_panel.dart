import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_tracking_visuals.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_tracking_state.dart';
import 'package:kid_manager/features/safe_route/presentation/widgets/safe_route_route_selector.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/device_battery_widgets.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

class SafeRouteBottomPanel extends StatelessWidget {
  const SafeRouteBottomPanel({
    super.key,
    required this.state,
    required this.safetyStatusLabel,
    required this.speedLabel,
    required this.batteryState,
    required this.lastUpdatedLabel,
    required this.scrollController,
    required this.onUseLiveLocationAsStart,
    required this.onSearchStart,
    required this.onSearchEnd,
    required this.onStartSelectingStart,
    required this.onStartSelectingEnd,
    required this.onClearStart,
    required this.onClearEnd,
    required this.onSelectTravelMode,
    required this.onSwapPoints,
    required this.onPickScheduleDate,
    required this.onPickScheduleTime,
    required this.onResetSchedule,
    required this.onToggleRepeatWeekday,
    required this.onShowHistory,
    required this.onFetchSuggestedRoutes,
    required this.onSelectRoute,
    required this.onToggleAlternativeRoute,
    required this.onStartTrip,
    required this.onCompleteTrip,
    required this.onCancelTrip,
    required this.onFocusRoute,
  });

  final SafeRouteTrackingState state;
  final String safetyStatusLabel;
  final String speedLabel;
  final DeviceBatteryUiState batteryState;
  final String lastUpdatedLabel;
  final ScrollController scrollController;
  final VoidCallback onUseLiveLocationAsStart;
  final VoidCallback onSearchStart;
  final VoidCallback onSearchEnd;
  final VoidCallback onStartSelectingStart;
  final VoidCallback onStartSelectingEnd;
  final VoidCallback onClearStart;
  final VoidCallback onClearEnd;
  final ValueChanged<SafeRouteTravelMode> onSelectTravelMode;
  final VoidCallback onSwapPoints;
  final VoidCallback onPickScheduleDate;
  final VoidCallback onPickScheduleTime;
  final VoidCallback onResetSchedule;
  final ValueChanged<int> onToggleRepeatWeekday;
  final VoidCallback onShowHistory;
  final VoidCallback onFetchSuggestedRoutes;
  final ValueChanged<SafeRoute> onSelectRoute;
  final ValueChanged<SafeRoute> onToggleAlternativeRoute;
  final VoidCallback onStartTrip;
  final VoidCallback onCompleteTrip;
  final VoidCallback onCancelTrip;
  final VoidCallback onFocusRoute;

  bool get _hasActiveTrip => state.activeTrip != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final trackingVisuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: l10n,
      fallbackStatusLabel: safetyStatusLabel,
    );

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: locationPanelColor(scheme).withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 26,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: CustomScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: locationPanelBorderColor(scheme),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      if (_hasActiveTrip)
                        _TrackingStatusContent(
                          state: state,
                          l10n: l10n,
                          safetyStatusLabel: safetyStatusLabel,
                          speedLabel: speedLabel,
                          batteryState: batteryState,
                          lastUpdatedLabel: lastUpdatedLabel,
                          onCompleteTrip: onCompleteTrip,
                          onCancelTrip: onCancelTrip,
                          onFocusRoute: onFocusRoute,
                          onShowHistory: onShowHistory,
                        )
                      else
                        _RouteSelectionContent(
                          state: state,
                          l10n: l10n,
                          onUseLiveLocationAsStart: onUseLiveLocationAsStart,
                          onSearchStart: onSearchStart,
                          onSearchEnd: onSearchEnd,
                          onStartSelectingStart: onStartSelectingStart,
                          onStartSelectingEnd: onStartSelectingEnd,
                          onClearStart: onClearStart,
                          onClearEnd: onClearEnd,
                          onSelectTravelMode: onSelectTravelMode,
                          onSwapPoints: onSwapPoints,
                          onPickScheduleDate: onPickScheduleDate,
                          onPickScheduleTime: onPickScheduleTime,
                          onResetSchedule: onResetSchedule,
                          onToggleRepeatWeekday: onToggleRepeatWeekday,
                          onShowHistory: onShowHistory,
                          onFetchSuggestedRoutes: onFetchSuggestedRoutes,
                          onSelectRoute: onSelectRoute,
                          onToggleAlternativeRoute: onToggleAlternativeRoute,
                          onStartTrip: onStartTrip,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_hasActiveTrip)
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: IgnorePointer(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: trackingVisuals.borderColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(999),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RouteSelectionContent extends StatelessWidget {
  const _RouteSelectionContent({
    required this.state,
    required this.l10n,
    required this.onUseLiveLocationAsStart,
    required this.onSearchStart,
    required this.onSearchEnd,
    required this.onStartSelectingStart,
    required this.onStartSelectingEnd,
    required this.onClearStart,
    required this.onClearEnd,
    required this.onSelectTravelMode,
    required this.onSwapPoints,
    required this.onPickScheduleDate,
    required this.onPickScheduleTime,
    required this.onResetSchedule,
    required this.onToggleRepeatWeekday,
    required this.onShowHistory,
    required this.onFetchSuggestedRoutes,
    required this.onSelectRoute,
    required this.onToggleAlternativeRoute,
    required this.onStartTrip,
  });

  final SafeRouteTrackingState state;
  final AppLocalizations l10n;
  final VoidCallback onUseLiveLocationAsStart;
  final VoidCallback onSearchStart;
  final VoidCallback onSearchEnd;
  final VoidCallback onStartSelectingStart;
  final VoidCallback onStartSelectingEnd;
  final VoidCallback onClearStart;
  final VoidCallback onClearEnd;
  final ValueChanged<SafeRouteTravelMode> onSelectTravelMode;
  final VoidCallback onSwapPoints;
  final VoidCallback onPickScheduleDate;
  final VoidCallback onPickScheduleTime;
  final VoidCallback onResetSchedule;
  final ValueChanged<int> onToggleRepeatWeekday;
  final VoidCallback onShowHistory;
  final VoidCallback onFetchSuggestedRoutes;
  final ValueChanged<SafeRoute> onSelectRoute;
  final ValueChanged<SafeRoute> onToggleAlternativeRoute;
  final VoidCallback onStartTrip;

  bool get _hasStart => state.selectedStart != null;
  bool get _hasEnd => state.selectedEnd != null;
  bool get _canFetch =>
      _hasStart && _hasEnd && !state.isFetchingSuggestions && !state.isStartingTrip;
  bool get _canStart =>
      state.selectedRoute != null && !state.isFetchingSuggestions && !state.isStartingTrip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.safeRouteSelectSafeRouteTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _hintText(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        _LocationPickerCard(
          start: state.selectedStart,
          end: state.selectedEnd,
          startLabel: state.selectedStartLabel,
          endLabel: state.selectedEndLabel,
          selectionMode: state.selectionMode,
          onStartTap: onSearchStart,
          onEndTap: onSearchEnd,
          onClearStart: _hasStart ? onClearStart : null,
          onClearEnd: _hasEnd ? onClearEnd : null,
          onSwapTap: (_hasStart && _hasEnd) ? onSwapPoints : null,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickActionChip(
              label: l10n.safeRouteUseCurrentLocationLabel,
              icon: Icons.my_location_rounded,
              highlighted: true,
              onTap: onUseLiveLocationAsStart,
            ),
            _QuickActionChip(
              label: l10n.safeRouteMapHintTapStart,
              icon: Icons.trip_origin_rounded,
              onTap: onStartSelectingStart,
            ),
            _QuickActionChip(
              label: l10n.safeRouteMapHintTapEnd,
              icon: Icons.place_rounded,
              onTap: onStartSelectingEnd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TravelModesRow(
          selectedMode: state.selectedTravelMode,
          onSelected: onSelectTravelMode,
        ),
        const SizedBox(height: 14),
        _ScheduleCard(
          scheduledDate: state.scheduledDate,
          scheduledTime: state.scheduledTime,
          repeatWeekdays: state.repeatWeekdays,
          onPickDate: onPickScheduleDate,
          onPickTime: onPickScheduleTime,
          onReset: onResetSchedule,
          onToggleWeekday: onToggleRepeatWeekday,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.safeRouteSuggestedRoutesTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.safeRouteSuggestedRoutesSubtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GhostButton(
                  label: l10n.safeRouteHistoryButton,
                  icon: Icons.history_rounded,
                  onTap: onShowHistory,
                ),
                const SizedBox(height: 8),
                _GhostButton(
                  label: state.isFetchingSuggestions
                      ? l10n.safeRouteRefreshingRoutes
                      : l10n.safeRouteRefreshButton,
                  icon: Icons.refresh_rounded,
                  onTap: state.isFetchingSuggestions ? null : onFetchSuggestedRoutes,
                ),
              ],
            ),
          ],
        ),
        if (state.suggestedRoutes.isEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: locationPanelMutedColor(scheme),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: locationPanelBorderColor(scheme)),
            ),
            child: Text(
              _emptyRoutesText(),
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: 14),
          if (state.selectedRoute != null || state.selectedAlternativeRouteIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _selectedRoutesSummary(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          SafeRouteRouteSelector(
            routes: state.suggestedRoutes,
            selectedRoute: state.selectedRoute,
            selectedAlternativeRouteIds: state.selectedAlternativeRouteIds,
            onSelectPrimary: onSelectRoute,
            onToggleAlternative: onToggleAlternativeRoute,
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canStart
                ? onStartTrip
                : (_canFetch ? onFetchSuggestedRoutes : null),
            style: FilledButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: state.isStartingTrip
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.safeRouteConfirmingRoute,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _canStart
                        ? _primaryActionLabel()
                        : l10n.safeRouteFetchSuggestedRoutes,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  String _hintText() {
    switch (state.selectionMode) {
      case RouteSelectionMode.selectingStart:
        return l10n.safeRouteHintSelectingStart;
      case RouteSelectionMode.selectingEnd:
        return l10n.safeRouteHintSelectingEnd;
      case RouteSelectionMode.none:
        if (!_hasStart || !_hasEnd) {
          return l10n.safeRouteHintMissingPoints;
        }
        return l10n.safeRouteHintReadyChooseRoute;
    }
  }

  String _emptyRoutesText() {
    if (!_hasStart || !_hasEnd) {
      return l10n.safeRouteEmptyRoutesNeedPoints;
    }
    return l10n.safeRouteEmptyRoutesRefresh;
  }

  String _primaryActionLabel() {
    if (state.repeatWeekdays.isNotEmpty || state.scheduledDate != null) {
      return l10n.safeRoutePrimaryActionSaveSchedule;
    }
    if (state.selectedAlternativeRouteIds.isNotEmpty) {
      return l10n.safeRoutePrimaryActionStartSelectedRoutes;
    }
    return l10n.safeRoutePrimaryActionSelectThisRoute;
  }

  String _selectedRoutesSummary() {
    final primary = state.selectedRoute;
    final alternativeCount = state.selectedAlternativeRouteIds.length;
    if (primary == null) {
      return l10n.safeRouteSelectedRoutesNeedPrimary;
    }
    if (alternativeCount == 0) {
      return l10n.safeRouteSelectedRoutesPrimaryOnly;
    }
    return l10n.safeRouteSelectedRoutesWithAlternatives(alternativeCount);
  }
}
class _TrackingStatusContent extends StatelessWidget {
  const _TrackingStatusContent({
    required this.state,
    required this.l10n,
    required this.safetyStatusLabel,
    required this.speedLabel,
    required this.batteryState,
    required this.lastUpdatedLabel,
    required this.onCompleteTrip,
    required this.onCancelTrip,
    required this.onFocusRoute,
    required this.onShowHistory,
  });

  final SafeRouteTrackingState state;
  final AppLocalizations l10n;
  final String safetyStatusLabel;
  final String speedLabel;
  final DeviceBatteryUiState batteryState;
  final String lastUpdatedLabel;
  final VoidCallback onCompleteTrip;
  final VoidCallback onCancelTrip;
  final VoidCallback onFocusRoute;
  final VoidCallback onShowHistory;

  bool get _isCompleting => state.tripMutation == TripMutationState.completing;
  bool get _isCancelling => state.tripMutation == TripMutationState.cancelling;
  bool get _hasTripMutation => state.tripMutation != TripMutationState.none;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: l10n,
      fallbackStatusLabel: safetyStatusLabel,
    );
    final isDanger = visuals.severity == SafeRouteTrackingSeverity.danger;
    final isWarning = visuals.severity == SafeRouteTrackingSeverity.warning;
    final distanceFromRoute =
        state.activeTrip?.currentDistanceFromRouteMeters.round() ?? 0;
    final hazard = findTriggeredSafeRouteHazard(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: visuals.bannerColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: visuals.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visuals.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  visuals.icon,
                  color: visuals.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      visuals.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visuals.subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: visuals.badgeBackgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  visuals.badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: visuals.badgeForegroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (state.activeRoute != null) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrowLayout = constraints.maxWidth < 430;
              final speedCard = _TrackingMetricCard(
                label: l10n.safeRouteMetricSpeed,
                value: speedLabel,
                subtitle: _speedSubtitle(state),
                tint: isDanger ? const Color(0xFFFEF2F2) : visuals.softColor,
                borderColor: isDanger
                    ? const Color(0xFFFECACA)
                    : visuals.borderColor.withOpacity(0.55),
                valueColor: isDanger ? const Color(0xFF991B1B) : null,
              );
              final batteryCard = _BatteryMetricCard(
                batteryState: batteryState,
              );
              final etaCard = _TrackingMetricCard(
                label: isDanger
                    ? l10n.safeRouteMetricOffRoute
                    : isWarning
                    ? l10n.safeRouteMetricOffCorridor
                    : l10n.safeRouteMetricEta,
                value: isDanger || isWarning
                    ? l10n.safeRouteDistanceCompactLabel(
                        distanceFromRoute.toDouble(),
                      )
                    : _etaLabel(state),
                subtitle: isDanger
                    ? (hazard?.name ?? l10n.safeRouteDangerCheckNow)
                    : isWarning
                    ? l10n.safeRouteVisualOffRouteSubtitle
                    : l10n.safeRouteMetricEtaEstimate,
                tint: isDanger ? const Color(0xFFFEF2F2) : visuals.softColor,
                borderColor: isDanger
                    ? const Color(0xFFFECACA)
                    : visuals.borderColor.withOpacity(0.55),
                valueColor: isDanger ? const Color(0xFF991B1B) : null,
              );

              if (narrowLayout) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    speedCard,
                    const SizedBox(height: 10),
                    batteryCard,
                    const SizedBox(height: 10),
                    etaCard,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: speedCard),
                  const SizedBox(width: 10),
                  Expanded(child: batteryCard),
                  const SizedBox(width: 10),
                  Expanded(child: etaCard),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: locationPanelMutedColor(scheme),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: locationPanelBorderColor(scheme)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.activeRoute!.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lastUpdatedLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: visuals.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InlineChip(
                      icon: Icons.route_rounded,
                      label: l10n.safeRouteDistanceLabel(
                        state.activeRoute!.distanceMeters,
                      ),
                    ),
                    _InlineChip(
                      icon: Icons.schedule_rounded,
                      label: l10n.safeRouteDurationLabel(
                        state.activeRoute!.durationSeconds,
                      ),
                    ),
                    _InlineChip(
                      icon: Icons.warning_amber_rounded,
                      label: l10n.safeRouteHazardCount(
                        state.activeRoute!.hazards.length,
                      ),
                    ),
                    if (state.activeTrip?.scheduledStartAt != null)
                      _InlineChip(
                        icon: Icons.event_rounded,
                        label: l10n.safeRouteDateTimeLabel(
                          state.activeTrip!.scheduledStartAt!,
                        ),
                      ),
                    if (state.activeTrip?.repeatWeekdays.isNotEmpty == true)
                      _InlineChip(
                        icon: Icons.repeat_rounded,
                        label: l10n.safeRouteRepeatSummary(
                          state.activeTrip!.repeatWeekdays,
                        ),
                      ),
                    _InlineChip(
                      icon: Icons.traffic_rounded,
                      label: _currentRouteUsageLabel(state),
                    ),
                    if (state.activeAlternativeRoutes.isNotEmpty)
                      _InlineChip(
                        icon: Icons.alt_route_rounded,
                        label: l10n.safeRouteAlternativeRouteCount(
                          state.activeAlternativeRoutes.length,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _RouteProgressSummary(
                  details: _routeProgressDetails(state),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _GhostButton(
              label: l10n.safeRouteHistoryButton,
              icon: Icons.history_rounded,
              onTap: onShowHistory,
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (isDanger)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionStopTracking,
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFF991B1B),
                  borderColor: const Color(0xFFFCA5A5),
                  onTap: _hasTripMutation ? null : onCancelTrip,
                  isLoading: _isCancelling,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionViewRoute,
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  onTap: _hasTripMutation ? null : onFocusRoute,
                ),
              ),
            ],
          )
        else if (isWarning)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionStopTracking,
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFF8FAFC),
                  foregroundColor: const Color(0xFF475569),
                  borderColor: const Color(0xFFCBD5E1),
                  onTap: _hasTripMutation ? null : onCancelTrip,
                  isLoading: _isCancelling,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionViewRoute,
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFFFF7ED),
                  foregroundColor: const Color(0xFFB45309),
                  borderColor: const Color(0xFFFCD34D),
                  onTap: _hasTripMutation ? null : onFocusRoute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionMarkArrived,
                  icon: Icons.flag_rounded,
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  onTap: _hasTripMutation ? null : onCompleteTrip,
                  isLoading: _isCompleting,
                ),
              ),
            ],
          )
        else if (state.activeTrip?.status == TripStatus.planned)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionCancelSchedule,
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFF8FAFC),
                  foregroundColor: const Color(0xFF475569),
                  borderColor: const Color(0xFFCBD5E1),
                  onTap: _hasTripMutation ? null : onCancelTrip,
                  isLoading: _isCancelling,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionViewRoute,
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: _hasTripMutation ? null : onFocusRoute,
                ),
              ),
            ],
          )
        else if (state.activeTrip?.status == TripStatus.completed)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionViewRoute,
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: _hasTripMutation ? null : onFocusRoute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionChooseNewRoute,
                  icon: Icons.alt_route_rounded,
                  backgroundColor: const Color(0xFFF0FDF4),
                  foregroundColor: const Color(0xFF15803D),
                  borderColor: const Color(0xFFBBF7D0),
                  onTap: _hasTripMutation ? null : onCompleteTrip,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionRouteDetails,
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: _hasTripMutation ? null : onFocusRoute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: l10n.safeRouteActionMarkArrived,
                  icon: Icons.check_circle_rounded,
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  onTap: _hasTripMutation ? null : onCompleteTrip,
                  isLoading: _isCompleting,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _statusSubtitle(SafeRouteTrackingState state) {
    switch (state.activeTrip?.status) {
      case TripStatus.active:
        return 'Bé đang bám sát tuyến đã chọn';
      case TripStatus.temporarilyDeviated:
        return 'Có dấu hiệu lệch nhẹ, hệ thống đang tiếp tục theo dõi';
      case TripStatus.deviated:
        return 'Bé đã lệch khỏi corridor an toàn';
      case TripStatus.completed:
        return 'Hành trình đã hoàn tất';
      case TripStatus.cancelled:
        return 'Phụ huynh đã dừng giám sát';
      case TripStatus.planned:
        return 'Tuyến đang chờ tới giờ để tự kích hoạt';
      case null:
        return 'Chưa có dữ liệu giám sát';
    }
  }

  String _speedSubtitle(SafeRouteTrackingState state) {
    final speed = state.liveLocation?.speedKmh ?? 0;
    if (speed < 1) return l10n.safeRouteSpeedStanding;
    if (speed < 7) return l10n.safeRouteSpeedWalking;
    if (speed < 18) return l10n.safeRouteSpeedCycling;
    return l10n.safeRouteSpeedMoving;
  }

  String _etaLabel(SafeRouteTrackingState state) {
    return l10n.safeRouteEtaApproxLabel(
      state.activeRoute?.durationSeconds ?? 0,
    );
  }

  String _currentRouteUsageLabel(SafeRouteTrackingState state) {
    final trip = state.activeTrip;
    final activeRoute = state.activeRoute;
    return l10n.safeRouteCurrentRouteUsageLabel(
      activeRoute?.id,
      trip?.routeId,
      trip?.alternativeRouteIds ?? const [],
    );
  }

  _RouteProgressDetails _routeProgressDetails(SafeRouteTrackingState state) {
    final route = state.activeRoute;
    if (route == null || route.distanceMeters <= 0) {
      return const _RouteProgressDetails(
        progress: 0,
        traveledMeters: 0,
        totalMeters: 0,
      );
    }

    if (state.activeTrip?.status == TripStatus.completed) {
      return _RouteProgressDetails(
        progress: 1.0,
        traveledMeters: route.distanceMeters,
        totalMeters: route.distanceMeters,
      );
    }

    final live = state.liveLocation;
    if (live == null) {
      return _RouteProgressDetails(
        progress: 0,
        traveledMeters: 0,
        totalMeters: route.distanceMeters,
      );
    }

    final points = [...route.points]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (points.length < 2) {
      return _RouteProgressDetails(
        progress: 0,
        traveledMeters: 0,
        totalMeters: route.distanceMeters,
      );
    }

    final projection = _projectLocationOntoRoute(
      latitude: live.latitude,
      longitude: live.longitude,
      points: points,
    );

    var travelledMeters = 0.0;
    for (var index = 0; index < projection.segmentIndex; index++) {
      travelledMeters += _distanceMeters(
        points[index].latitude,
        points[index].longitude,
        points[index + 1].latitude,
        points[index + 1].longitude,
      );
    }

    travelledMeters += _distanceMeters(
      points[projection.segmentIndex].latitude,
      points[projection.segmentIndex].longitude,
      projection.projectedLatitude,
      projection.projectedLongitude,
    );

    return _RouteProgressDetails(
      progress: (travelledMeters / route.distanceMeters).clamp(0.0, 1.0).toDouble(),
      traveledMeters: travelledMeters.clamp(0.0, route.distanceMeters).toDouble(),
      totalMeters: route.distanceMeters,
    );
  }

  _PanelRouteProjection _projectLocationOntoRoute({
    required double latitude,
    required double longitude,
    required List<RoutePoint> points,
  }) {
    _PanelRouteProjection? best;
    for (var index = 0; index < points.length - 1; index++) {
      final projection = _projectOntoSegment(
        latitude: latitude,
        longitude: longitude,
        start: points[index],
        end: points[index + 1],
        segmentIndex: index,
      );
      if (best == null ||
          projection.distanceFromRouteMeters < best.distanceFromRouteMeters) {
        best = projection;
      }
    }
    return best!;
  }

  _PanelRouteProjection _projectOntoSegment({
    required double latitude,
    required double longitude,
    required RoutePoint start,
    required RoutePoint end,
    required int segmentIndex,
  }) {
    final metersPerLat = 111320.0;
    final cosValue = math.cos(latitude * math.pi / 180.0).abs();
    final metersPerLng = 111320.0 * cosValue.clamp(0.0001, 1.0).toDouble();

    final ax = (start.longitude - longitude) * metersPerLng;
    final ay = (start.latitude - latitude) * metersPerLat;
    final bx = (end.longitude - longitude) * metersPerLng;
    final by = (end.latitude - latitude) * metersPerLat;

    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;

    var t = 0.0;
    if (lengthSquared > 0) {
      t = (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0).toDouble();
    }

    final qx = ax + dx * t;
    final qy = ay + dy * t;
    final projectedLongitude = longitude + (qx / metersPerLng);
    final projectedLatitude = latitude + (qy / metersPerLat);

    return _PanelRouteProjection(
      segmentIndex: segmentIndex,
      distanceFromRouteMeters: math.sqrt(qx * qx + qy * qy),
      projectedLatitude: projectedLatitude,
      projectedLongitude: projectedLongitude,
    );
  }

  double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
class _TrackingMetricCard extends StatelessWidget {
  const _TrackingMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.tint,
    required this.borderColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color tint;
  final Color borderColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteProgressSummary extends StatelessWidget {
  const _RouteProgressSummary({
    required this.details,
  });

  final _RouteProgressDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: locationPanelColor(scheme),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: locationPanelBorderColor(scheme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.safeRouteProgressTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.safeRouteProgressCompletedPercent(
                  (details.progress * 100).round(),
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: details.progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.safeRouteProgressTraveled(
                    l10n.safeRouteDistanceCompactLabel(details.traveledMeters),
                    l10n.safeRouteDistanceCompactLabel(details.totalMeters),
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.safeRouteProgressRemainingPercent(
                  ((1 - details.progress).clamp(0.0, 1.0) * 100).round(),
                ),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.safeRouteProgressRemaining(
              l10n.safeRouteDistanceCompactLabel(
                (details.totalMeters - details.traveledMeters)
                    .clamp(0.0, details.totalMeters)
                    .toDouble(),
              ),
            ),
            style: TextStyle(
              fontSize: 10.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
class _PanelRouteProjection {
  const _PanelRouteProjection({
    required this.segmentIndex,
    required this.distanceFromRouteMeters,
    required this.projectedLatitude,
    required this.projectedLongitude,
  });

  final int segmentIndex;
  final double distanceFromRouteMeters;
  final double projectedLatitude;
  final double projectedLongitude;
}

class _RouteProgressDetails {
  const _RouteProgressDetails({
    required this.progress,
    required this.traveledMeters,
    required this.totalMeters,
  });

  final double progress;
  final double traveledMeters;
  final double totalMeters;
}

class _BatteryMetricCard extends StatelessWidget {
  const _BatteryMetricCard({
    required this.batteryState,
  });

  final DeviceBatteryUiState batteryState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DeviceBatteryPanelCard(
      state: batteryState,
      title: AppLocalizations.of(context).safeRouteDeviceBatteryLabel,
      backgroundColor: Colors.white,
      borderColor: locationPanelBorderColor(scheme),
    );
  }
}
class _TrackingActionButton extends StatelessWidget {
  const _TrackingActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !isLoading;
    return Material(
      color: disabled ? backgroundColor.withOpacity(0.58) : backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: borderColor == null ? null : Border.all(color: borderColor!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              else
                Icon(
                  icon,
                  size: 16,
                  color: disabled
                      ? foregroundColor.withOpacity(0.75)
                      : foregroundColor,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: disabled
                        ? foregroundColor.withOpacity(0.75)
                        : foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPickerCard extends StatelessWidget {
  const _LocationPickerCard({
    required this.start,
    required this.end,
    required this.startLabel,
    required this.endLabel,
    required this.selectionMode,
    required this.onStartTap,
    required this.onEndTap,
    this.onClearStart,
    this.onClearEnd,
    this.onSwapTap,
  });

  final RoutePoint? start;
  final RoutePoint? end;
  final String? startLabel;
  final String? endLabel;
  final RouteSelectionMode selectionMode;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;
  final VoidCallback? onClearStart;
  final VoidCallback? onClearEnd;
  final VoidCallback? onSwapTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: locationPanelMutedColor(scheme),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: locationPanelBorderColor(scheme)),
      ),
      child: Stack(
        children: [
          if (onSwapTap != null)
            Positioned(
              right: 12,
              top: 50,
              child: Material(
                color: locationPanelColor(scheme),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onSwapTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: locationPanelBorderColor(scheme)),
                    ),
                    child: Icon(
                      Icons.swap_vert_rounded,
                      size: 20,
                      color: onSwapTap == null
                          ? const Color(0xFFB0BDC9)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 56, 14),
            child: Column(
              children: [
                _LocationRow(
                  title: l10n.safeRouteFromLabel,
                  value: _pointLabel(
                    start,
                    label: startLabel,
                    fallback: l10n.safeRouteSearchOrSelectStart,
                  ),
                  dotColor: const Color(0xFF1A73E8),
                  selected: selectionMode == RouteSelectionMode.selectingStart,
                  onTap: onStartTap,
                  onClearTap: onClearStart,
                ),
                const SizedBox(height: 10),
                _LocationRow(
                  title: l10n.safeRouteToLabel,
                  value: _pointLabel(
                    end,
                    label: endLabel,
                    fallback: l10n.safeRouteSearchOrSelectEnd,
                  ),
                  dotColor: const Color(0xFF16A05F),
                  selected: selectionMode == RouteSelectionMode.selectingEnd,
                  onTap: onEndTap,
                  onClearTap: onClearEnd,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pointLabel(
    RoutePoint? point, {
    String? label,
    required String fallback,
  }) {
    if (label != null && label.trim().isNotEmpty) return label;
    if (point == null) return fallback;
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }
}
class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.title,
    required this.value,
    required this.dotColor,
    required this.selected,
    required this.onTap,
    required this.onClearTap,
  });

  final String title;
  final String value;
  final Color dotColor;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClearTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? locationPanelHighlightColor(scheme) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withOpacity(0.16),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onClearTap != null)
                Material(
                  color: locationPanelColor(scheme),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onClearTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ),
                )
              else
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant.withOpacity(0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TravelModesRow extends StatelessWidget {
  const _TravelModesRow({
    required this.selectedMode,
    required this.onSelected,
  });

  final SafeRouteTravelMode selectedMode;
  final ValueChanged<SafeRouteTravelMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ModeChip(
          icon: Icons.directions_walk_rounded,
          label: l10n.safeRouteTravelModeLabel(SafeRouteTravelMode.walking),
          active: selectedMode == SafeRouteTravelMode.walking,
          onTap: () => onSelected(SafeRouteTravelMode.walking),
        ),
        _ModeChip(
          icon: Icons.two_wheeler_rounded,
          label: l10n.safeRouteTravelModeLabel(SafeRouteTravelMode.motorbike),
          active: selectedMode == SafeRouteTravelMode.motorbike,
          onTap: () => onSelected(SafeRouteTravelMode.motorbike),
        ),
        _ModeChip(
          icon: Icons.family_restroom_rounded,
          label: l10n.safeRouteTravelModeLabel(SafeRouteTravelMode.pickup),
          active: selectedMode == SafeRouteTravelMode.pickup,
          onTap: () => onSelected(SafeRouteTravelMode.pickup),
        ),
        _ModeChip(
          icon: Icons.directions_car_filled_rounded,
          label: l10n.safeRouteTravelModeLabel(SafeRouteTravelMode.otherVehicle),
          active: selectedMode == SafeRouteTravelMode.otherVehicle,
          onTap: () => onSelected(SafeRouteTravelMode.otherVehicle),
        ),
      ],
    );
  }
}
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? locationPanelColor(scheme) : locationPanelMutedColor(scheme),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: locationPanelBorderColor(scheme),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.scheduledDate,
    required this.scheduledTime,
    required this.repeatWeekdays,
    required this.onPickDate,
    required this.onPickTime,
    required this.onReset,
    required this.onToggleWeekday,
  });

  final DateTime? scheduledDate;
  final TimeOfDay? scheduledTime;
  final List<int> repeatWeekdays;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onReset;
  final ValueChanged<int> onToggleWeekday;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: locationPanelMutedColor(scheme),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: locationPanelBorderColor(scheme)),
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
                    Text(
                      l10n.safeRouteScheduleTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.safeRouteScheduleSubtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _GhostButton(
                label: l10n.safeRouteTrackNowLabel,
                icon: Icons.bolt_rounded,
                onTap: onReset,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ScheduleSelectorTile(
                  icon: Icons.calendar_today_rounded,
                  title: l10n.safeRouteDateLabel,
                  value: l10n.safeRouteFormattedDateLabel(scheduledDate),
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScheduleSelectorTile(
                  icon: Icons.schedule_rounded,
                  title: l10n.safeRouteTimeLabel,
                  value: l10n.safeRouteFormattedTimeLabel(scheduledTime),
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.safeRouteRepeatByDayLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(7, (index) {
              final weekday = index + 1;
              final selected = repeatWeekdays.contains(weekday);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: selected ? scheme.primary : locationPanelColor(scheme),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => onToggleWeekday(weekday),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? scheme.primary
                                : locationPanelBorderColor(scheme),
                          ),
                        ),
                        child: Text(
                          l10n.safeRouteWeekdayShort(weekday),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.safeRouteRepeatSummary(repeatWeekdays),
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
class _ScheduleSelectorTile extends StatelessWidget {
  const _ScheduleSelectorTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: locationPanelColor(scheme),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: locationPanelBorderColor(scheme)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: locationPanelHighlightColor(scheme),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: highlighted
          ? locationPanelHighlightColor(scheme)
          : locationPanelMutedColor(scheme),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: highlighted ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlighted
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    this.icon,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: locationPanelBorderColor(scheme)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: locationPanelMutedColor(scheme),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}








