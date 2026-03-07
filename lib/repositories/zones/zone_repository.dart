import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';

class ZoneRepository {
  final FirebaseDatabase _db;
  final FirebaseFunctions _functions;

  ZoneRepository({
    FirebaseDatabase? db,
    FirebaseFunctions? functions,
  })  : _db = db ?? FirebaseDatabase.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  DatabaseReference _zonesRef(String childUid) => _db.ref("zonesByChild/$childUid");
  DatabaseReference _eventsRef(String childUid) => _db.ref("zoneEventsByChild/$childUid");

  Stream<List<GeoZone>> watchZones(String childUid) {
    return _zonesRef(childUid).onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) return <GeoZone>[];

      final m = Map<dynamic, dynamic>.from(e.snapshot.value as Map);
      final list = <GeoZone>[];

      m.forEach((k, v) {
        if (v is Map) {
          list.add(GeoZone.fromJson(k.toString(), Map<String, dynamic>.from(v)));
        }
      });

      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<List<GeoZone>> getZonesOnce(String childUid) async {
    final snap = await _zonesRef(childUid).get();
    if (!snap.exists || snap.value == null) return [];

    final m = Map<dynamic, dynamic>.from(snap.value as Map);
    final list = <GeoZone>[];

    m.forEach((k, v) {
      if (v is Map) {
        list.add(GeoZone.fromJson(k.toString(), Map<String, dynamic>.from(v)));
      }
    });

    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<String> createZone(String childUid, Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('upsertChildZone');
    final res = await callable.call({
      'childUid': childUid,
      ...data,
    });

    final map = Map<String, dynamic>.from(res.data as Map);
    return (map['zoneId'] ?? '').toString();
  }

  Future<void> upsertZone(String childUid, GeoZone zone) async {
    try {
      final callable = _functions.httpsCallable('upsertChildZone');
      await callable.call({
        'childUid': childUid,
        'zoneId': zone.id,
        ...zone.toJson(),
      });
      debugPrint("✅ callable upsertChildZone OK childUid=$childUid zoneId=${zone.id}");
    } on FirebaseFunctionsException catch (e) {
      debugPrint("❌ callable upsertChildZone failed: code=${e.code} message=${e.message}");
      rethrow;
    }
  }

  Future<void> deleteZone(String childUid, String zoneId) async {
    final callable = _functions.httpsCallable('deleteChildZone');
    await callable.call({
      'childUid': childUid,
      'zoneId': zoneId,
    });
  }

  Future<void> pushZoneEvent(String childUid, Map<String, dynamic> event) async {
    try {
      final ref = _eventsRef(childUid).push();
      await ref.set(event);
      debugPrint("✅ pushZoneEvent OK path=zoneEventsByChild/$childUid/${ref.key} data=$event");
    } catch (e, st) {
      debugPrint("❌ pushZoneEvent FAIL $e");
      debugPrint("$st");
      rethrow;
    }
  }
}