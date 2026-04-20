import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

abstract class SafeRouteRepository {
  Future<List<SafeRoute>> getSuggestedRoutes(
    RoutePoint start,
    RoutePoint end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  });
  Future<Trip> startTrip(Trip trip);
  Stream<LiveLocation> streamLiveLocation(String childId);
  Stream<Trip?> watchCurrentTripByChildId(
    String childId, {
    required TripVisibilityAudience audience,
  });
  Future<void> updateTripStatus(
    String tripId,
    TripStatus status, {
    String? reason,
  });
  Future<Trip?> getActiveTripByChildId(String childId);
  Future<List<Trip>> getTripHistoryByChildId(String childId);
  Future<SafeRoute?> getRouteById(String routeId);
}
