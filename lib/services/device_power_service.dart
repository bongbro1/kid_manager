import 'package:battery_plus/battery_plus.dart';

class DevicePowerSnapshot {
  const DevicePowerSnapshot({
    required this.batteryLevel,
    required this.isCharging,
    required this.fetchedAtMs,
  });

  final int? batteryLevel;
  final bool? isCharging;
  final int fetchedAtMs;
}

class DevicePowerService {
  DevicePowerService({
    Battery? battery,
    Duration cacheTtl = const Duration(seconds: 30),
  }) : _battery = battery ?? Battery(),
       _cacheTtl = cacheTtl;

  final Battery _battery;
  final Duration _cacheTtl;

  DevicePowerSnapshot? _cachedSnapshot;
  Future<DevicePowerSnapshot>? _inFlightSnapshot;

  Future<DevicePowerSnapshot> getSnapshot({bool forceRefresh = false}) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cachedSnapshot = _cachedSnapshot;
    if (!forceRefresh &&
        cachedSnapshot != null &&
        nowMs - cachedSnapshot.fetchedAtMs <= _cacheTtl.inMilliseconds) {
      return cachedSnapshot;
    }

    final inFlightSnapshot = _inFlightSnapshot;
    if (!forceRefresh && inFlightSnapshot != null) {
      return inFlightSnapshot;
    }

    final future = _readSnapshot(nowMs);
    _inFlightSnapshot = future;

    try {
      final snapshot = await future;
      _cachedSnapshot = snapshot;
      return snapshot;
    } finally {
      if (identical(_inFlightSnapshot, future)) {
        _inFlightSnapshot = null;
      }
    }
  }

  void clearCache() {
    _cachedSnapshot = null;
  }

  Future<DevicePowerSnapshot> _readSnapshot(int nowMs) async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      return DevicePowerSnapshot(
        batteryLevel: batteryLevel.clamp(0, 100),
        isCharging: _isChargingState(batteryState),
        fetchedAtMs: nowMs,
      );
    } catch (_) {
      final cachedSnapshot = _cachedSnapshot;
      return DevicePowerSnapshot(
        batteryLevel: cachedSnapshot?.batteryLevel,
        isCharging: cachedSnapshot?.isCharging,
        fetchedAtMs: nowMs,
      );
    }
  }

  bool _isChargingState(BatteryState state) {
    return state == BatteryState.charging || state == BatteryState.full;
  }
}
