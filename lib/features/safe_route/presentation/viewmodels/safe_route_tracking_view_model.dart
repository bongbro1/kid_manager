import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_suggested_routes_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_trip_history_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/start_trip_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/stream_live_location_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/update_trip_status_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_tracking_state.dart';

class SafeRouteTrackingViewModel extends ChangeNotifier {
  SafeRouteTrackingViewModel({
    required this.childId,
    required GetSuggestedRoutesUseCase getSuggestedRoutesUseCase,
    required StartTripUseCase startTripUseCase,
    required StreamLiveLocationUseCase streamLiveLocationUseCase,
    required UpdateTripStatusUseCase updateTripStatusUseCase,
    required GetActiveTripByChildIdUseCase getActiveTripByChildIdUseCase,
    required GetTripHistoryByChildIdUseCase getTripHistoryByChildIdUseCase,
    required GetRouteByIdUseCase getRouteByIdUseCase,
    FirebaseAuth? auth,
  }) : _getSuggestedRoutesUseCase = getSuggestedRoutesUseCase,
       _startTripUseCase = startTripUseCase,
       _streamLiveLocationUseCase = streamLiveLocationUseCase,
       _updateTripStatusUseCase = updateTripStatusUseCase,
       _getActiveTripByChildIdUseCase = getActiveTripByChildIdUseCase,
       _getTripHistoryByChildIdUseCase = getTripHistoryByChildIdUseCase,
       _getRouteByIdUseCase = getRouteByIdUseCase,
       _auth = auth ?? FirebaseAuth.instance,
       _state = SafeRouteTrackingState.initial(childId);

  final String childId;
  final GetSuggestedRoutesUseCase _getSuggestedRoutesUseCase;
  final StartTripUseCase _startTripUseCase;
  final StreamLiveLocationUseCase _streamLiveLocationUseCase;
  final UpdateTripStatusUseCase _updateTripStatusUseCase;
  final GetActiveTripByChildIdUseCase _getActiveTripByChildIdUseCase;
  final GetTripHistoryByChildIdUseCase _getTripHistoryByChildIdUseCase;
  final GetRouteByIdUseCase _getRouteByIdUseCase;
  final FirebaseAuth _auth;

  SafeRouteTrackingState _state;
  SafeRouteTrackingState get state => _state;

  StreamSubscription? _liveLocationSub;
  Timer? _tripRefreshTimer;
  bool _isRefreshingTrip = false;
  String? _dismissedCompletedTripId;

  static const Duration _tripRefreshInterval = Duration(seconds: 5);

  bool get canFetchSuggestions =>
      _state.selectedStart != null &&
      _state.selectedEnd != null &&
      !_state.isFetchingSuggestions;

  bool get canStartTrip =>
      _state.selectedRoute != null && !_state.isStartingTrip;

  String get safetyStatusLabel {
    final status = _state.activeTrip?.status;
    switch (status) {
      case TripStatus.active:
        return 'Đang an toàn';
      case TripStatus.temporarilyDeviated:
        return 'Tạm lệch tuyến';
      case TripStatus.deviated:
        return 'Lệch tuyến';
      case TripStatus.completed:
        return 'Đã hoàn thành';
      case TripStatus.cancelled:
        return 'Đã huỷ';
      case TripStatus.planned:
        return 'Đã lên lịch';
      case null:
        return 'Chưa có chuyến đi';
    }
  }

  void _log(String message) {
    debugPrint('[SafeRouteVM] $message');
  }

  String get speedLabel {
    final speedKmh = (_state.liveLocation?.speedKmh ?? 0).toStringAsFixed(1);
    return '$speedKmh km/h';
  }

  String get batteryLabel {
    final battery = _state.liveLocation?.batteryLevel;
    if (battery == null) return '--';
    return '${battery.round()}%';
  }

