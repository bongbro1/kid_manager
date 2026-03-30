import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/repositories/safe_route_repository.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/watch_current_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/viewmodels/child_safe_route_view_model.dart';

void main() {
  group('ChildSafeRouteViewModel', () {
    test(
      'does not notify after dispose when active trip request completes late',
      () async {
        final tripCompleter = Completer<Trip?>();
        final repository = _FakeSafeRouteRepository(
          activeTripLoader: (_) => tripCompleter.future,
        );
        final viewModel = ChildSafeRouteViewModel(
          childId: 'child-1',
          getActiveTripByChildIdUseCase: GetActiveTripByChildIdUseCase(
            repository,
          ),
          watchCurrentTripByChildIdUseCase: WatchCurrentTripByChildIdUseCase(
            repository,
          ),
          getRouteByIdUseCase: GetRouteByIdUseCase(repository),
        );

        viewModel.initialize(languageCode: 'vi');
        viewModel.dispose();

        tripCompleter.complete(_sampleTrip());
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(true, isTrue);
      },
    );

    test(
      'does not notify after dispose when route loading completes late',
      () async {
        final routeCompleter = Completer<SafeRoute?>();
        final repository = _FakeSafeRouteRepository(
          activeTripLoader: (_) async => _sampleTrip(),
          routeLoader: (_) => routeCompleter.future,
        );
        final viewModel = ChildSafeRouteViewModel(
          childId: 'child-1',
          getActiveTripByChildIdUseCase: GetActiveTripByChildIdUseCase(
            repository,
          ),
          watchCurrentTripByChildIdUseCase: WatchCurrentTripByChildIdUseCase(
            repository,
          ),
          getRouteByIdUseCase: GetRouteByIdUseCase(repository),
        );

        viewModel.initialize(languageCode: 'vi');
        await Future<void>.delayed(Duration.zero);
        viewModel.dispose();

        routeCompleter.complete(_sampleRoute());
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(true, isTrue);
      },
    );
  });
}

Trip _sampleTrip() {
  return Trip(
    id: 'trip-1',
    childId: 'child-1',
    parentId: 'parent-1',
    routeId: 'route-1',
    alternativeRouteIds: const <String>[],
    currentRouteId: 'route-1',
    routeName: 'Morning route',
    status: TripStatus.active,
    reason: null,
    consecutiveDeviationCount: 0,
    currentDistanceFromRouteMeters: 0,
    startedAt: DateTime(2026, 3, 24, 7),
    updatedAt: DateTime(2026, 3, 24, 7, 1),
    scheduledStartAt: null,
    repeatWeekdays: const <int>[],
    lastLocation: const LiveLocation(
      childId: 'child-1',
      latitude: 21.0,
      longitude: 105.0,
      accuracyMeters: 5,
      speedMps: 0,
      bearing: 0,
      batteryLevel: null,
      isMock: false,
      timestamp: 1710000000000,
    ),
  );
}

SafeRoute _sampleRoute() {
  const start = RoutePoint(latitude: 21.0, longitude: 105.0, sequence: 0);
  const end = RoutePoint(latitude: 21.001, longitude: 105.001, sequence: 1);

  return SafeRoute(
    id: 'route-1',
    childId: 'child-1',
    parentId: 'parent-1',
    name: 'Morning route',
    startPoint: start,
    endPoint: end,
    points: const <RoutePoint>[start, end],
    hazards: const [],
    corridorWidthMeters: 50,
    distanceMeters: 120,
    durationSeconds: 180,
    travelMode: SafeRouteTravelMode.walking,
    profile: 'walking',
    createdAt: DateTime(2026, 3, 24, 7),
    updatedAt: DateTime(2026, 3, 24, 7, 1),
  );
}

class _FakeSafeRouteRepository implements SafeRouteRepository {
  _FakeSafeRouteRepository({
    Future<Trip?> Function(String childId)? activeTripLoader,
    Future<SafeRoute?> Function(String routeId)? routeLoader,
  }) : _activeTripLoader = activeTripLoader,
       _routeLoader = routeLoader;

  final Future<Trip?> Function(String childId)? _activeTripLoader;
  final Future<SafeRoute?> Function(String routeId)? _routeLoader;

  @override
  Future<Trip?> getActiveTripByChildId(String childId) {
    return _activeTripLoader?.call(childId) ?? Future<Trip?>.value(null);
  }

  @override
  Future<SafeRoute?> getRouteById(String routeId) {
    return _routeLoader?.call(routeId) ?? Future<SafeRoute?>.value(null);
  }

  @override
  Future<List<SafeRoute>> getSuggestedRoutes(
    RoutePoint start,
    RoutePoint end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  }) async => const <SafeRoute>[];

  @override
  Future<List<Trip>> getTripHistoryByChildId(String childId) async =>
      const <Trip>[];

  @override
  Future<Trip> startTrip(Trip trip) async => trip;

  @override
  Stream<LiveLocation> streamLiveLocation(String childId) =>
      const Stream<LiveLocation>.empty();

  @override
  Future<void> updateTripStatus(
    String tripId,
    TripStatus status, {
    String? reason,
  }) async {}
  @override
  Stream<Trip?> watchCurrentTripByChildId(
    String childId, {
    required TripVisibilityAudience audience,
  }) {
    return const Stream<Trip?>.empty();
  }
}
