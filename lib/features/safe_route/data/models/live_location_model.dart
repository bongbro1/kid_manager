import 'package:kid_manager/features/safe_route/domain/entities/live_location.dart';

class LiveLocationModel extends LiveLocation {
  const LiveLocationModel({
    required super.childId,
    required super.latitude,
    required super.longitude,
    required super.accuracyMeters,
    required super.speedMps,
    required super.bearing,
    required super.batteryLevel,
    required super.isCharging,
    required super.isMock,
    required super.timestamp,
  });

  factory LiveLocationModel.fromMap(String childId, Map<dynamic, dynamic> map) {
    return LiveLocationModel(
      childId: childId,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (map['accuracy'] as num?)?.toDouble() ?? 0,
      speedMps: (map['speed'] as num?)?.toDouble() ?? 0,
      bearing: (map['heading'] as num?)?.toDouble() ?? 0,
      batteryLevel: (map['batteryLevel'] as num?)?.toDouble(),
      isCharging: map['isCharging'] == null ? null : map['isCharging'] == true,
      isMock: map['isMock'] == true,
      timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  factory LiveLocationModel.fromEntity(LiveLocation entity) {
    return LiveLocationModel(
      childId: entity.childId,
      latitude: entity.latitude,
      longitude: entity.longitude,
      accuracyMeters: entity.accuracyMeters,
      speedMps: entity.speedMps,
      bearing: entity.bearing,
      batteryLevel: entity.batteryLevel,
      isCharging: entity.isCharging,
      isMock: entity.isMock,
      timestamp: entity.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracyMeters,
      'speed': speedMps,
      'heading': bearing,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
      'isMock': isMock,
      'timestamp': timestamp,
    };
  }

  LiveLocation toEntity() => LiveLocation(
        childId: childId,
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        speedMps: speedMps,
        bearing: bearing,
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        isMock: isMock,
        timestamp: timestamp,
      );
}
