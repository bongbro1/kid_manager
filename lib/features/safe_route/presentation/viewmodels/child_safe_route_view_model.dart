import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/watch_current_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/features/safe_route/presentation/states/child_safe_route_state.dart';
import 'package:kid_manager/models/location/location_data.dart';

class ChildSafeRouteViewModel extends ChangeNotifier {
  ChildSafeRouteViewModel({
    required this.childId,
    required GetActiveTripByChildIdUseCase getActiveTripByChildIdUseCase,
    required WatchCurrentTripByChildIdUseCase watchCurrentTripByChildIdUseCase,
    required GetRouteByIdUseCase getRouteByIdUseCase,
  }) : _getActiveTripByChildIdUseCase = getActiveTripByChildIdUseCase,
       _watchCurrentTripByChildIdUseCase = watchCurrentTripByChildIdUseCase,
       _getRouteByIdUseCase = getRouteByIdUseCase,
       _state = ChildSafeRouteState.initial(childId);

  final String childId;
  final GetActiveTripByChildIdUseCase _getActiveTripByChildIdUseCase;
  final WatchCurrentTripByChildIdUseCase _watchCurrentTripByChildIdUseCase;
  final GetRouteByIdUseCase _getRouteByIdUseCase;

  static const Duration _refreshInterval = Duration(minutes: 1);
  static const Duration _arrivalRefreshCooldown = Duration(seconds: 4);

  ChildSafeRouteState _state;
  ChildSafeRouteState get state => _state;

  Timer? _refreshTimer;
  StreamSubscription<Trip?>? _tripSub;
  String _languageCode = 'vi';
  DateTime? _lastArrivalRefreshAt;
  bool _disposed = false;
  int _lifecycleGeneration = 0;

