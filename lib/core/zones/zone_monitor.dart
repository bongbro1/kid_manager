import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';

class ZoneMonitor {
  final ZoneRepository repo;
  final String childUid;

  ZoneMonitor({
    required this.repo,
    required this.childUid,
  });

  List<GeoZone> _zones = [];
  final Set<String> _inside = {}; // zoneIds currently inside

  int _lastEventAtMs = 0;

  void updateZones(List<GeoZone> zones) {
    _zones = zones.where((z) => z.enabled).toList();
  }

  /// Call for every location update
  Future<void> onLocation(LocationData loc) async {
    if (_zones.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    // anti-spam: tối thiểu 3s giữa các event
    if (now - _lastEventAtMs < 3000) return;

    for (final z in _zones) {
      final d = _distanceMeters(loc.latitude, loc.longitude, z.lat, z.lng);
      final isIn = d <= z.radiusM;
      final wasIn = _inside.contains(z.id);

      if (isIn && !wasIn) {
        _inside.add(z.id);
        _lastEventAtMs = now;

        //  local alarm trên máy con nếu danger
        if (z.type == ZoneType.danger) {
          await LocalAlarmService.I.showDangerEnter(zoneName: z.name);
        }
        await repo.pushZoneEvent(childUid, {
          "zoneId": z.id,
          "zoneType": z.type.name, // safe/danger
          "action": "enter",
          "zoneName": z.name,
          "lat": loc.latitude,
          "lng": loc.longitude,
          "timestamp": loc.timestamp,
        });

        debugPrint("🧭 ZONE ENTER: ${z.name} (${z.type.name})");
      }

      if (!isIn && wasIn) {
        _inside.remove(z.id);
        _lastEventAtMs = now;

        await repo.pushZoneEvent(childUid, {
          "zoneId": z.id,
          "zoneType": z.type.name,
          "action": "exit",
          "zoneName": z.name,
          "lat": loc.latitude,
          "lng": loc.longitude,
          "timestamp": loc.timestamp,
        });

        debugPrint("🧭 ZONE EXIT: ${z.name} (${z.type.name})");
      }
    }
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;
}