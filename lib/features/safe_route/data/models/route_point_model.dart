import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';

class RoutePointModel extends RoutePoint {
  const RoutePointModel({
    required super.latitude,
    required super.longitude,
    required super.sequence,
  });

  factory RoutePointModel.fromMap(Map<String, dynamic> map) {
    return RoutePointModel(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      sequence: (map['sequence'] as num?)?.toInt() ?? 0,
    );
  }

  factory RoutePointModel.fromEntity(RoutePoint entity) {
    return RoutePointModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      sequence: entity.sequence,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
    };
  }

  RoutePoint toEntity() => RoutePoint(
        latitude: latitude,
        longitude: longitude,
        sequence: sequence,
      );
}
