import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

import '../models/schedule.dart';
import '../models/schedule_history.dart';

class ScheduleRepository {
  final FirebaseFirestore _firestore;

  ScheduleRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _scheduleCol(String parentUid) {
    return _firestore
        .collection('parents')
        .doc(parentUid)
        .collection('schedules');
  }

  CollectionReference<Map<String, dynamic>> _historyCol(
    String parentUid,
    String scheduleId,
  ) {
    return _scheduleCol(parentUid).doc(scheduleId).collection('histories');
  }

  Future<List<Schedule>> getSchedulesByMonth({
    required String parentUid,
    required String childId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final startOfNextMonth = DateTime(month.year, month.month + 1, 1);

    final snapshot = await _scheduleCol(parentUid)
        .where('childId', isEqualTo: childId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('startAt', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .orderBy('startAt')
        .get();

    return snapshot.docs
        .map((doc) => Schedule.fromFirestore(doc).copyWith(parentUid: parentUid))
        .toList();
  }

  Future<List<Schedule>> getSchedulesByRange({
    required String parentUid,
    required String childId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _scheduleCol(parentUid)
        .where('childId', isEqualTo: childId)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('startAt')
        .get();

    return snapshot.docs
        .map((doc) => Schedule.fromFirestore(doc).copyWith(parentUid: parentUid))
        .toList();
  }

  Future<String> createSchedule(String parentUid, Schedule s) async {
    final ref = await _scheduleCol(parentUid).add(s.toMap());
    return ref.id;
  }

  /// Updates a schedule and stores a history snapshot of the previous version.
  Future<void> updateSchedule(String parentUid, Schedule newSchedule) async {
    final l10n = runtimeL10n();
    final scheduleRef = _scheduleCol(parentUid).doc(newSchedule.id);
    final historyRef = _historyCol(parentUid, newSchedule.id).doc();

    await _firestore.runTransaction((tx) async {
      final currentSnap = await tx.get(scheduleRef);
      if (!currentSnap.exists) {
        throw Exception(l10n.scheduleRepositoryNotFound);
      }

      final currentSchedule = Schedule.fromFirestore(currentSnap);
      final now = DateTime.now();

      final history = ScheduleHistory.fromSchedule(
        currentSchedule,
        historyCreatedAt: now,
      );

      tx.set(historyRef, history.toMap());

      final updatedSchedule = newSchedule.copyWith(
        editCount: currentSchedule.editCount + 1,
        updatedAt: newSchedule.updatedAt ?? now,
      );

      tx.update(scheduleRef, updatedSchedule.toMap());
    });
  }

  Future<List<ScheduleHistory>> getScheduleHistories({
    required String parentUid,
    required String scheduleId,
  }) async {
    final snapshot = await _historyCol(parentUid, scheduleId)
        .orderBy('historyCreatedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ScheduleHistory.fromFirestore(doc))
        .toList();
  }

  Future<void> restoreScheduleFromHistory({
    required String parentUid,
    required String scheduleId,
    required String historyId,
  }) async {
    final l10n = runtimeL10n();
    final scheduleRef = _scheduleCol(parentUid).doc(scheduleId);
    final selectedHistoryRef = _historyCol(parentUid, scheduleId).doc(historyId);

    // backup bản hiện tại trước khi restore
    final backupCurrentRef = _historyCol(parentUid, scheduleId).doc();

    // tạo 1 version mới đại diện cho bản được restore ở thời điểm hiện tại
    final restoredVersionRef = _historyCol(parentUid, scheduleId).doc();

    await _firestore.runTransaction((tx) async {
      final currentSnap = await tx.get(scheduleRef);
      if (!currentSnap.exists) {
        throw Exception(l10n.scheduleRepositoryCurrentNotFound);
      }

      final selectedHistorySnap = await tx.get(selectedHistoryRef);
      if (!selectedHistorySnap.exists) {
        throw Exception(l10n.scheduleRepositoryHistoryNotFound);
      }

      final currentSchedule = Schedule.fromFirestore(currentSnap);
      final selectedHistory = ScheduleHistory.fromFirestore(selectedHistorySnap);

      final now = DateTime.now();

      // 1) backup current schedule
      final backupCurrent = ScheduleHistory.fromSchedule(
        currentSchedule,
        historyCreatedAt: now,
      );

      // 2) tạo một record history mới cho bản vừa được restore
      final restoredVersion = ScheduleHistory(
        id: '',
        scheduleId: scheduleId,
        childId: selectedHistory.childId,
        parentUid: selectedHistory.parentUid,
        title: selectedHistory.title,
        description: selectedHistory.description,
        date: selectedHistory.date,
        startAt: selectedHistory.startAt,
        endAt: selectedHistory.endAt,
        period: selectedHistory.period,
        originalCreatedAt: selectedHistory.originalCreatedAt,
        originalUpdatedAt: selectedHistory.originalUpdatedAt,
        // +1ms để luôn nằm trên backupCurrent khi sort desc
        historyCreatedAt: now.add(const Duration(milliseconds: 1)),
      );

      tx.set(backupCurrentRef, backupCurrent.toMap());
      tx.set(restoredVersionRef, restoredVersion.toMap());

      final restoredSchedule = selectedHistory.toSchedule(
        currentScheduleId: scheduleId,
        editCount: currentSchedule.editCount + 1,
        updatedAt: now,
      );

      tx.update(scheduleRef, restoredSchedule.toMap());
    });
  }

  Future<void> deleteSchedule(String parentUid, String id) async {
    final historySnapshot = await _historyCol(parentUid, id).get();

    final batch = _firestore.batch();

    for (final doc in historySnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_scheduleCol(parentUid).doc(id));
    await batch.commit();
  }

  Future<void> createSchedulesBatch({
    required String parentUid,
    required List<Schedule> items,
  }) async {
    if (items.isEmpty) return;

    const chunkSize = 450;

    for (var i = 0; i < items.length; i += chunkSize) {
      final chunk = items.sublist(
        i,
        (i + chunkSize > items.length) ? items.length : i + chunkSize,
      );

      final batch = _firestore.batch();
      for (final s in chunk) {
        final ref = _scheduleCol(parentUid).doc();
        batch.set(ref, s.toMap());
      }
      await batch.commit();
    }
  }
}
