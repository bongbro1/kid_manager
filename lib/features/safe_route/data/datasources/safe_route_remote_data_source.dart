import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kid_manager/features/safe_route/data/models/live_location_model.dart';
import 'package:kid_manager/features/safe_route/data/models/route_point_model.dart';
import 'package:kid_manager/features/safe_route/data/models/safe_route_model.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

abstract class SafeRouteRemoteDataSource {
  Future<List<SafeRouteModel>> getSuggestedRoutes(
    RoutePointModel start,
    RoutePointModel end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  });

  Future<TripModel> startTrip(TripModel trip);

  Stream<LiveLocationModel> streamLiveLocation(String childId);

  Future<void> updateTripStatus(String tripId, String status, {String? reason});

  Future<TripModel?> getActiveTripByChildId(String childId);

  Future<List<TripModel>> getTripHistoryByChildId(String childId);

  Future<SafeRouteModel?> getRouteById(String routeId);
}

class FirebaseSafeRouteRemoteDataSource implements SafeRouteRemoteDataSource {
  FirebaseSafeRouteRemoteDataSource({
    FirebaseFunctions? functions,
    FirebaseDatabase? database,
  })  : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
        _database = database ?? FirebaseDatabase.instance;

  final FirebaseFunctions _functions;
  final FirebaseDatabase _database;
  static const Duration _liveLocationPollingInterval = Duration(seconds: 2);

  @override
  Future<List<SafeRouteModel>> getSuggestedRoutes(
    RoutePointModel start,
    RoutePointModel end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  }) async {
    final callable = _functions.httpsCallable('getSuggestedSafeRoutes');
    final response = await callable.call({
      'childId': childId,
      'start': start.toMap(),
      'end': end.toMap(),
      'travelMode': travelMode.name,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    final rawRoutes = (data['routes'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => SafeRouteModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return rawRoutes;
  }

  @override
  Future<TripModel> startTrip(TripModel trip) async {
    final callable = _functions.httpsCallable('startSafeRouteTrip');
    final response = await callable.call({
      'routeId': trip.routeId,
      'alternativeRouteIds': trip.alternativeRouteIds,
      'scheduledStartAt': trip.scheduledStartAt?.millisecondsSinceEpoch,
      'repeatWeekdays': trip.repeatWeekdays,
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return TripModel.fromMap(Map<String, dynamic>.from(data['trip'] as Map));
  }

  @override
  Stream<LiveLocationModel> streamLiveLocation(String childId) {
    final controller = StreamController<LiveLocationModel>();
    StreamSubscription<DatabaseEvent>? rtdbSub;
    Timer? pollTimer;
    var fallbackStarted = false;
    var lastTimestamp = 0;

    LiveLocationModel? parseValue(dynamic value) {
      if (value is! Map) return null;
      final location = LiveLocationModel.fromMap(
        childId,
        Map<dynamic, dynamic>.from(value),
      );
      if (location.timestamp <= 0 || location.timestamp == lastTimestamp) {
        return null;
      }
      lastTimestamp = location.timestamp;
      return location;
    }

    Future<void> pollOnce() async {
      try {
        final callable = _functions.httpsCallable('getChildLocationCurrent');
        final response = await callable.call({'childUid': childId});
        final data = Map<String, dynamic>.from(response.data as Map);
        final location = parseValue(data['current']);
        if (location != null && !controller.isClosed) {
          controller.add(location);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    void startFallbackPolling() {
      if (fallbackStarted) return;
      fallbackStarted = true;
      pollTimer?.cancel();
      unawaited(pollOnce());
      pollTimer = Timer.periodic(_liveLocationPollingInterval, (_) {
        unawaited(pollOnce());
      });
    }

    rtdbSub = _database.ref('live_locations/$childId').onValue.listen(
      (event) {
        final location = parseValue(event.snapshot.value);
        if (location != null && !controller.isClosed) {
          if (fallbackStarted) {
            pollTimer?.cancel();
            fallbackStarted = false;
          }
          controller.add(location);
          return;
        }

        if (event.snapshot.value == null) {
          startFallbackPolling();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        unawaited(rtdbSub?.cancel());
        rtdbSub = null;
        startFallbackPolling();
      },
      cancelOnError: false,
    );

    controller.onCancel = () async {
      pollTimer?.cancel();
      await rtdbSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> updateTripStatus(String tripId, String status, {String? reason}) async {
    final callable = _functions.httpsCallable('updateSafeRouteTripStatus');
    await callable.call({
      'tripId': tripId,
      'status': status,
      'reason': reason,
    });
  }

  @override
  Future<TripModel?> getActiveTripByChildId(String childId) async {
    final callable = _functions.httpsCallable('getActiveSafeRouteTripByChildId');
    final response = await callable.call({'childId': childId});
    final data = Map<String, dynamic>.from(response.data as Map);
    final trip = data['trip'];
    if (trip is! Map) return null;
    return TripModel.fromMap(Map<String, dynamic>.from(trip));
  }

  @override
  Future<List<TripModel>> getTripHistoryByChildId(String childId) async {
    final callable = _functions.httpsCallable('getSafeRouteTripHistoryByChildId');
    final response = await callable.call({'childId': childId});
    final data = Map<String, dynamic>.from(response.data as Map);
    final rawTrips = (data['trips'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => TripModel.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return rawTrips;
  }

  @override
  Future<SafeRouteModel?> getRouteById(String routeId) async {
    final callable = _functions.httpsCallable('getSafeRouteById');
    final response = await callable.call({'routeId': routeId});
    final data = Map<String, dynamic>.from(response.data as Map);
    final route = data['route'];
    if (route is! Map) return null;
    return SafeRouteModel.fromMap(Map<String, dynamic>.from(route));
  }
}
