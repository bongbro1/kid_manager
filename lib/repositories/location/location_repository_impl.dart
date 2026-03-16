import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';

class _HistoryChunkPage {
  final List<LocationData> items;
  final bool hasMore;
  final int? nextCursorTs;

  const _HistoryChunkPage({
    required this.items,
    required this.hasMore,
    required this.nextCursorTs,
  });
}

class LocationRepositoryImpl implements LocationRepository {
  final FirebaseDatabase _database;
  final FirebaseAuth _auth;

  LocationRepositoryImpl({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  })  : _database = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const Duration _trackingTzOffset = Duration(hours: 7);
  static const Duration _currentPollingInterval = Duration(seconds: 2);
  static const int _historyChunkLimit = 250;

  String? _cachedParentUid;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  String _formatDayKeyParts(int year, int month, int day) =>
      "${year.toString().padLeft(4, '0')}-"
      "${month.toString().padLeft(2, '0')}-"
      "${day.toString().padLeft(2, '0')}";

  String _trackingDayKeyFromTimestamp(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true)
        .add(_trackingTzOffset);
    return _formatDayKeyParts(d.year, d.month, d.day);
  }

  String _trackingDayKeyFromDate(DateTime day) =>
      _formatDayKeyParts(day.year, day.month, day.day);

  void _log(String msg) {
    debugPrint('[LocationRepo] $msg');
  }

  void _logErr(String msg, Object e, StackTrace st) {
    debugPrint('[LocationRepo] $msg | $e');
    debugPrint('$st');
  }

  Map<String, dynamic> _safePayloadJson(TrackingPayload p) {
    final j = p.toJson();
    return {
      'lat': j['lat'] ?? j['location']?['lat'],
      'lng': j['lng'] ?? j['location']?['lng'],
      'timestamp': p.location.timestamp,
      'acc': j['accuracy'] ?? j['location']?['accuracy'],
      'speed': j['speed'] ?? j['location']?['speed'],
    };
  }

  static void enableRtdbLoggingForDev(FirebaseDatabase db) {
    if (kDebugMode) {
      db.setLoggingEnabled(true);
    }
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    _log('requireUid -> currentUser.uid=$uid');
    if (uid == null || uid.isEmpty) {
      throw Exception("Chua dang nhap -> khong the gui vi tri");
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
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final parentUid = snap.data()?['parentUid'];
      _log('getParentUid -> Firestore parentUid=$parentUid');

      if (parentUid == null) {
        throw Exception('Khong tim thay parentUid');
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

  @override
  Future<void> updateMyCurrent(TrackingPayload payload) async {
    final uid = _requireUid();
    final newTs = payload.location.timestamp;

    _log(
      'updateMyCurrent -> uid=$uid newTs=$newTs payload=${_safePayloadJson(payload)}',
    );

    try {
      await _ensureMeta(uid);

      final ref = _database.ref('locations/$uid/current');

      final result = await ref.runTransaction((current) {
        if (current is Map) {
          final oldTsRaw = current['timestamp'];
          final oldTs =
              (oldTsRaw is num) ? oldTsRaw.toInt() : int.tryParse('$oldTsRaw') ?? 0;

          if (oldTs >= newTs) {
            return Transaction.abort();
          }
        }

        return Transaction.success({
          ..._flattenPayload(payload),
          'updatedAt': ServerValue.timestamp,
        });
      });

      _log(
        'updateMyCurrent -> committed=${result.committed} dataExists=${result.snapshot.exists}',
      );

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

  String _dayKeyFromTs(int ts) => _trackingDayKeyFromTimestamp(ts);

  @override
  Future<void> appendMyHistory(TrackingPayload payload) async {
    final uid = _requireUid();
    final ts = payload.location.timestamp;
    final day = _dayKeyFromTs(ts);
    final tsKey = ts.toString();

    _log(
      'appendMyHistory -> uid=$uid day=$day tsKey=$tsKey payload=${_safePayloadJson(payload)}',
    );

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

  Map<String, dynamic> _flattenPayload(
    TrackingPayload payload, {
    bool includeSentAt = false,
  }) {
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

  List<LocationData> _parseHistoryItems(dynamic rawItems) {
    if (rawItems is! List) return const <LocationData>[];

    final items = <LocationData>[];
    for (final item in rawItems) {
      if (item is Map) {
        items.add(LocationData.fromJson(Map<String, dynamic>.from(item)));
      }
    }
    return items;
  }

  Future<_HistoryChunkPage> _fetchHistoryChunk(
    String childUid,
    String dayKey, {
    int? cursorAfterTs,
    int? fromTs,
    int? toTs,
  }) async {
    final res = await _functions.httpsCallable('getChildHistoryChunk').call({
      "childUid": childUid,
      "dayKey": dayKey,
      "limit": _historyChunkLimit,
      if (cursorAfterTs != null) "cursorAfterTs": cursorAfterTs,
      if (fromTs != null) "fromTs": fromTs,
      if (toTs != null) "toTs": toTs,
    });

    final data = Map<String, dynamic>.from(res.data);
    final nextCursorRaw = data["nextCursorTs"];
    final nextCursorTs = nextCursorRaw is num
        ? nextCursorRaw.toInt()
        : int.tryParse("$nextCursorRaw");

    return _HistoryChunkPage(
      items: _parseHistoryItems(data["items"]),
      hasMore: data["hasMore"] == true,
      nextCursorTs: nextCursorTs,
    );
  }

  Future<List<LocationData>> _getHistoryByDayLegacy(
    String childUid,
    String dayKey, {
    int? fromTs,
    int? toTs,
  }) async {
    final res = await _functions.httpsCallable('getChildHistoryByDay').call({
      "childUid": childUid,
      "dayKey": dayKey,
    });

    final data = Map<String, dynamic>.from(res.data);
    final historyRaw = data["history"];
    if (historyRaw == null || historyRaw is! Map) {
      return const <LocationData>[];
    }

    final m = Map<String, dynamic>.from(historyRaw);
    final keys = m.keys.toList()..sort();

    final list = <LocationData>[];
    for (final k in keys) {
      final point = m[k];
      if (point is Map) {
        list.add(LocationData.fromJson(Map<String, dynamic>.from(point)));
      }
    }

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (fromTs == null && toTs == null) {
      return list;
    }

    return list.where((item) {
      if (fromTs != null && item.timestamp < fromTs) return false;
      if (toTs != null && item.timestamp > toTs) return false;
      return true;
    }).toList(growable: false);
  }

  @override
  Stream<LocationData> watchChildLocation(String childId) {
    final ctrl = StreamController<LocationData>();
    StreamSubscription<DatabaseEvent>? rtdbSub;
    Timer? pollTimer;
    bool fallbackStarted = false;
    int? lastTimestamp;

    void emitCurrent(dynamic raw) {
      if (raw is! Map) return;
      final loc = LocationData.fromJson(Map<String, dynamic>.from(raw));
      if (loc.timestamp <= 0 || lastTimestamp == loc.timestamp) return;
      lastTimestamp = loc.timestamp;
      if (!ctrl.isClosed) {
        ctrl.add(loc);
      }
    }

    Future<void> pollOnce() async {
      try {
        final res = await _functions.httpsCallable('getChildLocationCurrent').call({
          "childUid": childId,
        });
        final data = Map<String, dynamic>.from(res.data);
        emitCurrent(data["current"]);
      } catch (e) {
        debugPrint("watchChildLocation(fn) error: $e");
      }
    }

    void startFallbackPolling() {
      if (fallbackStarted) return;
      fallbackStarted = true;
      pollTimer?.cancel();
      unawaited(pollOnce());
      pollTimer = Timer.periodic(_currentPollingInterval, (_) {
        unawaited(pollOnce());
      });
    }

    rtdbSub = _database.ref('locations/$childId/current').onValue.listen(
      (event) => emitCurrent(event.snapshot.value),
      onError: (Object e, StackTrace st) {
        debugPrint("watchChildLocation(rtdb) error: $e");
        unawaited(rtdbSub?.cancel());
        rtdbSub = null;
        startFallbackPolling();
      },
    );

    ctrl.onCancel = () {
      pollTimer?.cancel();
      unawaited(rtdbSub?.cancel());
    };

    return ctrl.stream;
  }

  @override
  Future<List<LocationData>> getLocationHistoryByDay(
    String childId,
    DateTime day, {
    int? fromTs,
    int? toTs,
  }) async {
    final dayKey = _trackingDayKeyFromDate(day);
    debugPrint(
      "[FN] getChildHistoryByDay -> childUid=$childId dayKey=$dayKey fromTs=$fromTs toTs=$toTs",
    );

    try {
      final list = <LocationData>[];
      int? cursorAfterTs;
      var hasMore = true;

      while (hasMore) {
        final page = await _fetchHistoryChunk(
          childId,
          dayKey,
          cursorAfterTs: cursorAfterTs,
          fromTs: fromTs,
          toTs: toTs,
        );
        list.addAll(page.items);
        hasMore = page.hasMore;
        cursorAfterTs = page.nextCursorTs;
        if (page.items.isEmpty) break;
      }

      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint("[FN] parsed points=${list.length}");
      return list;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' ||
          e.code == 'unimplemented' ||
          e.code == 'internal') {
        debugPrint("[FN] fallback legacy history API code=${e.code}");
        return _getHistoryByDayLegacy(
          childId,
          dayKey,
          fromTs: fromTs,
          toTs: toTs,
        );
      }
      debugPrint(
        "[FN] getChildHistoryByDay error code=${e.code} message=${e.message}",
      );
      return const <LocationData>[];
    } catch (e) {
      debugPrint("[FN] getChildHistoryByDay error: $e");
      return const <LocationData>[];
    }
  }

  Future<List<LocationData>> getLocationHistory(String childId) async {
    final now = DateTime.now();
    _log('getLocationHistory -> fallback today=${now.toIso8601String()}');
    return getLocationHistoryByDay(childId, now);
  }
}
