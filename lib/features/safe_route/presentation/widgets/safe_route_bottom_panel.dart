import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_tracking_visuals.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_tracking_state.dart';
import 'package:kid_manager/features/safe_route/presentation/widgets/safe_route_route_selector.dart';

class SafeRouteBottomPanel extends StatelessWidget {
  const SafeRouteBottomPanel({
    super.key,
    required this.state,
    required this.safetyStatusLabel,
    required this.speedLabel,
    required this.batteryLabel,
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
  final String batteryLabel;
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
    final trackingVisuals = resolveSafeRouteTrackingVisuals(
      state,
      fallbackStatusLabel: safetyStatusLabel,
    );

    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
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
                            color: const Color(0xFFD3DCE7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      if (_hasActiveTrip)
                        _TrackingStatusContent(
                          state: state,
                          safetyStatusLabel: safetyStatusLabel,
                          speedLabel: speedLabel,
                          batteryLabel: batteryLabel,
                          lastUpdatedLabel: lastUpdatedLabel,
                          onCompleteTrip: onCompleteTrip,
                          onCancelTrip: onCancelTrip,
                          onFocusRoute: onFocusRoute,
                          onShowHistory: onShowHistory,
                        )
                      else
                        _RouteSelectionContent(
                          state: state,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn tuyến an toàn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _hintText(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF667085),
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
              label: 'Dùng vị trí hiện tại',
              icon: Icons.my_location_rounded,
              highlighted: true,
              onTap: onUseLiveLocationAsStart,
            ),
            _QuickActionChip(
              label: 'Chọn điểm đi trên bản đồ',
              icon: Icons.trip_origin_rounded,
              onTap: onStartSelectingStart,
            ),
            _QuickActionChip(
              label: 'Chọn điểm đến trên bản đồ',
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Các tuyến đường gợi ý',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Ưu tiên an toàn, dễ theo dõi và ít đi qua vùng nguy hiểm',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
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
                  label: 'Lịch sử',
                  icon: Icons.history_rounded,
                  onTap: onShowHistory,
                ),
                const SizedBox(height: 8),
                _GhostButton(
                  label: state.isFetchingSuggestions ? 'Đang tìm...' : 'Làm mới',
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
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EDF4)),
            ),
            child: Text(
              _emptyRoutesText(),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF617182),
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
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF526074),
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
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: state.isStartingTrip
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Đang xác nhận tuyến...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Text(
                    _canStart ? _primaryActionLabel() : 'Lấy gợi ý tuyến đường',
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
        return 'Chạm trên bản đồ để chọn điểm đi cho bé.';
      case RouteSelectionMode.selectingEnd:
        return 'Chạm trên bản đồ để chọn điểm đến của bé.';
      case RouteSelectionMode.none:
        if (!_hasStart || !_hasEnd) {
          return 'Chọn điểm A và điểm B theo phong cách bản đồ, sau đó xem các tuyến gợi ý.';
        }
        return 'Đã có đủ điểm đi và điểm đến. Bạn có thể chọn tuyến an toàn nhất để bắt đầu giám sát.';
    }
  }

  String _emptyRoutesText() {
    if (!_hasStart || !_hasEnd) {
      return 'Hãy chọn cả điểm đi và điểm đến để app đề xuất các tuyến đường an toàn.';
    }
    return 'Nhấn “Làm mới” hoặc nút phía dưới để lấy lại danh sách tuyến gợi ý.';
  }

  String _primaryActionLabel() {
    if (state.repeatWeekdays.isNotEmpty || state.scheduledDate != null) {
      return 'Lưu tuyến và lên lịch theo dõi';
    }
    if (state.selectedAlternativeRouteIds.isNotEmpty) {
      return 'Bắt đầu theo dõi các tuyến đã chọn';
    }
    return 'Chọn tuyến này và bắt đầu theo dõi';
  }

  String _selectedRoutesSummary() {
    final primary = state.selectedRoute;
    final alternativeCount = state.selectedAlternativeRouteIds.length;
    if (primary == null) {
      return 'Hãy chọn 1 tuyến chính và có thể thêm tối đa 2 tuyến phụ.';
    }
    if (alternativeCount == 0) {
      return 'Đã chọn 1 tuyến chính. Bạn có thể thêm tối đa 2 tuyến phụ.';
    }
    return 'Đã chọn 1 tuyến chính và $alternativeCount tuyến phụ.';
  }
}

