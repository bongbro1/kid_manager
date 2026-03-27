import 'package:kid_manager/features/safe_route/data/datasources/safe_route_remote_data_source.dart';
import 'package:kid_manager/features/safe_route/data/models/route_point_model.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model.dart';
import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';

class SafeRouteRepositoryImpl implements SafeRouteRepository {
  final SafeRouteRemoteDataSource _remoteDataSource;

  const SafeRouteRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SafeRoute>> getSuggestedRoutes(
    RoutePoint start,
    RoutePoint end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  }) async {
    final routes = await _remoteDataSource.getSuggestedRoutes(
      RoutePointModel.fromEntity(start),
      RoutePointModel.fromEntity(end),
      childId: childId,
      travelMode: travelMode,
    );
    return routes.map((route) => route.toEntity()).toList(growable: false);
  }

  @override
  Future<Trip?> getActiveTripByChildId(String childId) async {
    return (await _remoteDataSource.getActiveTripByChildId(childId))?.toEntity();
  }

  @override
  Future<List<Trip>> getTripHistoryByChildId(String childId) async {
    final trips = await _remoteDataSource.getTripHistoryByChildId(childId);
    return trips.map((trip) => trip.toEntity()).toList(growable: false);
  }

  @override
  Future<SafeRoute?> getRouteById(String routeId) async {
    return (await _remoteDataSource.getRouteById(routeId))?.toEntity();
  }

  @override
  Future<Trip> startTrip(Trip trip) async {
    final created = await _remoteDataSource.startTrip(TripModel.fromEntity(trip));
    return created.toEntity();
  }

  @override
  Stream<Trip?> watchCurrentTripByChildId(
    String childId, {
    required TripVisibilityAudience audience,
  }) {
    return _remoteDataSource
        .watchCurrentTripByChildId(childId, audience: audience)
        .map((item) => item?.toEntity());
  }

  @override
  Stream<LiveLocation> streamLiveLocation(String childId) {
    return _remoteDataSource.streamLiveLocation(childId).map((item) => item.toEntity());
  }

  @override
  Future<void> updateTripStatus(String tripId, TripStatus status, {String? reason}) {
    return _remoteDataSource.updateTripStatus(tripId, status.name, reason: reason);
  }
}
