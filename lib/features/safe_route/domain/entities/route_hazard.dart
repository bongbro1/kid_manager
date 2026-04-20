import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

class RouteHazard {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final ZoneRiskLevel riskLevel;
  final String? sourceZoneId;

  const RouteHazard({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.riskLevel,
    this.sourceZoneId,
  });

  RouteHazard copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    ZoneRiskLevel? riskLevel,
    String? sourceZoneId,
  }) {
    return RouteHazard(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      riskLevel: riskLevel ?? this.riskLevel,
      sourceZoneId: sourceZoneId ?? this.sourceZoneId,
    );
  }
}
