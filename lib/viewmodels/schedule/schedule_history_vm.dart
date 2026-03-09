import 'package:flutter/material.dart';
import '../../models/schedule_history.dart';
import '../../repositories/schedule_repository.dart';
import '../auth_vm.dart';

class ScheduleHistoryViewModel extends ChangeNotifier {
  final ScheduleRepository _repo;
  final AuthVM _authVM;

  ScheduleHistoryViewModel(this._repo, this._authVM);

  bool isLoading = false;
  String? error;
  List<ScheduleHistory> histories = [];

  String? _scheduleOwnerUid;

  String get scheduleOwnerUid {
    final uid = _scheduleOwnerUid;
    if (uid == null) throw Exception('Chưa set scheduleOwnerUid');
    return uid;
  }

  void setScheduleOwnerUid(String uid) {
    _scheduleOwnerUid = uid;
  }

  String get parentUid {
    final uid = _authVM.user?.uid;
    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }
    return uid;
  }

  Future<void> loadHistories({
    required String parentUid,
    required String scheduleId,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      histories = await _repo.getScheduleHistories(
        parentUid: parentUid,
        scheduleId: scheduleId,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreHistory({
    required String parentUid,
    required String scheduleId,
    required String historyId,
  }) async {
    await _repo.restoreScheduleFromHistory(
      parentUid: parentUid,
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