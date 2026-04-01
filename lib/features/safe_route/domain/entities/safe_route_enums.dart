enum TripStatus {
  planned,
  active,
  temporarilyDeviated,
  deviated,
  completed,
  cancelled,
}

enum TripVisibilityAudience {
  childMonitor,
  adultManager,
}

enum TripMutationState {
  none,
  completing,
  cancelling,
}

TripStatus parseTripStatus(dynamic value) {
  final raw = (value ?? '').toString().trim();
  return TripStatus.values.firstWhere(
    (status) => status.name == raw,
    orElse: () => TripStatus.planned,
  );
}

enum ZoneRiskLevel {
  low,
  medium,
  high,
}

ZoneRiskLevel parseZoneRiskLevel(dynamic value) {
  final raw = (value ?? '').toString().trim();
  return ZoneRiskLevel.values.firstWhere(
    (level) => level.name == raw,
    orElse: () => ZoneRiskLevel.low,
  );
}

enum SafeRouteTravelMode {
  walking,
  motorbike,
  pickup,
  otherVehicle,
}

SafeRouteTravelMode parseSafeRouteTravelMode(dynamic value) {
  final raw = (value ?? '').toString().trim();
  return SafeRouteTravelMode.values.firstWhere(
    (mode) => mode.name == raw,
    orElse: () => SafeRouteTravelMode.walking,
  );
}

extension SafeRouteTravelModeX on SafeRouteTravelMode {
  String get label {
    switch (this) {
      case SafeRouteTravelMode.walking:
        return 'Đi bộ';
      case SafeRouteTravelMode.motorbike:
        return 'Xe máy';
      case SafeRouteTravelMode.pickup:
        return 'Đón con';
      case SafeRouteTravelMode.otherVehicle:
        return 'Phương tiện khác';
    }
  }

  String get mapboxProfile {
    switch (this) {
      case SafeRouteTravelMode.walking:
        return 'walking';
      case SafeRouteTravelMode.motorbike:
      case SafeRouteTravelMode.pickup:
      case SafeRouteTravelMode.otherVehicle:
        return 'driving';
    }
  }
}