class _TrackingStatusContent extends StatelessWidget {
  const _TrackingStatusContent({
    required this.state,
    required this.safetyStatusLabel,
    required this.speedLabel,
    required this.batteryLabel,
    required this.lastUpdatedLabel,
    required this.onCompleteTrip,
    required this.onCancelTrip,
    required this.onFocusRoute,
    required this.onShowHistory,
  });

  final SafeRouteTrackingState state;
  final String safetyStatusLabel;
  final String speedLabel;
  final String batteryLabel;
  final String lastUpdatedLabel;
  final VoidCallback onCompleteTrip;
  final VoidCallback onCancelTrip;
  final VoidCallback onFocusRoute;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    final visuals = resolveSafeRouteTrackingVisuals(
      state,
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      visuals.subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF667085),
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
          Row(
            children: [
              Expanded(
                child: _TrackingMetricCard(
                  label: 'Tốc độ',
                  value: speedLabel,
                  subtitle: _speedSubtitle(state),
                  tint: isDanger
                      ? const Color(0xFFFEF2F2)
                      : visuals.softColor,
                  borderColor: isDanger
                      ? const Color(0xFFFECACA)
                      : visuals.borderColor.withOpacity(0.55),
                  valueColor: isDanger ? const Color(0xFF991B1B) : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BatteryMetricCard(
                  batteryLabel: batteryLabel,
                  tint: Colors.white,
                  fillColor: isDanger
                      ? const Color(0xFFEF4444)
                      : isWarning
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingMetricCard(
                  label: isDanger
                      ? 'Lệch tuyến'
                      : isWarning
                          ? 'Lệch khỏi'
                          : 'Đến nơi',
                  value: isDanger || isWarning
                      ? '${distanceFromRoute}m'
                      : _etaLabel(state),
                  subtitle: isDanger
                      ? (hazard?.name ?? 'Cần kiểm tra ngay')
                      : isWarning
                          ? 'Ngoài corridor'
                          : 'Ước tính',
                  tint: isDanger
                      ? const Color(0xFFFEF2F2)
                      : visuals.softColor,
                  borderColor: isDanger
                      ? const Color(0xFFFECACA)
                      : visuals.borderColor.withOpacity(0.55),
                  valueColor: isDanger ? const Color(0xFF991B1B) : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7EDF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.activeRoute!.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
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
                      label: _distanceLabel(state.activeRoute!.distanceMeters),
                    ),
                    _InlineChip(
                      icon: Icons.schedule_rounded,
                      label: _durationLabel(state.activeRoute!.durationSeconds),
                    ),
                    _InlineChip(
                      icon: Icons.warning_amber_rounded,
                      label: '${state.activeRoute!.hazards.length} vùng nguy hiểm',
                    ),
                    if (state.activeTrip?.scheduledStartAt != null)
                      _InlineChip(
                        icon: Icons.event_rounded,
                        label: _scheduledLabel(state.activeTrip!.scheduledStartAt!),
                      ),
                    if (state.activeTrip?.repeatWeekdays.isNotEmpty == true)
                      _InlineChip(
                        icon: Icons.repeat_rounded,
                        label: state.activeTrip!.repeatWeekdays
                            .map(_weekdayLabel)
                            .join(', '),
                      ),
                    _InlineChip(
                      icon: Icons.traffic_rounded,
                      label: _currentRouteUsageLabel(state),
                    ),
                    if (state.activeAlternativeRoutes.isNotEmpty)
                      _InlineChip(
                        icon: Icons.alt_route_rounded,
                        label: '+${state.activeAlternativeRoutes.length} tuyến phụ',
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
              label: 'Lịch sử',
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
                  label: 'Dừng theo dõi',
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFF991B1B),
                  borderColor: const Color(0xFFFCA5A5),
                  onTap: onCancelTrip,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: 'Xem tuyến',
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  onTap: onFocusRoute,
                ),
              ),
            ],
          )
        else if (isWarning)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: 'Dừng theo dõi',
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFF8FAFC),
                  foregroundColor: const Color(0xFF475569),
                  borderColor: const Color(0xFFCBD5E1),
                  onTap: onCancelTrip,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: 'Xem tuyến',
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFFFF7ED),
                  foregroundColor: const Color(0xFFB45309),
                  borderColor: const Color(0xFFFCD34D),
                  onTap: onFocusRoute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: 'Đánh dấu đã đến',
                  icon: Icons.flag_rounded,
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  onTap: onCompleteTrip,
                ),
              ),
            ],
          )
        else if (state.activeTrip?.status == TripStatus.planned)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: 'Hủy lịch',
                  icon: Icons.close_rounded,
                  backgroundColor: const Color(0xFFF8FAFC),
                  foregroundColor: const Color(0xFF475569),
                  borderColor: const Color(0xFFCBD5E1),
                  onTap: onCancelTrip,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: 'Xem tuyến',
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: onFocusRoute,
                ),
              ),
            ],
          )
        else if (state.activeTrip?.status == TripStatus.completed)
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: 'Xem tuyến',
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: onFocusRoute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: 'Chọn tuyến mới',
                  icon: Icons.alt_route_rounded,
                  backgroundColor: const Color(0xFFF0FDF4),
                  foregroundColor: const Color(0xFF15803D),
                  borderColor: const Color(0xFFBBF7D0),
                  onTap: onCompleteTrip,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _TrackingActionButton(
                  label: 'Chi tiết tuyến',
                  icon: Icons.route_rounded,
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF1D4ED8),
                  borderColor: const Color(0xFFBFDBFE),
                  onTap: onFocusRoute,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrackingActionButton(
                  label: 'Đánh dấu đã đến',
                  icon: Icons.check_circle_rounded,
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  onTap: onCompleteTrip,
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
    if (speed < 1) return 'Đứng yên';
    if (speed < 7) return 'Đi bộ';
    if (speed < 18) return 'Đi xe đạp';
    return 'Di chuyển';
  }

  String _etaLabel(SafeRouteTrackingState state) {
    final durationSeconds = state.activeRoute?.durationSeconds ?? 0;
    final minutes = (durationSeconds / 60).round();
    if (minutes <= 0) return '--';
    if (minutes < 60) return '~$minutes phút';
    final hours = minutes ~/ 60;
    final remainMinutes = minutes % 60;
    if (remainMinutes == 0) return '~$hours giờ';
    return '~$hours giờ ${remainMinutes}p';
  }

  String _currentRouteUsageLabel(SafeRouteTrackingState state) {
    final trip = state.activeTrip;
    final activeRoute = state.activeRoute;
    if (trip == null || activeRoute == null) {
      return 'Đang đi trên tuyến chính';
    }

    if (activeRoute.id == trip.routeId) {
      return 'Đang đi trên tuyến chính';
    }

    final alternativeIndex = trip.alternativeRouteIds.indexOf(activeRoute.id);
    if (alternativeIndex >= 0) {
      return 'Đang đi trên tuyến phụ ${alternativeIndex + 1}';
    }

    return 'Đang đi trên tuyến phụ';
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

  String _scheduledLabel(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
    }
    return '';
  }
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
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF667085),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 16,
                color: Color(0xFF1A73E8),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tiến độ hành trình',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Đã đi ${(details.progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A73E8),
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
                  'Đã đi ${_distanceCompactLabel(details.traveledMeters)}/${_distanceCompactLabel(details.totalMeters)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Còn lại ${((1 - details.progress).clamp(0.0, 1.0) * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Còn ${_distanceCompactLabel((details.totalMeters - details.traveledMeters).clamp(0.0, details.totalMeters).toDouble())}',
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  String _distanceCompactLabel(double meters) {
    if (meters <= 0) return '0 m';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(meters >= 10000 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
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
    required this.batteryLabel,
    required this.tint,
    required this.fillColor,
  });

  final String batteryLabel;
  final Color tint;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final normalized = batteryLabel.replaceAll('%', '').trim();
    final value = double.tryParse(normalized) ?? 0;
    final progress = (value / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pin thiết bị',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            batteryLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
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
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
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
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
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
    required this.onClearStart,
    required this.onClearEnd,
    required this.onSwapTap,
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 28,
            bottom: 28,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFDAE6F5),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 50,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onSwapTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE7EDF4)),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 20,
                    color: onSwapTap == null
                        ? const Color(0xFFB0BDC9)
                        : const Color(0xFF526074),
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
                  title: 'Từ',
                  value: _pointLabel(
                    start,
                    label: startLabel,
                    fallback: 'Tìm hoặc chọn điểm đi',
                  ),
                  dotColor: const Color(0xFF1A73E8),
                  selected: selectionMode == RouteSelectionMode.selectingStart,
                  onTap: onStartTap,
                  onClearTap: onClearStart,
                ),
                const SizedBox(height: 10),
                _LocationRow(
                  title: 'Đến',
                  value: _pointLabel(
                    end,
                    label: endLabel,
                    fallback: 'Tìm hoặc chọn điểm đến',
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
    return Material(
      color: selected ? const Color(0xFFEFF5FF) : Colors.transparent,
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
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7B8799),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: onClearTap,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ModeChip(
          icon: Icons.directions_walk_rounded,
          label: SafeRouteTravelMode.walking.label,
          active: selectedMode == SafeRouteTravelMode.walking,
          onTap: () => onSelected(SafeRouteTravelMode.walking),
        ),
        _ModeChip(
          icon: Icons.two_wheeler_rounded,
          label: SafeRouteTravelMode.motorbike.label,
          active: selectedMode == SafeRouteTravelMode.motorbike,
          onTap: () => onSelected(SafeRouteTravelMode.motorbike),
        ),
        _ModeChip(
          icon: Icons.family_restroom_rounded,
          label: SafeRouteTravelMode.pickup.label,
          active: selectedMode == SafeRouteTravelMode.pickup,
          onTap: () => onSelected(SafeRouteTravelMode.pickup),
        ),
        _ModeChip(
          icon: Icons.directions_car_filled_rounded,
          label: SafeRouteTravelMode.otherVehicle.label,
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
    return Material(
      color: active ? Colors.white : const Color(0xFFF4F7FB),
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
              color: active ? const Color(0xFFCEE0FA) : const Color(0xFFE7EDF4),
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
                color: active ? const Color(0xFF1A73E8) : const Color(0xFF607182),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF1A73E8) : const Color(0xFF607182),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch áp dụng tuyến',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đặt ngày, giờ và chọn các ngày lặp lại cho tuyến đường an toàn này.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF667085),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _GhostButton(
                label: 'Theo dõi ngay',
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
                  title: 'Ngày',
                  value: _dateLabel(scheduledDate),
                  onTap: onPickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScheduleSelectorTile(
                  icon: Icons.schedule_rounded,
                  title: 'Giờ',
                  value: _timeLabel(scheduledTime),
                  onTap: onPickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Lặp lại theo ngày',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF526074),
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
                    color: selected
                        ? const Color(0xFF1A73E8)
                        : Colors.white,
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
                                ? const Color(0xFF1A73E8)
                                : const Color(0xFFE7EDF4),
                          ),
                        ),
                        child: Text(
                          _weekdayLabel(weekday),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : const Color(0xFF607182),
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
            _repeatSummary(repeatWeekdays),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF667085),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Hôm nay';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final normalized = DateTime(value.year, value.month, value.day);
    if (normalized == today) return 'Hôm nay';
    if (normalized == tomorrow) return 'Ngày mai';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _timeLabel(TimeOfDay? value) {
    if (value == null) {
      return 'Bây giờ';
    }
    final effective = value;
    return '${effective.hour.toString().padLeft(2, '0')}:${effective.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
    }
    return '';
  }

  String _repeatSummary(List<int> weekdays) {
    if (weekdays.isEmpty) {
      return 'Không lặp lại, tuyến sẽ được áp dụng cho một lịch theo dõi gần nhất.';
    }
    final labels = weekdays.map(_weekdayLabel).join(', ');
    return 'Lặp lại vào: $labels';
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EDF4)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: const Color(0xFF1A73E8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
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
    return Material(
      color: highlighted ? const Color(0xFFEAF2FF) : const Color(0xFFF4F7FB),
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
                color: highlighted
                    ? const Color(0xFF1A73E8)
                    : const Color(0xFF526074),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: highlighted
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF526074),
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF1A73E8),
        side: const BorderSide(color: Color(0xFFDCE8F8)),
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

class _StatusHighlightCard extends StatelessWidget {
  const _StatusHighlightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: foregroundColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF526074),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF78859A),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1A73E8)),
          const SizedBox(width: 6),
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