  void setScheduledDate(DateTime? value) {
    final normalized = value == null
        ? null
        : DateTime(value.year, value.month, value.day);
    final fallbackTime = normalized != null && _state.scheduledTime == null
        ? TimeOfDay.now()
        : _state.scheduledTime;

    _setState(
      _state.copyWith(
        scheduledDate: normalized,
        scheduledTime: fallbackTime,
        clearErrorMessage: true,
      ),
    );
  }

  void setScheduledTime(TimeOfDay? value) {
    final fallbackDate = value != null && _state.scheduledDate == null
        ? DateTime.now()
        : _state.scheduledDate;

    _setState(
      _state.copyWith(
        scheduledDate: fallbackDate,
        scheduledTime: value,
        clearErrorMessage: true,
      ),
    );
  }

  void toggleRepeatWeekday(int weekday) {
    if (weekday < 1 || weekday > 7) return;
    final next = [..._state.repeatWeekdays];
    if (next.contains(weekday)) {
      next.remove(weekday);
    } else {
      next.add(weekday);
      next.sort();
    }

    _setState(_state.copyWith(repeatWeekdays: next, clearErrorMessage: true));
  }

  void resetSchedule() {
    _setState(
      _state.copyWith(
        scheduledDate: null,
        scheduledTime: null,
        repeatWeekdays: const [],
        clearErrorMessage: true,
      ),
    );
  }

