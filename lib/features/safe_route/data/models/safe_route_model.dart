import 'package:kid_manager/features/safe_route/data/models/route_hazard_model.dart';
import 'package:kid_manager/features/safe_route/data/models/route_point_model.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

class SafeRouteModel extends SafeRoute {
  const SafeRouteModel({
    required super.id,
    required super.childId,
    required super.parentId,
    required super.name,
    required super.startPoint,
    required super.endPoint,
    required super.points,
    required super.hazards,
    required super.corridorWidthMeters,
    required super.distanceMeters,
    required super.durationSeconds,
    required super.travelMode,
    required super.profile,
    required super.createdAt,
    required super.updatedAt,
  });

  factory SafeRouteModel.fromMap(Map<String, dynamic> map) {
    final pointMaps = (map['points'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => RoutePointModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final hazardMaps = (map['hazards'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => RouteHazardModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return SafeRouteModel(
      id: (map['id'] ?? '').toString(),
      childId: (map['childId'] ?? '').toString(),
      parentId: map['parentId']?.toString(),
      name: (map['name'] ?? '').toString(),
      startPoint: pointMaps.isNotEmpty
          ? pointMaps.first
          : RoutePointModel.fromMap(Map<String, dynamic>.from(map['startPoint'] as Map? ?? const {})),
      endPoint: pointMaps.isNotEmpty
          ? pointMaps.last
          : RoutePointModel.fromMap(Map<String, dynamic>.from(map['endPoint'] as Map? ?? const {})),
      points: pointMaps,
      hazards: hazardMaps,
      corridorWidthMeters: (map['corridorWidthMeters'] as num?)?.toDouble() ?? 50,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (map['durationSeconds'] as num?)?.toDouble() ?? 0,
      travelMode: parseSafeRouteTravelMode(map['travelMode']),
      profile: map['profile']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch((map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((map['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  factory SafeRouteModel.fromEntity(SafeRoute entity) {
    return SafeRouteModel(
      id: entity.id,
      childId: entity.childId,
      parentId: entity.parentId,
      name: entity.name,
      startPoint: entity.startPoint,
      endPoint: entity.endPoint,
      points: entity.points,
      hazards: entity.hazards,
      corridorWidthMeters: entity.corridorWidthMeters,
      distanceMeters: entity.distanceMeters,
      durationSeconds: entity.durationSeconds,
      travelMode: entity.travelMode,
      profile: entity.profile,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'parentId': parentId,
      'name': name,
      'startPoint': RoutePointModel.fromEntity(startPoint).toMap(),
      'endPoint': RoutePointModel.fromEntity(endPoint).toMap(),
      'points': points.map((point) => RoutePointModel.fromEntity(point).toMap()).toList(),
      'hazards': hazards.map((hazard) => RouteHazardModel.fromEntity(hazard).toMap()).toList(),
      'corridorWidthMeters': corridorWidthMeters,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'travelMode': travelMode.name,
      'profile': profile,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  SafeRoute toEntity() => SafeRoute(
        id: id,
        childId: childId,
        parentId: parentId,
        name: name,
        startPoint: startPoint,
        endPoint: endPoint,
        points: points,
        hazards: hazards,
        corridorWidthMeters: corridorWidthMeters,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
        travelMode: travelMode,
        profile: profile,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
