import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/async/polling_backoff.dart';
import 'package:kid_manager/features/safe_route/data/models/current_trip_snapshot_model.dart';
import 'package:kid_manager/features/safe_route/data/models/live_location_model.dart';
import 'package:kid_manager/features/safe_route/data/models/route_point_model.dart';
import 'package:kid_manager/features/safe_route/data/models/safe_route_model.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model_decoder.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/services/location/canonical_live_location_stream.dart';

abstract class SafeRouteRemoteDataSource {
  Future<List<SafeRouteModel>> getSuggestedRoutes(
    RoutePointModel start,
    RoutePointModel end, {
    String? childId,
    required SafeRouteTravelMode travelMode,
  });

  Future<TripModel> startTrip(TripModel trip);

  Stream<LiveLocationModel> streamLiveLocation(String childId);

  Stream<TripModel?> watchCurrentTripByChildId(
    String childId, {
    required TripVisibilityAudience audience,
  });

  Future<void> updateTripStatus(String tripId, String status, {String? reason});

  Future<TripModel?> getActiveTripByChildId(String childId);

  Future<List<TripModel>> getTripHistoryByChildId(String childId);

  Future<SafeRouteModel?> getRouteById(String routeId);
}

class FirebaseSafeRouteRemoteDataSource implements SafeRouteRemoteDataSource {
  FirebaseSafeRouteRemoteDataSource({
    FirebaseFunctions? functions,
    FirebaseDatabase? database,
    FirebaseFirestore? firestore,
  }) : _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
       _database = database ?? FirebaseDatabase.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseDatabase _database;
  final FirebaseFirestore _firestore;
  static const Duration _liveLocationPollingInterval = Duration(seconds: 2);
  static const Duration _currentTripFallbackPollingInterval = Duration(seconds: 4);
  static const Duration _currentTripFallbackMaxPollingInterval = Duration(
    seconds: 30,
  );
  static const Duration _currentTripFallbackRealtimeRetryInterval = Duration(
    minutes: 1,
  );

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
      'previewRoute': trip.previewRoute == null
          ? null
          : SafeRouteModel.fromEntity(trip.previewRoute!).toMap(),
      'previewAlternativeRoutes': trip.previewAlternativeRoutes
          .map((route) => SafeRouteModel.fromEntity(route).toMap())
          .toList(growable: false),
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return TripModel.fromMap(Map<String, dynamic>.from(data['trip'] as Map));
  }

  @override
  Stream<LiveLocationModel> streamLiveLocation(String childId) {
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

    return streamCanonicalLiveLocation<LiveLocationModel>(
      reference: _database.ref('live_locations/$childId'),
      pollCanonicalSnapshot: () async {
        final callable = _functions.httpsCallable('getChildLocationCurrent');
        final response = await callable.call({'childUid': childId});
        final data = Map<String, dynamic>.from(response.data as Map);
        return data['current'];
      },
      parseSnapshot: parseValue,
      pollingInterval: _liveLocationPollingInterval,
    );
  }

  @override
  Stream<TripModel?> watchCurrentTripByChildId(
    String childId, {
    required TripVisibilityAudience audience,
  }) {
    final docRef = _firestore
        .collection('safe_route_current_trips')
        .doc(childId);

    late final StreamController<TripModel?> controller;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? subscription;
    Timer? expiryTimer;
    Timer? fallbackPollTimer;
    Timer? realtimeRetryTimer;
    CurrentTripSnapshotModel? latestSnapshot;
    bool usingCallableFallback = false;
    final fallbackBackoff = PollingBackoff(
      initialDelay: _currentTripFallbackPollingInterval,
      maxDelay: _currentTripFallbackMaxPollingInterval,
    );

    late void Function() emitCurrent;
    late void Function() attachSnapshotListener;
    late Future<void> Function() pollCurrentTripFromCallable;
    late void Function() scheduleFallbackPoll;

    bool shouldFallbackToCallable(Object error) {
      return error is FirebaseException &&
          (error.code == 'permission-denied' || error.code == 'unavailable');
    }

    void cancelFallbackTimers() {
      fallbackPollTimer?.cancel();
      fallbackPollTimer = null;
      realtimeRetryTimer?.cancel();
      realtimeRetryTimer = null;
    }

    void scheduleRealtimeRetry() {
      if (!usingCallableFallback ||
          controller.isClosed ||
          realtimeRetryTimer != null ||
          subscription != null) {
        return;
      }

      realtimeRetryTimer = Timer(
        _currentTripFallbackRealtimeRetryInterval,
        () {
          realtimeRetryTimer = null;
          if (!controller.isClosed && usingCallableFallback && subscription == null) {
            debugPrint(
              '[SafeRoute] retry realtime snapshot for '
              'safe_route_current_trips/$childId',
            );
            attachSnapshotListener();
          }
        },
      );
    }

    scheduleFallbackPoll = () {
      fallbackPollTimer?.cancel();
      if (!usingCallableFallback || controller.isClosed) {
        return;
      }

      final delay = fallbackBackoff.nextDelay();
      debugPrint(
        '[SafeRoute] fallback polling current trip child=$childId '
        'attempt=${fallbackBackoff.attemptCount} nextInMs=${delay.inMilliseconds}',
      );
      fallbackPollTimer = Timer(delay, () {
        if (!controller.isClosed && usingCallableFallback) {
          unawaited(pollCurrentTripFromCallable());
        }
      });
    };

    pollCurrentTripFromCallable = () async {
      if (controller.isClosed) {
        return;
      }

      try {
        final trip = await getActiveTripByChildId(childId);
        if (!controller.isClosed) {
          controller.add(trip);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      } finally {
        if (!controller.isClosed && usingCallableFallback) {
          scheduleFallbackPoll();
          scheduleRealtimeRetry();
        }
      }
    };

    void startCallableFallback(Object error) {
      if (usingCallableFallback || controller.isClosed) {
        return;
      }
      usingCallableFallback = true;
      expiryTimer?.cancel();
      expiryTimer = null;
      fallbackBackoff.reset();
      debugPrint(
        '[SafeRoute] fallback to getActiveSafeRouteTripByChildId for '
        'safe_route_current_trips/$childId because snapshot listen failed: '
        '$error',
      );
      unawaited(subscription?.cancel());
      subscription = null;
      cancelFallbackTimers();
      unawaited(pollCurrentTripFromCallable());
    }

    void scheduleExpiryIfNeeded() {
      expiryTimer?.cancel();
      expiryTimer = null;

      if (usingCallableFallback ||
          audience != TripVisibilityAudience.adultManager) {
        return;
      }

      final trip = latestSnapshot?.adultRecentCompletedTrip;
      final visibleUntil = latestSnapshot?.adultCurrentTripVisibleUntil;
      if (trip == null ||
          trip.status != TripStatus.completed ||
          visibleUntil == null) {
        return;
      }

      final remaining = visibleUntil.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        return;
      }

      expiryTimer = Timer(remaining, () {
        if (!controller.isClosed) {
          emitCurrent();
        }
      });
    }

    emitCurrent = () {
      if (controller.isClosed) {
        return;
      }
      controller.add(
        latestSnapshot?.tripForAudience(audience, now: DateTime.now()),
      );
      scheduleExpiryIfNeeded();
    };

    controller = StreamController<TripModel?>(
      onListen: () {
        attachSnapshotListener = () {
          subscription ??= docRef.snapshots().listen(
          (snapshot) {
            if (!snapshot.exists) {
              latestSnapshot = null;
              emitCurrent();
              return;
            }

            final data = snapshot.data();
            if (data == null) {
              latestSnapshot = null;
              emitCurrent();
              return;
            }

            try {
              latestSnapshot = CurrentTripSnapshotModel.fromMap(data);
            } catch (error, stackTrace) {
              latestSnapshot = null;
              debugPrint(
                '[SafeRoute] skip invalid safe_route_current_trips/$childId '
                'snapshot: $error\n$stackTrace',
              );
              emitCurrent();
              return;
            }

            if (usingCallableFallback) {
              usingCallableFallback = false;
              fallbackBackoff.reset();
              cancelFallbackTimers();
              debugPrint(
                '[SafeRoute] restored realtime snapshot for '
                'safe_route_current_trips/$childId',
              );
            }
            emitCurrent();
          },
          onError: (error, stackTrace) {
            if (shouldFallbackToCallable(error)) {
              startCallableFallback(error);
              return;
            }
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
            }
          },
        );
        };
        attachSnapshotListener();
      },
      onCancel: () async {
        expiryTimer?.cancel();
        expiryTimer = null;
        cancelFallbackTimers();
        await subscription?.cancel();
        subscription = null;
      },
    );

    return controller.stream;
  }

  @override
  Future<void> updateTripStatus(
    String tripId,
    String status, {
    String? reason,
  }) async {
    final callable = _functions.httpsCallable('updateSafeRouteTripStatus');
    await callable.call({'tripId': tripId, 'status': status, 'reason': reason});
  }

  @override
  Future<TripModel?> getActiveTripByChildId(String childId) async {
    final callable = _functions.httpsCallable(
      'getActiveSafeRouteTripByChildId',
    );
    final response = await callable.call({'childId': childId});
    final data = Map<String, dynamic>.from(response.data as Map);
    final trip = data['trip'];
    if (trip is! Map) return null;
    return tryParseTripModel(
      Map<String, dynamic>.from(trip),
      source: 'getActiveSafeRouteTripByChildId',
    );
  }

  @override
  Future<List<TripModel>> getTripHistoryByChildId(String childId) async {
    final callable = _functions.httpsCallable(
      'getSafeRouteTripHistoryByChildId',
    );
    final response = await callable.call({'childId': childId});
    final data = Map<String, dynamic>.from(response.data as Map);
    final rawTrips = (data['trips'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => tryParseTripModel(
            Map<String, dynamic>.from(item),
            source: 'getSafeRouteTripHistoryByChildId',
          ),
        )
        .whereType<TripModel>()
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
