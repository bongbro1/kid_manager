import 'dart:math';

import 'package:kid_manager/models/location/transport_mode.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final double speed;    // m/s
  final double heading;  // degrees
  final bool isMock;     // fake GPS detect
  final int timestamp;   // ms since epoch (int gốc – không đổi)
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
    this.isMock = false,
    this.transport = TransportMode.unknown,
    this.isNetworkGap = false,
    this.gapDurationMs,
    this.gapStartTimestamp,
    this.gapEndTimestamp,
  });

  // ── Factory từ DateTime ───────────────────────────────────────────────────

  /// Tạo LocationData với DateTime thay vì int ms.
  factory LocationData.fromDateTime({
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime dateTime,
    double speed = 0,
    double heading = 0,
    bool isMock = false,
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
      isMock: isMock,
      transport: transport,
      isNetworkGap: isNetworkGap,
      gapDurationMs: gapDurationMs,
      gapStartTimestamp: gapStartTimestamp,
      gapEndTimestamp: gapEndTimestamp,
    );
  }

  // ── copyWith ──────────────────────────────────────────────────────────────

  /// Hỗ trợ cả [timestamp] (int) lẫn [dateTime] (DateTime).
  /// Nếu truyền cả hai thì [dateTime] ưu tiên hơn.
  LocationData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? speed,
    double? heading,
    bool? isMock,
    int? timestamp,
    DateTime? dateTime, // ← tiện hơn khi có sẵn DateTime
    TransportMode? transport,
    bool? isNetworkGap,
    int? gapDurationMs,
    int? gapStartTimestamp,
    int? gapEndTimestamp,
  }) {
    final int resolvedTs = dateTime?.millisecondsSinceEpoch
        ?? timestamp
        ?? this.timestamp;

    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      isMock: isMock ?? this.isMock,
      timestamp: resolvedTs,
      transport: transport ?? this.transport,
      isNetworkGap: isNetworkGap ?? this.isNetworkGap,
      gapDurationMs: gapDurationMs ?? this.gapDurationMs,
      gapStartTimestamp: gapStartTimestamp ?? this.gapStartTimestamp,
      gapEndTimestamp: gapEndTimestamp ?? this.gapEndTimestamp,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'isMock': isMock,
    'timestamp': timestamp,                              // int → server
    'sentAt': DateTime.now().millisecondsSinceEpoch,
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
      isMock: toBool(json['isMock']),
      timestamp: toInt(json['timestamp']),
      transport: parseTransport(json['transport']),
      isNetworkGap: toBool(json['isNetworkGap']),
      gapDurationMs:
          json['gapDurationMs'] == null ? null : toInt(json['gapDurationMs']),
      gapStartTimestamp: json['gapStartTimestamp'] == null
          ? null
          : toInt(json['gapStartTimestamp']),
      gapEndTimestamp: json['gapEndTimestamp'] == null
          ? null
          : toInt(json['gapEndTimestamp']),
    );
  }

  // ── DateTime getters (local) ──────────────────────────────────────────────

  /// DateTime đầy đủ (local timezone).
  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);

  /// Chỉ phần ngày, không có giờ.
  DateTime get dateOnly {
    final d = dateTime;
    return DateTime(d.year, d.month, d.day);
  }

  /// Kiểm tra nhanh xem có phải hôm nay không.
  bool get isToday {
    final now = DateTime.now();
    final d = dateTime;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  // ── Format helpers ────────────────────────────────────────────────────────

  /// "HH:mm"
  String get timeLabel {
    final d = dateTime;
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  /// "HH:mm:ss"
  String get timeLabelFull {
    final d = dateTime;
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}:'
        '${d.second.toString().padLeft(2, '0')}';
  }

  /// "dd/MM/yyyy"
  String get dateLabel {
    final d = dateTime;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  /// "dd/MM/yyyy HH:mm"
  String get fullLabel => '$dateLabel  $timeLabel';

  Duration? get networkGapDuration =>
      gapDurationMs == null ? null : Duration(milliseconds: gapDurationMs!);

  DateTime? get gapStartDateTime => gapStartTimestamp == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(gapStartTimestamp!);

  DateTime? get gapEndDateTime => gapEndTimestamp == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(gapEndTimestamp!);

  // ── Tính toán ─────────────────────────────────────────────────────────────

  double get speedKmh => speed * 3.6;

  /// Khoảng cách (km) – Haversine.
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
