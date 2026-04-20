import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/core/network/app_network_error_mapper.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

import '../../models/schedule.dart';

class ScheduleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String parentUid) {
    return _db.collection('parents').doc(parentUid).collection('schedules');
  }

  Future<List<Schedule>> fetchByChildAndDate({
    required String parentUid,
    required String childId,
    required DateTime date,
  }) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final snap = await _col(parentUid)
          .where('childId', isEqualTo: childId)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('startAt')
          .get();

      return snap.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<List<Schedule>> fetchByChildAndRange({
    required String parentUid,
    required String childId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final snap = await _col(parentUid)
          .where('childId', isEqualTo: childId)
          .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('startAt', isLessThan: Timestamp.fromDate(end))
          .orderBy('startAt')
          .get();

      return snap.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> addSchedule(String parentUid, Schedule s) async {
    try {
      await _col(parentUid).add({
        ...s.toMap(),
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> updateSchedule(String parentUid, Schedule s) async {
    try {
      await _col(
        parentUid,
      ).doc(s.id).update({...s.toMap(), 'updatedAt': Timestamp.now()});
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> deleteSchedule(String parentUid, String scheduleId) async {
    try {
      await _col(parentUid).doc(scheduleId).delete();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }
}
