import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/features/safe_route/presentation/states/child_safe_route_state.dart';
import 'package:kid_manager/models/location/location_data.dart';

class ChildSafeRouteViewModel extends ChangeNotifier {
  ChildSafeRouteViewModel({
    required this.childId,
    required GetActiveTripByChildIdUseCase getActiveTripByChildIdUseCase,
    required GetRouteByIdUseCase getRouteByIdUseCase,
  }) : _getActiveTripByChildIdUseCase = getActiveTripByChildIdUseCase,
       _getRouteByIdUseCase = getRouteByIdUseCase,
       _state = ChildSafeRouteState.initial(childId);

  final String childId;
  final GetActiveTripByChildIdUseCase _getActiveTripByChildIdUseCase;
  final GetRouteByIdUseCase _getRouteByIdUseCase;

  static const Duration _refreshInterval = Duration(seconds: 15);
  static const Duration _arrivalRefreshCooldown = Duration(seconds: 4);

  ChildSafeRouteState _state;
  ChildSafeRouteState get state => _state;

  Timer? _refreshTimer;
  String _languageCode = 'vi';
  DateTime? _lastArrivalRefreshAt;

  void initialize({
    required String languageCode,
    LocationData? initialLocation,
  }) {
    _languageCode = languageCode;
    if (initialLocation != null) {
      _state = _state.copyWith(currentLocation: initialLocation);
    }
    unawaited(refreshActiveTrip());
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      unawaited(refreshActiveTrip());
    });
  }

  void updateLanguageCode(String value) {
    final normalized = value.trim().toLowerCase();
    if (_languageCode == normalized) return;
    _languageCode = normalized;
    _recomputeGuidance();
  }

  void updateCurrentLocation(LocationData? location) {
    if (location == null) return;
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

  Future<void> refreshActiveTrip() async {
    _setState(_state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final trip = await _getActiveTripByChildIdUseCase(childId);
      SafeRoute? route;
      List<SafeRoute> alternativeRoutes = const [];
      if (trip != null) {
        final routeGroup = await _loadRouteGroupForTrip(trip);
        route = routeGroup.primaryRoute;
        alternativeRoutes = routeGroup.alternativeRoutes;
      }

      _state = _state.copyWith(
        isLoading: false,
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
    } catch (error) {
      _setState(
        _state.copyWith(isLoading: false, errorMessage: error.toString()),
      );
    }
  }

  void _recomputeGuidance({bool notify = false}) {
    final trip = _state.activeTrip;
    final route = _resolveGuidanceRoute();
    final location = _state.currentLocation;

    if (trip == null || route == null || location == null) {
      _state = _state.copyWith(clearGuidance: true);
      if (notify) {
        notifyListeners();
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
      notifyListeners();
    }
  }

  void _setState(ChildSafeRouteState next) {
    _state = next;
    notifyListeners();
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

  Future<_ChildResolvedRouteGroup> _loadRouteGroupForTrip(Trip trip) async {
    final primaryRoute = await _getRouteByIdUseCase(trip.routeId);
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