  void initialize({
    required String languageCode,
    LocationData? initialLocation,
  }) {
    if (_disposed) return;
    final generation = ++_lifecycleGeneration;
    _languageCode = languageCode;
    if (initialLocation != null) {
      _state = _state.copyWith(currentLocation: initialLocation);
    }
    unawaited(_bindCurrentTripStream(generation));
    unawaited(refreshActiveTrip(generation: generation));
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (!_isActiveGeneration(generation)) return;
      unawaited(refreshActiveTrip(generation: generation));
    });
  }

  void updateLanguageCode(String value) {
    if (_disposed) return;
    final normalized = value.trim().toLowerCase();
    if (_languageCode == normalized) return;
    _languageCode = normalized;
    _recomputeGuidance();
  }

  void updateCurrentLocation(LocationData? location) {
    if (_disposed || location == null) return;
    final current = _state.currentLocation;
    if (current != null &&
        current.timestamp == location.timestamp &&
        current.latitude == location.latitude &&
        current.longitude == location.longitude) {
      return;
    }
    _state = _state.copyWith(
      currentLocation: location,
      clearErrorMessage: true,
    );
    _recomputeGuidance(notify: true);
    final guidance = _state.guidance;
    final now = DateTime.now();
    final canRefreshForArrival =
        guidance?.severity == ChildSafeRouteSeverity.arrived &&
        !_state.isLoading &&
        (_lastArrivalRefreshAt == null ||
            now.difference(_lastArrivalRefreshAt!) >= _arrivalRefreshCooldown);
    if (canRefreshForArrival) {
      _lastArrivalRefreshAt = now;
      unawaited(refreshActiveTrip());
    }
  }

  Future<void> refreshActiveTrip({int? generation}) async {
    if (!_isActiveGeneration(generation)) return;
    _setState(_state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final trip = await _getActiveTripByChildIdUseCase(childId);
      if (!_isActiveGeneration(generation)) return;
      await _applyCanonicalTrip(
        trip,
        generation: generation,
        isLoading: false,
      );
    } catch (error) {
      if (!_isActiveGeneration(generation)) return;
      _setState(
        _state.copyWith(isLoading: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> _bindCurrentTripStream(int generation) async {
    await _tripSub?.cancel();
    if (!_isActiveGeneration(generation)) return;
    _tripSub = _watchCurrentTripByChildIdUseCase(
      childId,
      audience: TripVisibilityAudience.childMonitor,
    ).listen(
      (trip) async {
        if (!_isActiveGeneration(generation)) return;
        await _applyCanonicalTrip(
          trip,
          generation: generation,
          isLoading: false,
        );
      },
      onError: (error) {
        if (!_isActiveGeneration(generation)) return;
        _setState(
          _state.copyWith(isLoading: false, errorMessage: error.toString()),
        );
      },
    );
  }

  void _recomputeGuidance({bool notify = false}) {
    if (_disposed) return;
    final trip = _state.activeTrip;
    final route = _resolveGuidanceRoute();
    final location = _state.currentLocation;

    if (trip == null || route == null || location == null) {
      _state = _state.copyWith(clearGuidance: true);
      if (notify) {
        _notifySafely();
      }
      return;
    }

    final guidance = buildChildSafeRouteGuidance(
      route: route,
      trip: trip,
      location: location,
      languageCode: _languageCode,
    );

    _state = _state.copyWith(guidance: guidance, clearErrorMessage: true);
    if (notify) {
      _notifySafely();
    }
  }

  void _setState(ChildSafeRouteState next) {
    if (_disposed) return;
    _state = next;
    _notifySafely();
  }

  SafeRoute? _resolveGuidanceRoute() {
    final trip = _state.activeTrip;
    final primaryRoute = _state.activeRoute;
    if (trip == null || primaryRoute == null) {
      return primaryRoute;
    }

    final routes = [primaryRoute, ..._state.alternativeRoutes];
    final currentRouteId = trip.currentRouteId;
    if (currentRouteId == null) {
      return primaryRoute;
    }

    for (final route in routes) {
      if (route.id == currentRouteId) {
        return route;
      }
    }

    return primaryRoute;
  }

  Future<_ChildResolvedRouteGroup> _loadRouteGroupForTrip(
    Trip trip, {
    int? generation,
  }) async {
    final primaryRoute = await _getRouteByIdUseCase(trip.routeId);
    if (!_isActiveGeneration(generation)) {
      return const _ChildResolvedRouteGroup(
        primaryRoute: null,
        alternativeRoutes: [],
      );
    }
    if (primaryRoute == null) {
      return const _ChildResolvedRouteGroup(
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
    if (!_isActiveGeneration(generation)) {
      return const _ChildResolvedRouteGroup(
        primaryRoute: null,
        alternativeRoutes: [],
      );
    }

    final currentRouteId = trip.currentRouteId;
    if (currentRouteId == null || currentRouteId == primaryRoute.id) {
      return _ChildResolvedRouteGroup(
        primaryRoute: primaryRoute,
        alternativeRoutes: alternativeRoutes,
      );
    }

    SafeRoute? matchedRoute;
    for (final route in alternativeRoutes) {
      if (route.id == currentRouteId) {
        matchedRoute = route;
        break;
      }
    }

    if (matchedRoute == null) {
      return _ChildResolvedRouteGroup(
        primaryRoute: primaryRoute,
        alternativeRoutes: alternativeRoutes,
      );
    }

    return _ChildResolvedRouteGroup(
      primaryRoute: matchedRoute,
      alternativeRoutes: [
        primaryRoute,
        ...alternativeRoutes.where((route) => route.id != matchedRoute?.id),
      ],
    );
  }

  Future<void> _applyCanonicalTrip(
    Trip? trip, {
    required int? generation,
    required bool isLoading,
  }) async {
    if (!_isActiveGeneration(generation)) return;

    SafeRoute? route;
    List<SafeRoute> alternativeRoutes = const [];
    if (trip != null) {
      final routeGroup = await _loadRouteGroupForTrip(
        trip,
        generation: generation,
      );
      if (!_isActiveGeneration(generation)) return;
      route = routeGroup.primaryRoute;
      alternativeRoutes = routeGroup.alternativeRoutes;
    }

    _state = _state.copyWith(
      isLoading: isLoading,
      activeTrip: trip,
      activeRoute: route,
      alternativeRoutes: alternativeRoutes,
      lastSyncedAt: DateTime.now(),
      clearActiveTrip: trip == null,
      clearActiveRoute: route == null,
      clearGuidance: trip == null || route == null,
      clearErrorMessage: true,
    );
    _recomputeGuidance(notify: true);
  }

  @override
  void dispose() {
    _disposed = true;
    _lifecycleGeneration++;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _tripSub?.cancel();
    _tripSub = null;
    super.dispose();
  }

  bool _isActiveGeneration(int? generation) {
    if (_disposed) return false;
    if (generation == null) return true;
    return generation == _lifecycleGeneration;
  }

  void _notifySafely() {
    if (_disposed) return;
    notifyListeners();
  }
}

class _ChildResolvedRouteGroup {
  const _ChildResolvedRouteGroup({
    required this.primaryRoute,
    required this.alternativeRoutes,
  });

  final SafeRoute? primaryRoute;
  final List<SafeRoute> alternativeRoutes;
}
