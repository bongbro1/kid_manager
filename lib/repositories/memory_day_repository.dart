import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/memory_day.dart';

class MemoryDayRepository {
  MemoryDayRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String ownerParentUid) {
    // Phase 2: The repository never infers the current user. Callers must pass
    // the resolved parent owner uid so guardian uses the parent's namespace.
    return _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memories');
  }

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

    return snapshot.docs.map((doc) => MemoryDay.fromFirestore(doc)).toList();
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

    return snapshot.docs.map((doc) => MemoryDay.fromFirestore(doc)).toList();
  }

  Future<MemoryDay> create(String ownerParentUid, MemoryDay memory) async {
    final ref = _col(ownerParentUid).doc();
    final persisted = memory.copyWith(id: ref.id);
    await ref.set(persisted.toMap());
    return persisted;
  }

  Future<void> update(String ownerParentUid, MemoryDay memory) async {
    await _col(ownerParentUid).doc(memory.id).update(memory.toMap());
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
