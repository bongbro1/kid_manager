import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

class SafeRouteHistoryState {
  static const Object _unset = Object();

  const SafeRouteHistoryState({
    required this.childId,
    required this.isLoading,
    required this.isLoadingRoute,
    required this.trips,
    required this.selectedTrip,
    required this.selectedRoute,
    required this.selectedAlternativeRoutes,
    required this.errorMessage,
  });

  final String childId;
  final bool isLoading;
  final bool isLoadingRoute;
  final List<Trip> trips;
  final Trip? selectedTrip;
  final SafeRoute? selectedRoute;
  final List<SafeRoute> selectedAlternativeRoutes;
  final String? errorMessage;

  factory SafeRouteHistoryState.initial(String childId) {
    return SafeRouteHistoryState(
      childId: childId,
      isLoading: false,
      isLoadingRoute: false,
      trips: const [],
      selectedTrip: null,
      selectedRoute: null,
      selectedAlternativeRoutes: const [],
      errorMessage: null,
    );
  }

  SafeRouteHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingRoute,
    List<Trip>? trips,
    Object? selectedTrip = _unset,
    Object? selectedRoute = _unset,
    List<SafeRoute>? selectedAlternativeRoutes,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SafeRouteHistoryState(
      childId: childId,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRoute: isLoadingRoute ?? this.isLoadingRoute,
      trips: trips ?? this.trips,
      selectedTrip: identical(selectedTrip, _unset)
          ? this.selectedTrip
          : selectedTrip as Trip?,
      selectedRoute: identical(selectedRoute, _unset)
          ? this.selectedRoute
          : selectedRoute as SafeRoute?,
      selectedAlternativeRoutes:
          selectedAlternativeRoutes ?? this.selectedAlternativeRoutes,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