String _distanceLabel(double distanceMeters) {
  if (distanceMeters >= 1000) {
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
  return '${distanceMeters.round()} m';
}

String _durationLabel(double durationSeconds) {
  final minutes = (durationSeconds / 60).round();
  if (minutes < 60) return '$minutes phút';
  final hours = minutes ~/ 60;
  final remainMinutes = minutes % 60;
  if (remainMinutes == 0) return '$hours giờ';
  return '$hours giờ $remainMinutes phút';
}

Color _statusColor(TripStatus? status) {
  switch (status) {
    case TripStatus.active:
      return const Color(0xFF15803D);
    case TripStatus.temporarilyDeviated:
      return const Color(0xFFB45309);
    case TripStatus.deviated:
      return const Color(0xFFB91C1C);
    case TripStatus.completed:
      return const Color(0xFF1D4ED8);
    case TripStatus.cancelled:
      return const Color(0xFF64748B);
    case TripStatus.planned:
      return const Color(0xFF1D4ED8);
    case null:
      return const Color(0xFF0F172A);
  }
}

Color _statusBackground(TripStatus? status) {
  switch (status) {
    case TripStatus.active:
      return const Color(0xFFEAF8EF);
    case TripStatus.temporarilyDeviated:
      return const Color(0xFFFFF3E4);
    case TripStatus.deviated:
      return const Color(0xFFFFE9E9);
    case TripStatus.completed:
      return const Color(0xFFEAF2FF);
    case TripStatus.cancelled:
      return const Color(0xFFF1F5F9);
    case TripStatus.planned:
      return const Color(0xFFEAF2FF);
    case null:
      return const Color(0xFFF1F5F9);
  }
}

IconData _statusIcon(TripStatus? status) {
  switch (status) {
    case TripStatus.active:
      return Icons.shield_rounded;
    case TripStatus.temporarilyDeviated:
      return Icons.near_me_outlined;
    case TripStatus.deviated:
      return Icons.warning_amber_rounded;
    case TripStatus.completed:
      return Icons.flag_circle_rounded;
    case TripStatus.cancelled:
      return Icons.pause_circle_outline_rounded;
    case TripStatus.planned:
      return Icons.route_rounded;
    case null:
      return Icons.route_rounded;
  }
}
