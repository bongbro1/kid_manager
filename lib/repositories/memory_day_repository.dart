import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory_day.dart';

class MemoryDayRepository {
  final FirebaseFirestore _firestore;
  MemoryDayRepository(this._firestore);

    CollectionReference<Map<String, dynamic>> _col(String ownerParentUid) {
    return _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memories');
  }

  /// Query theo tháng bằng field month (tối ưu cho repeatYearly)
  Future<List<MemoryDay>> getByMonth({
    required String ownerParentUid,
    required DateTime month,
  }) async {
    final snapshot = await _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memories')
        .where('month', isEqualTo: month.month)
        .orderBy('day')
        .get();

    return snapshot.docs.map((d) => MemoryDay.fromFirestore(d)).toList();
  }

  Future<List<MemoryDay>> getAll({
  required String ownerParentUid,
}) async {
  final snapshot = await _firestore
      .collection('parents')
      .doc(ownerParentUid)
      .collection('memories')
      .orderBy('month')
      .orderBy('day')
      .get();

  return snapshot.docs.map((d) => MemoryDay.fromFirestore(d)).toList();
}

  Future<void> create(String ownerParentUid, MemoryDay m) async {
    await _col(ownerParentUid).add(m.toMap());
  }

  Future<void> update(String ownerParentUid, MemoryDay m) async {
    await _col(ownerParentUid).doc(m.id).update(m.toMap());
  }

  Future<void> delete(String ownerParentUid, String id) async {
    await _col(ownerParentUid).doc(id).delete();
  }

  Future<MemoryDay?> getById({
    required String ownerParentUid,
    required String id,
  }) async {
    final snap = await _col(ownerParentUid).doc(id).get();
    if (!snap.exists) return null;
    return MemoryDay.fromFirestore(snap);
  }
}