import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/features/safe_route/data/models/safe_route_model.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model.dart';

void main() {
  group('SafeRouteModel.fromMap', () {
    test('throws when required timestamps are missing', () {
      expect(
        () => SafeRouteModel.fromMap(<String, dynamic>{
          'id': 'route-1',
          'childId': 'child-1',
          'name': 'Morning route',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('TripModel.fromMap', () {
    test('throws when required timestamps are missing', () {
      expect(
        () => TripModel.fromMap(<String, dynamic>{
          'id': 'trip-1',
          'childId': 'child-1',
          'parentId': 'parent-1',
          'routeId': 'route-1',
          'status': 'active',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('keeps scheduledStartAt nullable when field is absent', () {
      final trip = TripModel.fromMap(<String, dynamic>{
        'id': 'trip-1',
        'childId': 'child-1',
        'parentId': 'parent-1',
        'routeId': 'route-1',
        'status': 'planned',
        'startedAt': 1710000000000,
        'updatedAt': 1710000005000,
      });

      expect(trip.scheduledStartAt, isNull);
    });

    test('throws when scheduledStartAt is malformed', () {
      expect(
        () => TripModel.fromMap(<String, dynamic>{
          'id': 'trip-1',
          'childId': 'child-1',
          'parentId': 'parent-1',
          'routeId': 'route-1',
          'status': 'planned',
          'startedAt': 1710000000000,
          'updatedAt': 1710000005000,
          'scheduledStartAt': 'not-a-timestamp',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
