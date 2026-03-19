import 'package:kid_manager/features/safe_route/domain/entities/route_hazard.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

class RouteHazardModel extends RouteHazard {
  const RouteHazardModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.radiusMeters,
    required super.riskLevel,
    super.sourceZoneId,
  });

  factory RouteHazardModel.fromMap(Map<String, dynamic> map) {
    return RouteHazardModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 0,
      riskLevel: parseZoneRiskLevel(map['riskLevel']),
      sourceZoneId: map['sourceZoneId']?.toString(),
    );
  }

  factory RouteHazardModel.fromEntity(RouteHazard entity) {
    return RouteHazardModel(
      id: entity.id,
      name: entity.name,
      latitude: entity.latitude,
      longitude: entity.longitude,
      radiusMeters: entity.radiusMeters,
      riskLevel: entity.riskLevel,
      sourceZoneId: entity.sourceZoneId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'riskLevel': riskLevel.name,
      'sourceZoneId': sourceZoneId,
    };
  }

  RouteHazard toEntity() => RouteHazard(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        riskLevel: riskLevel,
        sourceZoneId: sourceZoneId,
      );
}
