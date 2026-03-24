import 'dart:async';

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
        _functions = functions ?? FirebaseFunctions.instanceFor(
          region: 'asia-southeast1',
        );
  DatabaseReference _zonesRef(String childUid) => _db.ref("zonesByChild/$childUid");
  DatabaseReference _eventsRef(String childUid) => _db.ref("zoneEventsByChild/$childUid");

  List<GeoZone> _parseZones(dynamic raw) {
    if (raw is! Map) return <GeoZone>[];

    final m = Map<dynamic, dynamic>.from(raw);
    final list = <GeoZone>[];

    m.forEach((k, v) {
      if (v is Map) {
        list.add(GeoZone.fromJson(k.toString(), Map<String, dynamic>.from(v)));
      }
    });

    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Future<List<GeoZone>> _fetchZonesViaCallable(String childUid) async {
    final callable = _functions.httpsCallable('getChildZones');
    final res = await callable.call({'childUid': childUid});
    final data = Map<String, dynamic>.from(res.data as Map);
    return _parseZones(data['zones']);
  }

  Stream<List<GeoZone>> watchZones(String childUid) {
    final ctrl = StreamController<List<GeoZone>>();
    StreamSubscription<DatabaseEvent>? rtdbSub;
    Timer? pollTimer;
    bool fallbackStarted = false;

    Future<void> pollOnce() async {
      try {
        final list = await _fetchZonesViaCallable(childUid);
        if (!ctrl.isClosed) {
          ctrl.add(list);
        }
      } catch (e, st) {
        debugPrint("watchZones(fn) error childUid=$childUid error=$e");
        debugPrint("$st");
      }
    }

    void startFallbackPolling() {
      if (fallbackStarted) return;
      fallbackStarted = true;
      pollTimer?.cancel();
      unawaited(pollOnce());
      pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        unawaited(pollOnce());
      });
    }

    rtdbSub = _zonesRef(childUid).onValue.listen(
      (event) {
        if (!ctrl.isClosed) {
          ctrl.add(_parseZones(event.snapshot.value));
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint("watchZones(rtdb) error childUid=$childUid error=$e");
        debugPrint("$st");
        unawaited(rtdbSub?.cancel());
        rtdbSub = null;
        startFallbackPolling();
      },
    );

    unawaited(pollOnce());

    ctrl.onCancel = () {
      pollTimer?.cancel();
      unawaited(rtdbSub?.cancel());
    };

    return ctrl.stream;
  }

  Future<List<GeoZone>> getZonesOnce(String childUid) async {
    try {
      final snap = await _zonesRef(childUid).get();
      return _parseZones(snap.value);
    } catch (_) {
      return _fetchZonesViaCallable(childUid);
    }
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
      debugPrint(
        '[ZoneRepository] upsertChildZone OK childUid=$childUid zoneId=${zone.id}',
      );
    } on FirebaseFunctionsException catch (e) {
      final isQuotaLimit =
          e.code == 'resource-exhausted' &&
          (e.message ?? '').contains('FREE_PLAN_ZONE_LIMIT_REACHED');
      if (isQuotaLimit) {
        debugPrint(
          '[ZoneRepository] upsertChildZone quota limit reached childUid=$childUid zoneId=${zone.id}',
        );
      } else {
        debugPrint(
          '[ZoneRepository] upsertChildZone failed: code=${e.code} message=${e.message}',
        );
      }
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
