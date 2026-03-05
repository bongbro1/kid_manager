import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';

class ZoneRepository {
  final FirebaseDatabase _db;
  ZoneRepository({FirebaseDatabase? db}) : _db = db ?? FirebaseDatabase.instance;

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
    final ref = _zonesRef(childUid).push();
    await ref.set(data);
    return ref.key!;
  }

  Future<void> upsertZone(String childUid, GeoZone zone) async {
    try {
      debugPrint("➡️ RTDB set zonesByChild/$childUid/${zone.id}");
      debugPrint("DATA: ${zone.toJson()}");
      await _zonesRef(childUid).child(zone.id).set(zone.toJson());
    } on FirebaseException catch (e) {
      debugPrint("❌ RTDB set failed: code=${e.code} message=${e.message}");
      rethrow;
    }
  }

  Future<void> deleteZone(String childUid, String zoneId) async {
    await _zonesRef(childUid).child(zoneId).remove();
  }

  /// Child ghi event enter/exit → Cloud Function sẽ chuyển thành notifications + FCM
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