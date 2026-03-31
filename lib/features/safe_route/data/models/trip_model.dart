import 'package:kid_manager/features/safe_route/data/models/live_location_model.dart';
import 'package:kid_manager/features/safe_route/data/models/safe_route_model.dart';
import 'package:kid_manager/features/safe_route/data/models/safe_route_timestamp_parser.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';

class TripModel extends Trip {
  const TripModel({
    required super.id,
    required super.childId,
    required super.parentId,
    required super.routeId,
    required super.alternativeRouteIds,
    required super.currentRouteId,
    required super.routeName,
    required super.status,
    required super.reason,
    required super.consecutiveDeviationCount,
    required super.currentDistanceFromRouteMeters,
    required super.startedAt,
    required super.updatedAt,
    required super.scheduledStartAt,
    required super.repeatWeekdays,
    required super.lastLocation,
    super.previewRoute,
    super.previewAlternativeRoutes = const [],
  });

  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: (map['id'] ?? '').toString(),
      childId: (map['childId'] ?? '').toString(),
      parentId: (map['parentId'] ?? '').toString(),
      routeId: (map['routeId'] ?? '').toString(),
      alternativeRouteIds: (map['alternativeRouteIds'] as List? ?? const [])
          .map((item) => item.toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false),
      currentRouteId: map['currentRouteId']?.toString(),
      routeName: map['routeName']?.toString(),
      status: parseTripStatus(map['status']),
      reason: map['reason']?.toString(),
      consecutiveDeviationCount: (map['consecutiveDeviationCount'] as num?)?.toInt() ?? 0,
      currentDistanceFromRouteMeters: (map['currentDistanceFromRouteMeters'] as num?)?.toDouble() ?? 0,
      startedAt: parseRequiredSafeRouteTimestamp(
        map['startedAt'],
        fieldName: 'Trip.startedAt',
      ),
      updatedAt: parseRequiredSafeRouteTimestamp(
        map['updatedAt'],
        fieldName: 'Trip.updatedAt',
      ),
      scheduledStartAt: parseOptionalSafeRouteTimestamp(
        map['scheduledStartAt'],
        fieldName: 'Trip.scheduledStartAt',
      ),
      repeatWeekdays: (map['repeatWeekdays'] as List? ?? const [])
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .where((day) => day >= 1 && day <= 7)
          .toList(growable: false),
      lastLocation: map['lastLocation'] is Map
          ? LiveLocationModel.fromMap((map['childId'] ?? '').toString(), Map<dynamic, dynamic>.from(map['lastLocation'] as Map))
          : null,
      previewRoute: map['previewRoute'] is Map
          ? SafeRouteModel.fromMap(
              Map<String, dynamic>.from(map['previewRoute'] as Map),
            )
          : null,
      previewAlternativeRoutes:
          (map['previewAlternativeRoutes'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (item) => SafeRouteModel.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false),
    );
  }

  factory TripModel.fromEntity(Trip entity) {
    return TripModel(
      id: entity.id,
      childId: entity.childId,
      parentId: entity.parentId,
      routeId: entity.routeId,
      alternativeRouteIds: entity.alternativeRouteIds,
      currentRouteId: entity.currentRouteId,
      routeName: entity.routeName,
      status: entity.status,
      reason: entity.reason,
      consecutiveDeviationCount: entity.consecutiveDeviationCount,
      currentDistanceFromRouteMeters: entity.currentDistanceFromRouteMeters,
      startedAt: entity.startedAt,
      updatedAt: entity.updatedAt,
      scheduledStartAt: entity.scheduledStartAt,
      repeatWeekdays: entity.repeatWeekdays,
      lastLocation: entity.lastLocation,
      previewRoute: entity.previewRoute,
      previewAlternativeRoutes: entity.previewAlternativeRoutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'parentId': parentId,
      'routeId': routeId,
      'alternativeRouteIds': alternativeRouteIds,
      'currentRouteId': currentRouteId,
      'routeName': routeName,
      'status': status.name,
      'reason': reason,
      'consecutiveDeviationCount': consecutiveDeviationCount,
      'currentDistanceFromRouteMeters': currentDistanceFromRouteMeters,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'scheduledStartAt': scheduledStartAt?.millisecondsSinceEpoch,
      'repeatWeekdays': repeatWeekdays,
      'lastLocation': lastLocation == null
          ? null
          : LiveLocationModel.fromEntity(lastLocation!).toMap(),
      'previewRoute': previewRoute == null
          ? null
          : SafeRouteModel.fromEntity(previewRoute!).toMap(),
      'previewAlternativeRoutes': previewAlternativeRoutes
          .map((route) => SafeRouteModel.fromEntity(route).toMap())
          .toList(growable: false),
    };
  }

  Trip toEntity() => Trip(
        id: id,
        childId: childId,
        parentId: parentId,
        routeId: routeId,
        alternativeRouteIds: alternativeRouteIds,
        currentRouteId: currentRouteId,
        routeName: routeName,
        status: status,
        reason: reason,
        consecutiveDeviationCount: consecutiveDeviationCount,
        currentDistanceFromRouteMeters: currentDistanceFromRouteMeters,
        startedAt: startedAt,
        updatedAt: updatedAt,
        scheduledStartAt: scheduledStartAt,
        repeatWeekdays: repeatWeekdays,
        lastLocation: lastLocation,
        previewRoute: previewRoute,
        previewAlternativeRoutes: previewAlternativeRoutes,
      );
}
