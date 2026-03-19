import 'package:kid_manager/features/safe_route/domain/entities/route_hazard.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';

class SafeRoute {
  final String id;
  final String childId;
  final String? parentId;
  final String name;
  final RoutePoint startPoint;
  final RoutePoint endPoint;
  final List<RoutePoint> points;
  final List<RouteHazard> hazards;
  final double corridorWidthMeters;
  final double distanceMeters;
  final double durationSeconds;
  final SafeRouteTravelMode travelMode;
  final String? profile;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SafeRoute({
    required this.id,
    required this.childId,
    required this.parentId,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.points,
    required this.hazards,
    required this.corridorWidthMeters,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.travelMode,
    required this.profile,
    required this.createdAt,
    required this.updatedAt,
  });

  SafeRoute copyWith({
    String? id,
    String? childId,
    String? parentId,
    String? name,
    RoutePoint? startPoint,
    RoutePoint? endPoint,
    List<RoutePoint>? points,
    List<RouteHazard>? hazards,
    double? corridorWidthMeters,
    double? distanceMeters,
    double? durationSeconds,
    SafeRouteTravelMode? travelMode,
    String? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafeRoute(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      points: points ?? this.points,
      hazards: hazards ?? this.hazards,
      corridorWidthMeters: corridorWidthMeters ?? this.corridorWidthMeters,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      travelMode: travelMode ?? this.travelMode,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
