class LiveLocation {
  final String childId;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedMps;
  final double bearing;
  final double? batteryLevel;
  final bool? isCharging;
  final bool isMock;
  final int timestamp;

  const LiveLocation({
    required this.childId,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedMps,
    required this.bearing,
    required this.batteryLevel,
    required this.isCharging,
    required this.isMock,
    required this.timestamp,
  });

  double get speedKmh => speedMps * 3.6;

  LiveLocation copyWith({
    String? childId,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    double? speedMps,
    double? bearing,
    double? batteryLevel,
    bool? isCharging,
    bool? isMock,
    int? timestamp,
  }) {
    return LiveLocation(
      childId: childId ?? this.childId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      speedMps: speedMps ?? this.speedMps,
      bearing: bearing ?? this.bearing,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      isMock: isMock ?? this.isMock,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LiveLocation('
        'childId: $childId, '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'accuracyMeters: $accuracyMeters, '
        'speedMps: $speedMps, '
        'bearing: $bearing, '
        'batteryLevel: $batteryLevel, '
        'isCharging: $isCharging, '
        'isMock: $isMock, '
        'timestamp: $timestamp'
        ')';
  }
}
