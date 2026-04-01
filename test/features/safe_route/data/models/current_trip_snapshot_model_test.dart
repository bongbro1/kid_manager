import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/features/safe_route/data/models/current_trip_snapshot_model.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

void main() {
  Map<String, dynamic> buildTrip({
    required String id,
    required String status,
    required int startedAt,
    required int updatedAt,
  }) {
    return {
      'id': id,
      'childId': 'child-1',
      'parentId': 'parent-1',
      'routeId': 'route-1',
      'alternativeRouteIds': const <String>[],
      'status': status,
      'reason': null,
      'consecutiveDeviationCount': 0,
      'currentDistanceFromRouteMeters': 0,
      'startedAt': startedAt,
      'updatedAt': updatedAt,
      'repeatWeekdays': const <int>[],
      'lastLocation': null,
    };
  }

  test('adult completed trip expires from visibility window', () {
    final snapshot = CurrentTripSnapshotModel.fromMap({
      'childId': 'child-1',
      'adultCurrentTrip': buildTrip(
        id: 'trip-planned',
        status: 'planned',
        startedAt: 1000,
        updatedAt: 1500,
      ),
      'adultRecentCompletedTrip': buildTrip(
        id: 'trip-completed',
        status: 'completed',
        startedAt: 1000,
        updatedAt: 2000,
      ),
      'adultCurrentTripVisibleUntil': 5000,
      'childMonitorTrip': null,
    });

    expect(
      snapshot.tripForAudience(
        TripVisibilityAudience.adultManager,
        now: DateTime.fromMillisecondsSinceEpoch(4000),
      )?.id,
      'trip-completed',
    );
    expect(
      snapshot.tripForAudience(
        TripVisibilityAudience.adultManager,
        now: DateTime.fromMillisecondsSinceEpoch(5000),
      )?.id,
      'trip-planned',
    );
  });

  test('invalid nested trip payload is skipped safely', () {
    final snapshot = CurrentTripSnapshotModel.fromMap({
      'childId': 'child-1',
      'adultCurrentTrip': {
        'id': 'trip-invalid',
        'childId': 'child-1',
      },
      'childMonitorTrip': buildTrip(
        id: 'trip-active',
        status: 'active',
        startedAt: 1000,
        updatedAt: 2000,
      ),
    });

    expect(snapshot.adultCurrentTrip, isNull);
    expect(
      snapshot.tripForAudience(TripVisibilityAudience.childMonitor)?.id,
      'trip-active',
    );
  });
}
