class GeoZone {
  final String id;
  final String name;
  final ZoneType type; // safe/danger
  final double lat;
  final double lng;
  final double radiusM;
  final bool enabled;

  final String createdBy;
  final int createdAt;
  final int updatedAt;

  GeoZone({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.enabled,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  GeoZone copyWith({
    String? id,
    String? name,
    ZoneType? type,
    double? lat,
    double? lng,
    double? radiusM,
    bool? enabled,
    String? createdBy,
    int? createdAt,
    int? updatedAt,
  }) {
    return GeoZone(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      radiusM: radiusM ?? this.radiusM,
      enabled: enabled ?? this.enabled,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "type": type.name,
    "lat": lat,
    "lng": lng,
    "radiusM": radiusM,
    "enabled": enabled,
    "createdBy": createdBy,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
  };

  factory GeoZone.fromJson(String id, Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? "") ?? 0;
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? "") ?? 0;
    }

    return GeoZone(
      id: id,
      name: (json["name"] ?? "").toString(),
      type: ZoneTypeX.parse(json["type"]),
      lat: toDouble(json["lat"]),
      lng: toDouble(json["lng"]),
      radiusM: toDouble(json["radiusM"]),
      enabled: (json["enabled"] ?? true) == true,
      createdBy: (json["createdBy"] ?? "").toString(),
      createdAt: toInt(json["createdAt"]),
      updatedAt: toInt(json["updatedAt"]),
    );
  }
}

enum ZoneType { safe, danger }

extension ZoneTypeX on ZoneType {
  static ZoneType parse(dynamic v) {
    final s = (v ?? "").toString().trim();
    return ZoneType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ZoneType.safe,
    );
  }

  String get label {
    switch (this) {
      case ZoneType.safe:
        return "An toàn";
      case ZoneType.danger:
        return "Nguy hiểm";
    }
  }
}
