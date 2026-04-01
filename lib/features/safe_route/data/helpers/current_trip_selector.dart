import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

const Duration kAdultRecentCompletedTripWindow = Duration(minutes: 15);

bool isTripVisibleToAudience(
  Trip trip, {
  required TripVisibilityAudience audience,
  DateTime? now,
}) {
  switch (audience) {
    case TripVisibilityAudience.childMonitor:
      return trip.status == TripStatus.active ||
          trip.status == TripStatus.temporarilyDeviated ||
          trip.status == TripStatus.deviated;
    case TripVisibilityAudience.adultManager:
      if (trip.status == TripStatus.planned ||
          trip.status == TripStatus.active ||
          trip.status == TripStatus.temporarilyDeviated ||
          trip.status == TripStatus.deviated) {
        return true;
      }
      if (trip.status != TripStatus.completed) {
        return false;
      }
      final effectiveNow = now ?? DateTime.now();
      return effectiveNow.difference(trip.updatedAt) <=
          kAdultRecentCompletedTripWindow;
  }
}

T? selectCurrentTripForAudience<T extends Trip>(
  Iterable<T> trips, {
  required TripVisibilityAudience audience,
  DateTime? now,
}) {
  final sorted = trips.toList(growable: false)
    ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));

  for (final trip in sorted) {
    if (isTripVisibleToAudience(trip, audience: audience, now: now)) {
      return trip;
    }
  }
  return null;
}
