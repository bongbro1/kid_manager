import 'package:flutter/material.dart';

import '../../models/schedule_history.dart';
import '../../repositories/schedule_repository.dart';

class ScheduleHistoryViewModel extends ChangeNotifier {
  final ScheduleRepository _repo;

  ScheduleHistoryViewModel(this._repo);

  bool isLoading = false;
  String? error;
  List<ScheduleHistory> histories = [];

  String? _scheduleOwnerUid;

  String get scheduleOwnerUid {
    final uid = _scheduleOwnerUid;
    if (uid == null) throw Exception('SCHEDULE_OWNER_UID_NOT_SET');
    return uid;
  }

  void setScheduleOwnerUid(String ownerParentUid) {
    final normalized = ownerParentUid.trim();
    if (normalized.isEmpty) {
      _scheduleOwnerUid = null;
      return;
    }
    _scheduleOwnerUid = normalized;
  }

  Future<void> loadHistories({
    required String scheduleId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      // Phase 2: Handle owner mapping for guardian. History is loaded from the
      // resolved parent owner namespace, never from the actor uid.
      histories = await _repo.getScheduleHistories(
        parentUid: scheduleOwnerUid,
        scheduleId: scheduleId,
      );
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '').trim();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreHistory({
    required String scheduleId,
    required String historyId,
  }) async {
    // Phase 2: Restore must target parents/{scheduleOwnerUid}/... so guardian
    // works on the same history branch as the parent owner.
    await _repo.restoreScheduleFromHistory(
      parentUid: scheduleOwnerUid,
      scheduleId: scheduleId,
      historyId: historyId,
    );
  }

  void clear({bool notify = true}) {
    histories = [];
    error = null;
    isLoading = false;

    if (notify) {
      notifyListeners();
    }
  }
}
