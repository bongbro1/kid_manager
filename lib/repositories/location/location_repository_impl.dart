import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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

  String? _cachedParentUid; // ✅ cache để khỏi đọc Firestore liên tục

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("Chưa đăng nhập -> không thể gửi vị trí");
    }
    return uid;
  }

  Future<String> _getParentUid() async {
    if (_cachedParentUid != null) return _cachedParentUid!;
    final uid = _requireUid();

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final parentUid = snap.data()?['parentUid'];
    debugPrint("parentUid : $parentUid");

    if (parentUid == null) {
      throw Exception('Không tìm thấy parentUid');
    }

    _cachedParentUid = parentUid.toString();
    return _cachedParentUid!;
  }

  Future<void> _ensureMeta(String uid) async {
    final parentUid = await _getParentUid();
    final metaRef = _database.ref('locations/$uid/meta');

    await metaRef.set({
      'parentUid': parentUid,
      'updatedAt': ServerValue.timestamp,
    });
  }

  /// ✅ NEW: update current (không push history)
  /// - dùng transaction để không bị bản timestamp cũ ghi đè current
  Future<void> updateMyCurrent(TrackingPayload payload) async {
    final uid = _requireUid();
    await _ensureMeta(uid);

    final ref = _database.ref('locations/$uid/current');
    final newTs = payload.location.timestamp;

    await ref.runTransaction((current) {
      if (current is Map) {
        final oldTsRaw = current['timestamp'];
        final oldTs = (oldTsRaw is num)
            ? oldTsRaw.toInt()
            : int.tryParse('$oldTsRaw') ?? 0;

        if (oldTs >= newTs) {
          return Transaction.abort(); // ✅ bỏ bản cũ
        }
      }

      return Transaction.success({
        ...payload.toJson(),
        'updatedAt': ServerValue.timestamp,
      });
    });
  }

  /// ✅ NEW: append history only
  Future<void> appendMyHistory(TrackingPayload payload) async {
    final uid = _requireUid();
    await _database.ref('locations/$uid/history').push().set(payload.toJson());
  }

  /// ✅ GIỮ NGUYÊN API CŨ: vẫn set current + push history như trước
  /// (nên các chỗ cũ không cần sửa)
  @override
  Future<void> updateMyLocation(TrackingPayload location) async {
    // giữ behavior cũ: meta + current + history
    await updateMyCurrent(location);
    await appendMyHistory(location);
  }

  @override
  Stream<LocationData> watchChildLocation(String childId) {
    return _database
        .ref('locations/$childId/current')
        .onValue
        .where((event) => event.snapshot.exists)
        .map((event) {
      final value = event.snapshot.value;
      final raw = Map<dynamic, dynamic>.from(value as Map);
      final json = raw.map((k, v) => MapEntry(k.toString(), v));

      debugPrint('📍 RTDB LOCATIONS [$childId] = $json');
      return LocationData.fromJson(json);
    });
  }

  @override
  Future<List<LocationData>> getLocationHistory(String childId) async {
    final snapshot = await _database.ref('locations/$childId/history').get();
    if (!snapshot.exists) return [];

    final list = <LocationData>[];
    for (final data in snapshot.children) {
      if (data.value is Map) {
        final json = Map<String, dynamic>.from(data.value as Map);
        list.add(LocationData.fromJson(json));
      }
    }

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }
}