  void applyInitialStartPoint(RoutePoint point) {
    _setState(
      _state.copyWith(
        selectedStart: point,
        selectedStartLabel: _formatPointLabel(point),
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void toggleAlternativeSuggestedRoute(SafeRoute route) {
    if (_state.selectedRoute?.id == route.id) return;

    final next = [..._state.selectedAlternativeRouteIds];
    if (next.contains(route.id)) {
      next.remove(route.id);
    } else {
      if (next.length >= 2) {
        _setState(
          _state.copyWith(
            errorMessage: 'Chỉ nên chọn tối đa 2 tuyến phụ cho mỗi chuyến.',
          ),
        );
        return;
      }
      next.add(route.id);
    }

    _setState(
      _state.copyWith(
        selectedAlternativeRouteIds: next,
        clearErrorMessage: true,
      ),
    );
  }

  void clearRouteSelection() {
    _setState(
      _state.copyWith(
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void selectTravelMode(SafeRouteTravelMode mode) {
    if (_state.selectedTravelMode == mode) return;

    _setState(
      _state.copyWith(
        selectedTravelMode: mode,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void swapSelectedPoints() {
    final start = _state.selectedStart;
    final end = _state.selectedEnd;
    if (start == null || end == null) return;

    _setState(
      _state.copyWith(
        selectedStart: end.copyWith(sequence: 0),
        selectedEnd: start.copyWith(sequence: 1),
        selectedStartLabel: _state.selectedEndLabel ?? _formatPointLabel(end),
        selectedEndLabel: _state.selectedStartLabel ?? _formatPointLabel(start),
        suggestedRoutes: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> initialize() async {
    _setState(_state.copyWith(isLoading: true, clearErrorMessage: true));
    await _bindLiveLocation();
    await refreshActiveTrip();
    _tripRefreshTimer?.cancel();
    _tripRefreshTimer = Timer.periodic(_tripRefreshInterval, (_) {
      unawaited(refreshActiveTrip());
    });
    _setState(_state.copyWith(isLoading: false));
  }

  Future<void> refreshActiveTrip() async {
    if (_isRefreshingTrip) return;
    _isRefreshingTrip = true;
    try {
      var trip = await _getActiveTripByChildIdUseCase(childId);
      if (trip?.status == TripStatus.completed &&
          trip?.id == _dismissedCompletedTripId) {
        trip = null;
      } else if (trip == null || trip.status != TripStatus.completed) {
        _dismissedCompletedTripId = null;
      }
      SafeRoute? route;
      List<SafeRoute> alternativeRoutes = const [];
      if (trip != null) {
        final routeGroup = await _loadRouteGroupForTrip(trip);
        route = routeGroup.primaryRoute;
        alternativeRoutes = routeGroup.alternativeRoutes;
      }

      final fallbackLiveLocation = trip?.lastLocation;
      final nextLiveLocation =
          fallbackLiveLocation != null &&
              (_state.liveLocation == null ||
                  fallbackLiveLocation.timestamp >
                      _state.liveLocation!.timestamp)
          ? fallbackLiveLocation
          : _state.liveLocation;

      _setState(
        _state.copyWith(
          activeTrip: trip,
          activeRoute: route,
          activeAlternativeRoutes: alternativeRoutes,
          liveLocation: nextLiveLocation,
          scheduledDate: trip == null
              ? _state.scheduledDate
              : trip.scheduledStartAt == null
              ? null
              : DateTime(
                  trip.scheduledStartAt!.year,
                  trip.scheduledStartAt!.month,
                  trip.scheduledStartAt!.day,
                ),
          scheduledTime: trip == null
              ? _state.scheduledTime
              : trip.scheduledStartAt == null
              ? null
              : TimeOfDay(
                  hour: trip.scheduledStartAt!.hour,
                  minute: trip.scheduledStartAt!.minute,
                ),
          repeatWeekdays: trip == null
              ? _state.repeatWeekdays
              : trip.repeatWeekdays,
          selectedAlternativeRouteIds: trip == null
              ? _state.selectedAlternativeRouteIds
              : trip.alternativeRouteIds,
          clearActiveTrip: trip == null,
          clearActiveRoute: route == null,
        ),
      );
    } catch (error) {
      debugPrint('Error refreshing active trip: $error');
      _setState(_state.copyWith(errorMessage: error.toString()));
    } finally {
      _isRefreshingTrip = false;
    }
  }

  Future<void> _bindLiveLocation() async {
    await _liveLocationSub?.cancel();
    _liveLocationSub = _streamLiveLocationUseCase(childId).listen(
      (location) {
        debugPrint('Live location updated: $location');
        _setState(_state.copyWith(liveLocation: location));
      },
      onError: (error) {
        debugPrint('Error occurred while streaming live location: $error');
        _setState(_state.copyWith(errorMessage: error.toString()));
      },
    );
  }

  void startSelectingStart() {
    _setState(
      _state.copyWith(
        selectionMode: RouteSelectionMode.selectingStart,
        clearErrorMessage: true,
      ),
    );
  }

  void startSelectingEnd() {
    _setState(
      _state.copyWith(
        selectionMode: RouteSelectionMode.selectingEnd,
        clearErrorMessage: true,
      ),
    );
  }

  void cancelSelection() {
    if (_state.selectionMode == RouteSelectionMode.none) return;
    _setState(
      _state.copyWith(
        selectionMode: RouteSelectionMode.none,
        clearErrorMessage: true,
      ),
    );
  }

  void useLiveLocationAsStart() {
    final liveLocation = _state.liveLocation;
    if (liveLocation == null) {
      _setState(
        _state.copyWith(errorMessage: 'Chưa có vị trí hiện tại của trẻ.'),
      );
      return;
    }

    _setState(
      _state.copyWith(
        selectedStart: RoutePoint(
          latitude: liveLocation.latitude,
          longitude: liveLocation.longitude,
          sequence: 0,
        ),
        selectedStartLabel: 'Vị trí hiện tại',
        selectionMode: RouteSelectionMode.none,
        clearErrorMessage: true,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
      ),
    );
  }

  void onMapPointSelected(double latitude, double longitude) {
    _log(
      'onMapPointSelected: mode=${_state.selectionMode}, '
      'lat=$latitude, lng=$longitude',
    );

    final point = RoutePoint(
      latitude: latitude,
      longitude: longitude,
      sequence: _state.selectionMode == RouteSelectionMode.selectingEnd ? 1 : 0,
    );

    if (_state.selectionMode == RouteSelectionMode.selectingStart) {
      final nextState = _state.copyWith(
        selectedStart: point,
        selectedStartLabel: _formatPointLabel(point),
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      );

      _log('setting selectedStart = ${_formatPointLabel(point)}');
      _setState(nextState);
      return;
    }

    if (_state.selectionMode == RouteSelectionMode.selectingEnd) {
      final nextState = _state.copyWith(
        selectedEnd: point,
        selectedEndLabel: _formatPointLabel(point),
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      );

      _log('setting selectedEnd = ${_formatPointLabel(point)}');
      _setState(nextState);
      return;
    }

    _log('ignored because mode is none');
  }

  void setStartPoint(RoutePoint point, {String? label}) {
    _setState(
      _state.copyWith(
        selectedStart: point.copyWith(sequence: 0),
        selectedStartLabel: label ?? _formatPointLabel(point),
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void setEndPoint(RoutePoint point, {String? label}) {
    _setState(
      _state.copyWith(
        selectedEnd: point.copyWith(sequence: 1),
        selectedEndLabel: label ?? _formatPointLabel(point),
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void clearStartPoint() {
    _setState(
      _state.copyWith(
        selectedStart: null,
        selectedStartLabel: null,
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void clearEndPoint() {
    _setState(
      _state.copyWith(
        selectedEnd: null,
        selectedEndLabel: null,
        selectionMode: RouteSelectionMode.none,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> fetchSuggestedRoutes() async {
    final start = _state.selectedStart;
    final end = _state.selectedEnd;
    if (start == null || end == null) {
      _setState(
        _state.copyWith(errorMessage: 'Cần chọn điểm A và điểm B trước.'),
      );
      return;
    }

    _setState(
      _state.copyWith(
        isFetchingSuggestions: true,
        clearErrorMessage: true,
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
      ),
    );

    try {
      final routes = await _getSuggestedRoutesUseCase(
        start,
        end,
        childId: childId,
        travelMode: _state.selectedTravelMode,
      );
      _setState(
        _state.copyWith(
          isFetchingSuggestions: false,
          suggestedRoutes: routes,
          selectedRoute: routes.isEmpty ? null : routes.first,
          selectedAlternativeRouteIds: const [],
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(
          isFetchingSuggestions: false,
          errorMessage: error.toString(),
        ),
      );

      debugPrint("fetchSuggestedRoutes $error");
    }
  }

  void selectSuggestedRoute(SafeRoute route) {
    final alternativeIds = _state.selectedAlternativeRouteIds
        .where((id) => id != route.id)
        .toList(growable: false);
    _setState(
      _state.copyWith(
        selectedRoute: route,
        selectedAlternativeRouteIds: alternativeIds,
        clearErrorMessage: true,
      ),
    );
  }

  Future<List<Trip>> loadTripHistory() {
    return _getTripHistoryByChildIdUseCase(childId);
  }

  Future<void> previewTripHistory(Trip trip) async {
    final route = await _getRouteByIdUseCase(trip.routeId);
    if (route == null) {
      _setState(
        _state.copyWith(
          errorMessage: 'Không tải được tuyến đường trong lịch sử.',
        ),
      );
      return;
    }

    final scheduledStartAt = trip.scheduledStartAt;
    _setState(
      _state.copyWith(
        selectedStart: route.startPoint.copyWith(sequence: 0),
        selectedEnd: route.endPoint.copyWith(sequence: 1),
        selectedStartLabel: 'Điểm bắt đầu của tuyến',
        selectedEndLabel: 'Điểm kết thúc của tuyến',
        suggestedRoutes: [route],
        selectedRoute: route,
        selectedAlternativeRouteIds: trip.alternativeRouteIds,
        scheduledDate: scheduledStartAt == null
            ? null
            : DateTime(
                scheduledStartAt.year,
                scheduledStartAt.month,
                scheduledStartAt.day,
              ),
        scheduledTime: scheduledStartAt == null
            ? null
            : TimeOfDay(
                hour: scheduledStartAt.hour,
                minute: scheduledStartAt.minute,
              ),
        repeatWeekdays: trip.repeatWeekdays,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> startTrip() async {
    final route = _state.selectedRoute;
    final parentId = _auth.currentUser?.uid;
    if (route == null) {
      _setState(
        _state.copyWith(errorMessage: 'Cần chọn một tuyến đường an toàn.'),
      );
      return;
    }
    if (parentId == null || parentId.isEmpty) {
      _setState(
        _state.copyWith(
          errorMessage: 'Bạn cần đăng nhập lại để bắt đầu chuyến đi.',
        ),
      );
      return;
    }
    if (_state.repeatWeekdays.isNotEmpty && _state.scheduledTime == null) {
      _setState(
        _state.copyWith(
          errorMessage: 'Chọn giờ áp dụng nếu muốn lặp lại theo ngày.',
        ),
      );
      return;
    }

    _setState(_state.copyWith(isStartingTrip: true, clearErrorMessage: true));

    try {
      _dismissedCompletedTripId = null;
      final scheduledStartAt = _buildScheduledStartAt();
      final createdTrip = await _startTripUseCase(
        Trip(
          id: '',
          childId: childId,
          parentId: parentId,
          routeId: route.id,
          alternativeRouteIds: _state.selectedAlternativeRouteIds,
          currentRouteId: route.id,
          routeName: route.name,
          status: TripStatus.active,
          reason: null,
          consecutiveDeviationCount: 0,
          currentDistanceFromRouteMeters: 0,
          startedAt: DateTime.now(),
          updatedAt: DateTime.now(),
          scheduledStartAt: scheduledStartAt,
          repeatWeekdays: _state.repeatWeekdays,
          lastLocation: null,
        ),
      );

      _setState(
        _state.copyWith(
          isStartingTrip: false,
          activeTrip: createdTrip,
          activeRoute: route,
          activeAlternativeRoutes: _state.suggestedRoutes
              .where(
                (item) => _state.selectedAlternativeRouteIds.contains(item.id),
              )
              .toList(growable: false),
          scheduledDate: scheduledStartAt == null
              ? _state.scheduledDate
              : DateTime(
                  scheduledStartAt.year,
                  scheduledStartAt.month,
                  scheduledStartAt.day,
                ),
          scheduledTime: scheduledStartAt == null
              ? _state.scheduledTime
              : TimeOfDay(
                  hour: scheduledStartAt.hour,
                  minute: scheduledStartAt.minute,
                ),
          suggestedRoutes: const [],
          selectedAlternativeRouteIds: const [],
          clearSelectedRoute: true,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(isStartingTrip: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> completeTrip() async {
    final trip = _state.activeTrip;
    if (trip == null) return;
    _dismissedCompletedTripId = null;
    await _updateTripStatusUseCase(trip.id, TripStatus.completed);
    await refreshActiveTrip();
  }

  Future<void> cancelTrip() async {
    final trip = _state.activeTrip;
    if (trip == null) return;
    _dismissedCompletedTripId = null;
    await _updateTripStatusUseCase(
      trip.id,
      TripStatus.cancelled,
      reason: 'Đã hủy bởi phụ huynh',
    );
    await refreshActiveTrip();
  }

  void returnToRouteSelection() {
    final activeTrip = _state.activeTrip;
    final activeRoute = _state.activeRoute;

    if (activeTrip?.status == TripStatus.completed) {
      _dismissedCompletedTripId = activeTrip!.id;
    } else {
      _dismissedCompletedTripId = null;
    }

    final fallbackStart =
        _state.selectedStart ?? activeRoute?.startPoint.copyWith(sequence: 0);
    final fallbackEnd =
        _state.selectedEnd ?? activeRoute?.endPoint.copyWith(sequence: 1);

    _setState(
      _state.copyWith(
        selectionMode: RouteSelectionMode.none,
        selectedStart: fallbackStart,
        selectedEnd: fallbackEnd,
        selectedStartLabel:
            _state.selectedStartLabel ??
            (activeRoute == null
                ? null
                : _formatPointLabel(activeRoute.startPoint)),
        selectedEndLabel:
            _state.selectedEndLabel ??
            (activeRoute == null
                ? null
                : _formatPointLabel(activeRoute.endPoint)),
        scheduledDate: null,
        scheduledTime: null,
        repeatWeekdays: const [],
        suggestedRoutes: const [],
        selectedAlternativeRouteIds: const [],
        clearSelectedRoute: true,
        clearActiveTrip: true,
        clearActiveRoute: true,
        clearErrorMessage: true,
      ),
    );
  }

  void clearError() {
    if (_state.errorMessage == null) return;
    _setState(_state.copyWith(clearErrorMessage: true));
  }

  DateTime? _buildScheduledStartAt() {
    final scheduledDate = _state.scheduledDate;
    final scheduledTime = _state.scheduledTime;
    if (scheduledDate == null && scheduledTime == null) {
      return null;
    }

    final baseDate = scheduledDate ?? DateTime.now();
    final baseTime = scheduledTime ?? TimeOfDay.now();
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      baseTime.hour,
      baseTime.minute,
    );
  }

  Future<_ResolvedRouteGroup> _loadRouteGroupForTrip(Trip trip) async {
    final primaryRoute = await _getRouteByIdUseCase(trip.routeId);
    if (primaryRoute == null) {
      return const _ResolvedRouteGroup(
        primaryRoute: null,
        alternativeRoutes: [],
      );
    }

    final alternativeRouteIds = trip.alternativeRouteIds
        .where((routeId) => routeId != primaryRoute.id)
        .toList(growable: false);

    final alternativeRoutes = (await Future.wait(
      alternativeRouteIds.map((routeId) => _getRouteByIdUseCase(routeId)),
    )).whereType<SafeRoute>().toList(growable: false);

    final currentRouteId = trip.currentRouteId;
    if (currentRouteId == null || currentRouteId == primaryRoute.id) {
      return _ResolvedRouteGroup(
        primaryRoute: primaryRoute,
        alternativeRoutes: alternativeRoutes,
      );
    }

    SafeRoute? matchedAlternative;
    for (final route in alternativeRoutes) {
      if (route.id == currentRouteId) {
        matchedAlternative = route;
        break;
      }
    }

    if (matchedAlternative == null) {
      return _ResolvedRouteGroup(
        primaryRoute: primaryRoute,
        alternativeRoutes: alternativeRoutes,
      );
    }

    return _ResolvedRouteGroup(
      primaryRoute: matchedAlternative,
      alternativeRoutes: [
        primaryRoute,
        ...alternativeRoutes.where(
          (route) => route.id != matchedAlternative?.id,
        ),
      ],
    );
  }

  void _setState(SafeRouteTrackingState next) {
    _log(
      'state change: '
      'mode ${_state.selectionMode} -> ${next.selectionMode}, '
      'start ${_state.selectedStartLabel} -> ${next.selectedStartLabel}, '
      'end ${_state.selectedEndLabel} -> ${next.selectedEndLabel}',
    );
    _state = next;
    notifyListeners();
  }

  String _formatPointLabel(RoutePoint point) {
    return '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
  }

  @override
  void dispose() {
    _liveLocationSub?.cancel();
    _tripRefreshTimer?.cancel();
    super.dispose();
  }
}

class _ResolvedRouteGroup {
  const _ResolvedRouteGroup({
    required this.primaryRoute,
    required this.alternativeRoutes,
  });

  final SafeRoute? primaryRoute;
  final List<SafeRoute> alternativeRoutes;
}
