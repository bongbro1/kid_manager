import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/features/safe_route/data/helpers/current_trip_selector.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

void main() {
  group('selectCurrentTripForAudience', () {
    final now = DateTime.utc(2026, 3, 26, 12);

    Trip buildTrip({
      required String id,
      required TripStatus status,
      required DateTime updatedAt,
    }) {
      return Trip(
        id: id,
        childId: 'child-1',
        parentId: 'parent-1',
        routeId: 'route-1',
        alternativeRouteIds: const [],
        currentRouteId: 'route-1',
        routeName: 'Route 1',
        status: status,
        reason: null,
        consecutiveDeviationCount: 0,
        currentDistanceFromRouteMeters: 0,
        startedAt: updatedAt,
        updatedAt: updatedAt,
        scheduledStartAt: null,
        repeatWeekdays: const [],
        lastLocation: null,
      );
    }

    test('child monitor ignores completed trip even inside grace window', () {
      final completedTrip = buildTrip(
        id: 'completed',
        status: TripStatus.completed,
        updatedAt: now.subtract(const Duration(minutes: 2)),
      );
      final activeTrip = buildTrip(
        id: 'active',
        status: TripStatus.active,
        updatedAt: now.subtract(const Duration(minutes: 5)),
      );

      final selected = selectCurrentTripForAudience(
        [completedTrip, activeTrip],
        audience: TripVisibilityAudience.childMonitor,
        now: now,
      );

      expect(selected?.id, 'active');
    });

    test('child monitor returns null when only completed trip exists', () {
      final completedTrip = buildTrip(
        id: 'completed',
        status: TripStatus.completed,
        updatedAt: now.subtract(const Duration(minutes: 1)),
      );

      final selected = selectCurrentTripForAudience(
        [completedTrip],
        audience: TripVisibilityAudience.childMonitor,
        now: now,
      );

      expect(selected, isNull);
    });

    test('adult manager can still see recent completed trip', () {
      final completedTrip = buildTrip(
        id: 'completed',
        status: TripStatus.completed,
        updatedAt: now.subtract(const Duration(minutes: 4)),
      );

      final selected = selectCurrentTripForAudience(
        [completedTrip],
        audience: TripVisibilityAudience.adultManager,
        now: now,
      );

      expect(selected?.id, 'completed');
    });

    test('adult manager hides completed trip after grace window', () {
      final completedTrip = buildTrip(
        id: 'completed',
        status: TripStatus.completed,
        updatedAt: now.subtract(
          kAdultRecentCompletedTripWindow + const Duration(minutes: 1),
        ),
      );

      final selected = selectCurrentTripForAudience(
        [completedTrip],
        audience: TripVisibilityAudience.adultManager,
        now: now,
      );

      expect(selected, isNull);
    });
  });
}
