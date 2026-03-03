import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepository(this._firestore);

  // =========================
  // GET SCHEDULES BY MONTH
  // =========================
  Future<List<Schedule>> getSchedulesByMonth({
    required String parentUid,
    required String childId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNextMonth = DateTime(month.year, month.month + 1, 1);

    final snapshot = await _firestore
        .collection('parents')
        .doc(parentUid)
        .collection('schedules')
        .where('childId', isEqualTo: childId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('startAt', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('startAt')
        .get();

    return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
  }

  // =========================
  // ✅ GET SCHEDULES BY RANGE (for dedupe import)
  // =========================
  Future<List<Schedule>> getSchedulesByRange({
    required String parentUid,
    required String childId,
    required DateTime start, // inclusive
    required DateTime end, // exclusive
  }) async {
    final snapshot = await _firestore
        .collection('parents')
        .doc(parentUid)
        .collection('schedules')
        .where('childId', isEqualTo: childId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('startAt')
        .get();

    return snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
  }

  // =========================
  // CRUD
  // =========================
  Future<void> createSchedule(String parentUid, Schedule s) async {
    await _firestore
        .collection('parents')
        .doc(parentUid)
        .collection('schedules')
        .add(s.toMap());
  }

  Future<void> updateSchedule(String parentUid, Schedule s) async {
    await _firestore
        .collection('parents')
        .doc(parentUid)
        .collection('schedules')
        .doc(s.id)
        .update(s.toMap());
  }

  Future<void> deleteSchedule(String parentUid, String id) async {
    await _firestore
        .collection('parents')
        .doc(parentUid)
        .collection('schedules')
        .doc(id)
        .delete();
  }

  // =========================
  // ✅ BATCH CREATE (for import)
  // =========================
  Future<void> createSchedulesBatch({
    required String parentUid,
    required List<Schedule> items,
  }) async {
    if (items.isEmpty) return;

    const chunkSize = 450; // an toàn dưới 500 writes/batch

    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.sublist(
        i,
        (i + chunkSize > items.length) ? items.length : i + chunkSize,
      );

      final batch = _firestore.batch();
      for (final s in chunk) {
        final ref = _firestore
            .collection('parents')
            .doc(parentUid)
            .collection('schedules')
            .doc(); // random id
        batch.set(ref, s.toMap());
      }
      await batch.commit();
    }
  }
}