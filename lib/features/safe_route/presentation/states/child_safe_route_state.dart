import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/presentation/child_safe_route_guidance.dart';
import 'package:kid_manager/models/location/location_data.dart';

class ChildSafeRouteState {
  const ChildSafeRouteState({
    required this.childId,
    required this.isLoading,
    required this.activeTrip,
    required this.activeRoute,
    required this.alternativeRoutes,
    required this.currentLocation,
    required this.guidance,
    required this.errorMessage,
    required this.lastSyncedAt,
  });

  factory ChildSafeRouteState.initial(String childId) {
    return ChildSafeRouteState(
      childId: childId,
      isLoading: false,
      activeTrip: null,
      activeRoute: null,
      alternativeRoutes: const [],
      currentLocation: null,
      guidance: null,
      errorMessage: null,
      lastSyncedAt: null,
    );
  }

  final String childId;
  final bool isLoading;
  final Trip? activeTrip;
  final SafeRoute? activeRoute;
  final List<SafeRoute> alternativeRoutes;
  final LocationData? currentLocation;
  final ChildSafeRouteGuidance? guidance;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  bool get hasActiveRoute => activeRoute != null && activeTrip != null;

  ChildSafeRouteState copyWith({
    bool? isLoading,
    Trip? activeTrip,
    SafeRoute? activeRoute,
    List<SafeRoute>? alternativeRoutes,
    LocationData? currentLocation,
    ChildSafeRouteGuidance? guidance,
    String? errorMessage,
    DateTime? lastSyncedAt,
    bool clearActiveTrip = false,
    bool clearActiveRoute = false,
    bool clearGuidance = false,
    bool clearErrorMessage = false,
  }) {
    return ChildSafeRouteState(
      childId: childId,
      isLoading: isLoading ?? this.isLoading,
      activeTrip: clearActiveTrip ? null : activeTrip ?? this.activeTrip,
      activeRoute: clearActiveRoute ? null : activeRoute ?? this.activeRoute,
      alternativeRoutes:
          clearActiveRoute ? const [] : alternativeRoutes ?? this.alternativeRoutes,
      currentLocation: currentLocation ?? this.currentLocation,
      guidance: clearGuidance ? null : guidance ?? this.guidance,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
