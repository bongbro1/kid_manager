import 'package:flutter/foundation.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_trip_history_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_history_state.dart';

class SafeRouteHistoryViewModel extends ChangeNotifier {
  SafeRouteHistoryViewModel({
    required this.childId,
    required GetTripHistoryByChildIdUseCase getTripHistoryByChildIdUseCase,
    required GetRouteByIdUseCase getRouteByIdUseCase,
  }) : _getTripHistoryByChildIdUseCase = getTripHistoryByChildIdUseCase,
       _getRouteByIdUseCase = getRouteByIdUseCase,
       _state = SafeRouteHistoryState.initial(childId);

  final String childId;
  final GetTripHistoryByChildIdUseCase _getTripHistoryByChildIdUseCase;
  final GetRouteByIdUseCase _getRouteByIdUseCase;

  SafeRouteHistoryState _state;
  SafeRouteHistoryState get state => _state;

  Future<void> initialize() async {
    _setState(
      _state.copyWith(
        isLoading: true,
        isLoadingRoute: false,
        selectedTrip: null,
        selectedRoute: null,
        selectedAlternativeRoutes: const [],
        clearErrorMessage: true,
      ),
    );
    try {
      final trips = (await _getTripHistoryByChildIdUseCase(childId))
          .where((trip) => trip.status != TripStatus.planned)
          .toList(growable: false);
      _setState(
        _state.copyWith(
          isLoading: false,
          trips: trips,
          selectedTrip: trips.isEmpty ? null : _state.selectedTrip,
          selectedRoute: trips.isEmpty ? null : _state.selectedRoute,
          selectedAlternativeRoutes: trips.isEmpty
              ? const []
              : _state.selectedAlternativeRoutes,
          clearErrorMessage: true,
        ),
      );

      if (trips.isNotEmpty) {
        await selectTrip(trips.first, notifyLoading: false);
      }
    } catch (error) {
      _setState(
        _state.copyWith(isLoading: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> selectTrip(Trip trip, {bool notifyLoading = true}) async {
    if (notifyLoading) {
      _setState(
        _state.copyWith(
          selectedTrip: trip,
          isLoadingRoute: true,
          clearErrorMessage: true,
        ),
      );
    } else {
      _state = _state.copyWith(
        selectedTrip: trip,
        isLoadingRoute: true,
        clearErrorMessage: true,
      );
      notifyListeners();
    }

    try {
      final routeGroup = await _loadRouteGroupForTrip(trip);
      _setState(
        _state.copyWith(
          isLoadingRoute: false,
          selectedTrip: trip,
          selectedRoute: routeGroup.primaryRoute,
          selectedAlternativeRoutes: routeGroup.alternativeRoutes,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      _setState(
        _state.copyWith(isLoadingRoute: false, errorMessage: error.toString()),
      );
    }
  }

  void clearError() {
    if (_state.errorMessage == null) return;
    _setState(_state.copyWith(clearErrorMessage: true));
  }

  void _setState(SafeRouteHistoryState next) {
    _state = next;
    notifyListeners();
  }

  Future<_ResolvedHistoryRouteGroup> _loadRouteGroupForTrip(Trip trip) async {
    final primaryRoute = await _getRouteByIdUseCase(trip.routeId);
    if (primaryRoute == null) {
      return const _ResolvedHistoryRouteGroup(
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
      return _ResolvedHistoryRouteGroup(
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
      return _ResolvedHistoryRouteGroup(
        primaryRoute: primaryRoute,
        alternativeRoutes: alternativeRoutes,
      );
    }

    return _ResolvedHistoryRouteGroup(
      primaryRoute: matchedAlternative,
      alternativeRoutes: [
        primaryRoute,
        ...alternativeRoutes.where(
          (route) => route.id != matchedAlternative?.id,
        ),
      ],
    );
  }
}

class _ResolvedHistoryRouteGroup {
  const _ResolvedHistoryRouteGroup({
    required this.primaryRoute,
    required this.alternativeRoutes,
  });

  final SafeRoute? primaryRoute;
  final List<SafeRoute> alternativeRoutes;
}
