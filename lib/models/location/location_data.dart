import 'dart:math';

import 'package:kid_manager/models/location/transport_mode.dart';

class LocationData {
  static const Object _unset = Object();

  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed; // m/s
  final double heading; // degrees
  final int? batteryLevel;
  final bool? isCharging;
  final bool isMock;
  final int timestamp; // ms since epoch
  final String motion;
  final TransportMode transport;
  final bool isNetworkGap;
  final int? gapDurationMs;
  final int? gapStartTimestamp;
  final int? gapEndTimestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed = 0,
    this.heading = 0,
    this.batteryLevel,
    this.isCharging,
    this.isMock = false,
    this.motion = '',
    this.transport = TransportMode.unknown,
    this.isNetworkGap = false,
    this.gapDurationMs,
    this.gapStartTimestamp,
    this.gapEndTimestamp,
  });

  factory LocationData.fromDateTime({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime dateTime,
    double speed = 0,
    double heading = 0,
    int? batteryLevel,
    bool? isCharging,
    bool isMock = false,
    String motion = '',
    TransportMode transport = TransportMode.unknown,
    bool isNetworkGap = false,
    int? gapDurationMs,
    int? gapStartTimestamp,
    int? gapEndTimestamp,
  }) {
    return LocationData(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: dateTime.millisecondsSinceEpoch,
      speed: speed,
      heading: heading,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      isMock: isMock,
      motion: motion,
      transport: transport,
      isNetworkGap: isNetworkGap,
      gapDurationMs: gapDurationMs,
      gapStartTimestamp: gapStartTimestamp,
      gapEndTimestamp: gapEndTimestamp,
    );
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    Object? batteryLevel = _unset,
    Object? isCharging = _unset,
    bool? isMock,
    int? timestamp,
    DateTime? dateTime,
    String? motion,
    TransportMode? transport,
    bool? isNetworkGap,
    int? gapDurationMs,
    int? gapStartTimestamp,
    int? gapEndTimestamp,
  }) {
    final resolvedTs = dateTime?.millisecondsSinceEpoch ?? timestamp ?? this.timestamp;

    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      batteryLevel: identical(batteryLevel, _unset)
          ? this.batteryLevel
          : batteryLevel as int?,
      isCharging: identical(isCharging, _unset)
          ? this.isCharging
          : isCharging as bool?,
      isMock: isMock ?? this.isMock,
      timestamp: resolvedTs,
      motion: motion ?? this.motion,
      transport: transport ?? this.transport,
      isNetworkGap: isNetworkGap ?? this.isNetworkGap,
      gapDurationMs: gapDurationMs ?? this.gapDurationMs,
      gapStartTimestamp: gapStartTimestamp ?? this.gapStartTimestamp,
      gapEndTimestamp: gapEndTimestamp ?? this.gapEndTimestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (isCharging != null) 'isCharging': isCharging,
        'isMock': isMock,
        'timestamp': timestamp,
        'sentAt': DateTime.now().millisecondsSinceEpoch,
        'motion': motion,
        'transport': transport.name,
        if (isNetworkGap) 'isNetworkGap': true,
        if (gapDurationMs != null) 'gapDurationMs': gapDurationMs,
        if (gapStartTimestamp != null) 'gapStartTimestamp': gapStartTimestamp,
        if (gapEndTimestamp != null) 'gapEndTimestamp': gapEndTimestamp,
      };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    bool toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      return v.toString().toLowerCase() == 'true';
    }

    return LocationData(
      latitude: toDouble(json['latitude']),
      longitude: toDouble(json['longitude']),
      accuracy: toDouble(json['accuracy']),
      speed: toDouble(json['speed']),
      heading: toDouble(json['heading']),
      batteryLevel: json['batteryLevel'] == null ? null : toInt(json['batteryLevel']),
      isCharging: json['isCharging'] == null ? null : toBool(json['isCharging']),
      isMock: toBool(json['isMock']),
      timestamp: toInt(json['timestamp']),
      motion: (json['motion'] ?? '').toString().trim(),
      transport: parseTransport(json['transport']),
      isNetworkGap: toBool(json['isNetworkGap']),
      gapDurationMs: json['gapDurationMs'] == null ? null : toInt(json['gapDurationMs']),
      gapStartTimestamp: json['gapStartTimestamp'] == null ? null : toInt(json['gapStartTimestamp']),
      gapEndTimestamp: json['gapEndTimestamp'] == null ? null : toInt(json['gapEndTimestamp']),
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  DateTime get dateOnly {
    final d = dateTime;
    return DateTime(d.year, d.month, d.day);
  }

  bool get isToday {
    final now = DateTime.now();
    final d = dateTime;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  String get timeLabel {
    final d = dateTime;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String get timeLabelFull {
    final d = dateTime;
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  String get dateLabel {
    final d = dateTime;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String get fullLabel => '$dateLabel  $timeLabel';

  Duration? get networkGapDuration =>
      gapDurationMs == null ? null : Duration(milliseconds: gapDurationMs!);

  DateTime? get gapStartDateTime =>
      gapStartTimestamp == null ? null : DateTime.fromMillisecondsSinceEpoch(gapStartTimestamp!);

  DateTime? get gapEndDateTime =>
      gapEndTimestamp == null ? null : DateTime.fromMillisecondsSinceEpoch(gapEndTimestamp!);

  double get speedKmh => speed * 3.6;

  double distanceTo(LocationData other) {
    const r = 6371.0;
    final dLat = _degToRad(other.latitude - latitude);
    final dLng = _degToRad(other.longitude - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(latitude)) *
            cos(_degToRad(other.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _degToRad(double deg) => deg * pi / 180.0;
}
