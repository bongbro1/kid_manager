import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  LocationRepositoryImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? _cachedParentUid;
  String _dayKey(DateTime d) =>
      "${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}";
  // ====== LOG HELPERS ======
  void _log(String msg) {
    // debugPrint có throttle, nhưng ổn cho dev
    debugPrint('🧭 [LocationRepo] $msg');
  }

  void _logErr(String msg, Object e, StackTrace st) {
    debugPrint('🧭❌ [LocationRepo] $msg | $e');
    debugPrint('$st');
  }

  Map<String, dynamic> _safePayloadJson(TrackingPayload p) {
    // tránh log quá to (nếu payload có nhiều field)
    final j = p.toJson();
    return {
      'lat': j['lat'] ?? j['location']?['lat'],
      'lng': j['lng'] ?? j['location']?['lng'],
      'timestamp': p.location.timestamp,
      'acc': j['accuracy'] ?? j['location']?['accuracy'],
      'speed': j['speed'] ?? j['location']?['speed'],
    };
  }

  // ====== OPTIONAL: bật RTDB logging (Android thường thấy rõ) ======
  // Gọi 1 lần ở app startup hoặc ngay trong constructor (dev only).
  // Lưu ý: iOS đôi khi không in đầy đủ như Android.
  static void enableRtdbLoggingForDev(FirebaseDatabase db) {
    if (kDebugMode) {
      db.setLoggingEnabled(true);
    }
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    _log('requireUid -> currentUser.uid=$uid');
    if (uid == null || uid.isEmpty) {
      throw Exception("Chưa đăng nhập -> không thể gửi vị trí");
    }
    return uid;
  }

  Future<String> _getParentUid() async {
    if (_cachedParentUid != null) {
      _log('getParentUid -> cache hit parentUid=$_cachedParentUid');
      return _cachedParentUid!;
    }

    final uid = _requireUid();
    _log('getParentUid -> fetch Firestore users/$uid');

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final parentUid = snap.data()?['parentUid'];
      _log('getParentUid -> Firestore parentUid=$parentUid');

      if (parentUid == null) {
        throw Exception('Không tìm thấy parentUid');
      }

      _cachedParentUid = parentUid.toString();
      return _cachedParentUid!;
    } catch (e, st) {
      _logErr('getParentUid failed', e, st);
      rethrow;
    }
  }

  Future<void> _ensureMeta(String uid) async {
    try {
      final parentUid = await _getParentUid();
      final metaRef = _database.ref('locations/$uid/meta');

      _log('ensureMeta -> set locations/$uid/meta {parentUid:$parentUid}');
      await metaRef.set({
        'parentUid': parentUid,
        'updatedAt': ServerValue.timestamp,
      });
      _log('ensureMeta -> OK');
    } catch (e, st) {
      _logErr('ensureMeta failed', e, st);
      rethrow;
    }
  }

  /// update current (transaction chống ghi đè timestamp cũ)
  Future<void> updateMyCurrent(TrackingPayload payload) async {
    final uid = _requireUid();
    final newTs = payload.location.timestamp;

    _log('updateMyCurrent -> uid=$uid newTs=$newTs payload=${_safePayloadJson(payload)}');

    try {
      await _ensureMeta(uid);

      final ref = _database.ref('locations/$uid/current');

      final result = await ref.runTransaction((current) {
        // log trong transaction: chỉ log nhẹ thôi
        if (current is Map) {
          final oldTsRaw = current['timestamp'];
          final oldTs = (oldTsRaw is num)
              ? oldTsRaw.toInt()
              : int.tryParse('$oldTsRaw') ?? 0;

          if (oldTs >= newTs) {
            // abort vì timestamp cũ >= mới
            return Transaction.abort();
          }
        }

        return Transaction.success({
          ..._flattenPayload(payload),
          'updatedAt': ServerValue.timestamp,
        });
      });

      // Sau transaction, log kết quả commit/abort
      _log('updateMyCurrent -> committed=${result.committed} '
          'dataExists=${result.snapshot.exists}');

      if (!result.committed) {
        _log('updateMyCurrent -> ABORT (old timestamp >= new timestamp)');
      } else {
        _log('updateMyCurrent -> OK wrote locations/$uid/current');
      }
    } catch (e, st) {
      _logErr('updateMyCurrent failed', e, st);
      rethrow;
    }
  }

  String _dayKeyFromTs(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  /// append history -> historyByDay/{day}/{tsKey}
  Future<void> appendMyHistory(TrackingPayload payload) async {
    final uid = _requireUid();
    final ts = payload.location.timestamp;
    final day = _dayKeyFromTs(ts);
    final tsKey = ts.toString();

    _log('appendMyHistory -> uid=$uid day=$day tsKey=$tsKey payload=${_safePayloadJson(payload)}');

    try {
      await _database
          .ref('locations/$uid/historyByDay/$day/$tsKey')
          .set(_flattenPayload(payload, includeSentAt: true));

      _log('appendMyHistory -> OK wrote locations/$uid/historyByDay/$day/$tsKey');
    } catch (e, st) {
      _logErr('appendMyHistory failed', e, st);
      rethrow;
    }
  }



  Map<String, dynamic> _flattenPayload(TrackingPayload payload, {bool includeSentAt = false}) {
    final loc = payload.location;

    final map = <String, dynamic>{
      "accuracy": loc.accuracy,
      "latitude": loc.latitude,
      "longitude": loc.longitude,
      "speed": loc.speed,
      "heading": loc.heading,
      "isMock": loc.isMock,
      "timestamp": loc.timestamp,
      "deviceId": payload.deviceId,
      "motion": payload.motion,
      "transport": payload.transport,
    };

    if (includeSentAt) {
      map["sentAt"] = ServerValue.timestamp;
    }
    return map;
  }
  @override
  Future<void> updateMyLocation(TrackingPayload location) async {
    _log('updateMyLocation -> START');
    await updateMyCurrent(location);
    await appendMyHistory(location);
    _log('updateMyLocation -> DONE');
  }

  Future<List<LocationData>> getHistoryByDayViaFn(String childUid, String dayKey) async {
    final fn = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
    final res = await fn.httpsCallable('getChildHistoryByDay').call({
      "childUid": childUid,
      "dayKey": dayKey,
    });

    final data = Map<String, dynamic>.from(res.data);
    final historyRaw = data["history"];
    if (historyRaw == null) return [];

    final m = Map<String, dynamic>.from(historyRaw as Map);

    final keys = m.keys.toList()..sort();
    return keys.map((k) {
      final point = Map<String, dynamic>.from(m[k] as Map);
      return LocationData.fromJson(point);
    }).toList()
      ..sort((a,b)=>a.timestamp.compareTo(b.timestamp));
  }


  @override
  Stream<LocationData> watchChildLocation(String childId) {
    final fn = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
    final ctrl = StreamController<LocationData>();

    Timer? timer;
    timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await fn.httpsCallable('getChildLocationCurrent').call({
          "childUid": childId,
        });

        final data = Map<String, dynamic>.from(res.data);
        final cur = data["current"];
        if (cur == null) return;

        if (cur is Map) {
          final json = Map<String, dynamic>.from(cur);
          ctrl.add(LocationData.fromJson(json));
        }
      } catch (e) {
        // không spam error quá mạnh: bạn có thể ctrl.addError(e)
        debugPrint("watchChildLocation(fn) error: $e");
      }
    });

    ctrl.onCancel = () {
      timer?.cancel();
    };

    return ctrl.stream;
  }
  Future<List<LocationData>> getLocationHistoryByDay(String childId, DateTime day) async {
    final fn = FirebaseFunctions.instanceFor(region: 'asia-southeast1');

    // ✅ FIX CỨNG NGÀY ĐỂ TEST
      final dayKey = _dayKey(DateTime(day.year, day.month, day.day));

    debugPrint("🧪 [FN] getChildHistoryByDay -> childUid=$childId dayKey=$dayKey");

    try {
      final res = await fn.httpsCallable('getChildHistoryByDay').call({
        "childUid": childId,
        "dayKey": dayKey,
      });

      final data = Map<String, dynamic>.from(res.data);
      final historyRaw = data["history"];

      debugPrint("🧪 [FN] response keys=${data.keys.toList()}");
      debugPrint("🧪 [FN] historyRawType=${historyRaw.runtimeType}");

      if (historyRaw == null) {
        debugPrint("🧪 [FN] history is null (no data for dayKey=$dayKey)");
        return [];
      }

      if (historyRaw is! Map) {
        debugPrint("🧪 [FN] history is NOT Map -> $historyRaw");
        return [];
      }

      final m = Map<String, dynamic>.from(historyRaw as Map);
      final keys = m.keys.toList()..sort();

      debugPrint("🧪 [FN] history items=${keys.length} firstKey=${keys.isNotEmpty ? keys.first : 'n/a'}");

      final list = <LocationData>[];
      for (final k in keys) {
        final v = m[k];
        if (v is Map) {
          list.add(LocationData.fromJson(Map<String, dynamic>.from(v)));
        } else {
          debugPrint("🧪 [FN] skip bad item key=$k type=${v.runtimeType}");
        }
      }

      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint("🧪 [FN] parsed points=${list.length}");
      return list;
    } catch (e) {
      debugPrint("🧪❌ [FN] getChildHistoryByDay error: $e");
      return [];
    }
  }
  // @override
  // Future<List<LocationData>> getLocationHistoryByDay(String childId, DateTime day) async {
  //   final fn = FirebaseFunctions.instanceFor(region: 'asia-southeast1');
  //   final dayKey = _dayKey(DateTime(day.year, day.month, day.day));
  //   final res = await fn.httpsCallable('getChildHistoryByDay').call({
  //     "childUid": childId,
  //     "dayKey": dayKey,
  //   });
  //
  //   final data = Map<String, dynamic>.from(res.data);
  //   final historyRaw = data["history"];
  //   if (historyRaw == null) return [];
  //
  //   if (historyRaw is! Map) return [];
  //
  //   final m = Map<String, dynamic>.from(historyRaw as Map);
  //   final keys = m.keys.toList()..sort();
  //
  //   final list = <LocationData>[];
  //   for (final k in keys) {
  //     final v = m[k];
  //     if (v is Map) {
  //       list.add(LocationData.fromJson(Map<String, dynamic>.from(v)));
  //     }
  //   }
  //
  //   list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  //   return list;
  // }
  Future<List<LocationData>> getLocationHistory(String childId) async {
    final now = DateTime.now();
    _log('getLocationHistory -> fallback today=${now.toIso8601String()}');
    return getLocationHistoryByDay(childId, now);
  }
}
