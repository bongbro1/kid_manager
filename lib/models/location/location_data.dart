import 'dart:math';

import 'package:kid_manager/models/location/transport_mode.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final double speed;    // m/s
  final double heading;  // degrees
  final bool isMock;     // fake GPS detect
  final int timestamp;   // ms since epoch
  final TransportMode transport; //

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    this.speed = 0,
    this.heading = 0,
    this.isMock = false,
    this.transport =TransportMode.unknown
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    bool? isMock,
    int? timestamp,
    TransportMode? transport
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isMock: isMock ?? this.isMock,
      timestamp: timestamp ?? this.timestamp,
      transport: transport ?? this.transport,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'isMock': isMock,
    'timestamp': timestamp,
    'sentAt': DateTime.now().millisecondsSinceEpoch,
    'transport': transport.name,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    bool _toBool(dynamic v) {
      if (v == null) return false;
      if (v is bool) return v;
      return v.toString().toLowerCase() == 'true';
    }

    return LocationData(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      accuracy: _toDouble(json['accuracy']),
      speed: _toDouble(json['speed']),     // nếu data cũ → default 0
      heading: _toDouble(json['heading']), // nếu data cũ → default 0
      isMock: _toBool(json['isMock']),     // nếu data cũ → false
      timestamp: _toInt(json['timestamp']),
      transport: parseTransport(json['transport']),
    );
  }

  DateTime get timestampAsDate =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// distance (km) using Haversine
  double distanceTo(LocationData other) {
    const r = 6371.0;
    final dLat = _degToRad(other.latitude - latitude);
    final dLng = _degToRad(other.longitude - longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(latitude)) *
            cos(_degToRad(other.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double get speedKmh => speed * 3.6;

  double _degToRad(double deg) => deg * pi / 180.0;
}


