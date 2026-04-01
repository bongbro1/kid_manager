import 'package:kid_manager/features/safe_route/data/models/trip_model.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model_decoder.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

class CurrentTripSnapshotModel {
  const CurrentTripSnapshotModel({
    required this.childId,
    required this.adultCurrentTrip,
    required this.adultRecentCompletedTrip,
    required this.adultCurrentTripVisibleUntil,
    required this.childMonitorTrip,
  });

  final String childId;
  final TripModel? adultCurrentTrip;
  final TripModel? adultRecentCompletedTrip;
  final DateTime? adultCurrentTripVisibleUntil;
  final TripModel? childMonitorTrip;

  factory CurrentTripSnapshotModel.fromMap(Map<String, dynamic> map) {
    final childId = (map['childId'] ?? '').toString().trim();
    if (childId.isEmpty) {
      throw StateError('CurrentTripSnapshot.childId is required');
    }

    final adultVisibleUntilRaw = map['adultCurrentTripVisibleUntil'];
    final adultVisibleUntil = adultVisibleUntilRaw is num
        ? DateTime.fromMillisecondsSinceEpoch(adultVisibleUntilRaw.toInt())
        : null;

    return CurrentTripSnapshotModel(
      childId: childId,
      adultCurrentTrip: tryParseTripModel(
        map['adultCurrentTrip'] is Map
            ? Map<String, dynamic>.from(map['adultCurrentTrip'] as Map)
            : null,
        source: 'safe_route_current_trips.adultCurrentTrip',
      ),
      adultRecentCompletedTrip: tryParseTripModel(
        map['adultRecentCompletedTrip'] is Map
            ? Map<String, dynamic>.from(map['adultRecentCompletedTrip'] as Map)
            : null,
        source: 'safe_route_current_trips.adultRecentCompletedTrip',
      ),
      adultCurrentTripVisibleUntil: adultVisibleUntil,
      childMonitorTrip: tryParseTripModel(
        map['childMonitorTrip'] is Map
            ? Map<String, dynamic>.from(map['childMonitorTrip'] as Map)
            : null,
        source: 'safe_route_current_trips.childMonitorTrip',
      ),
    );
  }

  TripModel? tripForAudience(
    TripVisibilityAudience audience, {
    DateTime? now,
  }) {
    if (audience == TripVisibilityAudience.childMonitor) {
      return childMonitorTrip;
    }

    final trip = adultCurrentTrip;
    final recentCompletedTrip = adultRecentCompletedTrip;
    final currentTime = now ?? DateTime.now();
    if (recentCompletedTrip != null &&
        adultCurrentTripVisibleUntil != null &&
        adultCurrentTripVisibleUntil!.isAfter(currentTime) &&
        (trip == null ||
            !recentCompletedTrip.updatedAt.isBefore(trip.updatedAt))) {
      return recentCompletedTrip;
    }

    return trip;
  }
}
