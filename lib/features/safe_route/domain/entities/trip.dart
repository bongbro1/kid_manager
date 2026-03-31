import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

class Trip {
  final String id;
  final String childId;
  final String parentId;
  final String routeId;
  final List<String> alternativeRouteIds;
  final String? currentRouteId;
  final String? routeName;
  final TripStatus status;
  final String? reason;
  final int consecutiveDeviationCount;
  final double currentDistanceFromRouteMeters;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? scheduledStartAt;
  final List<int> repeatWeekdays;
  final LiveLocation? lastLocation;
  final SafeRoute? previewRoute;
  final List<SafeRoute> previewAlternativeRoutes;

  const Trip({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.routeId,
    required this.alternativeRouteIds,
    required this.currentRouteId,
    required this.routeName,
    required this.status,
    required this.reason,
    required this.consecutiveDeviationCount,
    required this.currentDistanceFromRouteMeters,
    required this.startedAt,
    required this.updatedAt,
    required this.scheduledStartAt,
    required this.repeatWeekdays,
    required this.lastLocation,
    this.previewRoute,
    this.previewAlternativeRoutes = const [],
  });

  Trip copyWith({
    String? id,
    String? childId,
    String? parentId,
    String? routeId,
    List<String>? alternativeRouteIds,
    String? currentRouteId,
    String? routeName,
    TripStatus? status,
    String? reason,
    int? consecutiveDeviationCount,
    double? currentDistanceFromRouteMeters,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? scheduledStartAt,
    List<int>? repeatWeekdays,
    LiveLocation? lastLocation,
    SafeRoute? previewRoute,
    List<SafeRoute>? previewAlternativeRoutes,
  }) {
    return Trip(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      routeId: routeId ?? this.routeId,
      alternativeRouteIds: alternativeRouteIds ?? this.alternativeRouteIds,
      currentRouteId: currentRouteId ?? this.currentRouteId,
      routeName: routeName ?? this.routeName,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      consecutiveDeviationCount:
          consecutiveDeviationCount ?? this.consecutiveDeviationCount,
      currentDistanceFromRouteMeters:
          currentDistanceFromRouteMeters ?? this.currentDistanceFromRouteMeters,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      lastLocation: lastLocation ?? this.lastLocation,
      previewRoute: previewRoute ?? this.previewRoute,
      previewAlternativeRoutes:
          previewAlternativeRoutes ?? this.previewAlternativeRoutes,
    );
  }
}
