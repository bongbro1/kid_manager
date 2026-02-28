import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory_day.dart';

class MemoryDayRepository {
  final FirebaseFirestore _firestore;
  MemoryDayRepository(this._firestore);

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
    await _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memories')
        .add(m.toMap());
  }

  Future<void> update(String ownerParentUid, MemoryDay m) async {
    await _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memories')
        .doc(m.id)
        .update(m.toMap());
  }

  Future<void> delete(String ownerParentUid, String id) async {
    await _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memories')
        .doc(id)
        .delete();
  }
}