import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';

class ZoneMonitor {
  final ZoneRepositoryInterface repo;
  final String childUid;

  ZoneMonitor({required this.repo, required this.childUid});

  List<GeoZone> _zones = [];
  final Set<String> _inside = {}; // zoneIds currently inside

  int _lastEventAtMs = 0;
  int _lastZoneRefreshAtMs = 0;
  int _lastNoZonesLogAtMs = 0;
  bool _zoneRefreshInFlight = false;

  static const int _zoneReloadCooldownMs = 15000;
  static const int _noZonesLogCooldownMs = 30000;

  void updateZones(List<GeoZone> zones) {
    _zones = zones.where((z) => z.enabled).toList();

    // Keep inside-state consistent when zones are removed or disabled.
    final zoneIds = _zones.map((z) => z.id).toSet();
    _inside.removeWhere((id) => !zoneIds.contains(id));

    debugPrint(
      'ZoneMonitor.updateZones enabled=${_zones.length} childUid=$childUid',
    );
  }

  Future<void> _reloadZonesIfNeeded() async {
    if (_zones.isNotEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_zoneRefreshInFlight) return;
    if (now - _lastZoneRefreshAtMs < _zoneReloadCooldownMs) return;

    _zoneRefreshInFlight = true;
    _lastZoneRefreshAtMs = now;

    try {
      final zones = await repo.getZonesOnce(childUid);
      updateZones(zones);
      debugPrint(
        'ZoneMonitor.reloadZones fetched=${zones.length} childUid=$childUid',
      );
    } catch (e, st) {
      debugPrint('ZoneMonitor.reloadZones error: $e');
      debugPrint('$st');
    } finally {
      _zoneRefreshInFlight = false;
    }
  }

  /// Call for every location update.
  Future<void> onLocation(LocationData loc) async {
    await _reloadZonesIfNeeded();

    if (_zones.isEmpty) {
      if (kDebugMode) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastNoZonesLogAtMs >= _noZonesLogCooldownMs) {
          _lastNoZonesLogAtMs = now;
          debugPrint(
            'ZoneMonitor.onLocation skip: no enabled zones for childUid=$childUid',
          );
        }
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // Anti-spam: at least 3 seconds between zone events.
    if (now - _lastEventAtMs < 3000) return;

    for (final z in _zones) {
      final d = _distanceMeters(loc.latitude, loc.longitude, z.lat, z.lng);
      final isIn = d <= z.radiusM;
      final wasIn = _inside.contains(z.id);

      if (isIn && !wasIn) {
        _inside.add(z.id);
        _lastEventAtMs = now;

        if (z.type == ZoneType.danger) {
          await LocalAlarmService.I.showDangerEnter(zoneName: z.name);
        }

        debugPrint(
          'ZONE ENTER (local observation only): ${z.name} (${z.type.name}) '
          'd=${d.toStringAsFixed(1)}m',
        );
      }

      if (!isIn && wasIn) {
        _inside.remove(z.id);
        _lastEventAtMs = now;

        debugPrint(
          'ZONE EXIT (local observation only): ${z.name} (${z.type.name}) '
          'd=${d.toStringAsFixed(1)}m',
        );
      }
    }
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;
}
