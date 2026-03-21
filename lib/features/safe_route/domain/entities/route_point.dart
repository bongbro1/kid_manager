class RoutePoint {
  final double latitude;
  final double longitude;
  final int sequence;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  RoutePoint copyWith({
    double? latitude,
    double? longitude,
    int? sequence,
  }) {
    return RoutePoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sequence: sequence ?? this.sequence,
    );
  }
}
