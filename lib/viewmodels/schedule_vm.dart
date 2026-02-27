import 'package:flutter/material.dart';
import 'package:kid_manager/views/parent/schedule/schedule_screen.dart';
import '../models/schedule.dart';
import '../repositories/schedule_repository.dart';
import 'auth_vm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleRepository _repo;
  final AuthVM _authVM;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ScheduleViewModel(this._repo, this._authVM);

  int _loadToken = 0;

  // ======================
  // STATE
  // ======================

  /// tháng đang focus (để load calendar)
  DateTime focusedMonth = DateTime.now();

  /// ngày đang chọn
  DateTime selectedDate = DateTime.now();

  /// child đang chọn
  String? selectedChildId;

  bool isLoading = false;
  String? error;

  /// Map dùng cho DOT calendar
  /// key = yyyy-mm-dd (normalized)
  Map<DateTime, List<Schedule>> monthSchedules = {};

  /// list hiển thị bên dưới
  List<Schedule> schedules = [];

  String get parentUid {
    final uid = _authVM.user?.uid;
    if (uid == null) {
      throw Exception('User chưa đăng nhập');
    }
    return uid;
  }

  String? _scheduleOwnerUid;

  String get scheduleOwnerUid {
    final uid = _scheduleOwnerUid;
    if (uid == null) throw Exception('Chưa set scheduleOwnerUid');
    return uid;
  }

  void setScheduleOwnerUid(String uid) {
    _scheduleOwnerUid = uid;
  }

  // ======================
  // PUBLIC API (UI gọi)
  // ======================

  /// chọn bé
  Future<void> setChild(String id) async {
  selectedChildId = id;

  final now = DateTime.now();
  selectedDate = _normalize(now);
  focusedMonth = DateTime(now.year, now.month, 1);

  await loadMonth();
}

  /// chọn ngày
  void setDate(DateTime date) {
    selectedDate = _normalize(date);
    schedules = monthSchedules[selectedDate] ?? [];
    notifyListeners();
  }

  /// bấm ← →
  Future<void> changeMonth(DateTime newDate) async {
  focusedMonth = DateTime(newDate.year, newDate.month, 1);
  selectedDate = DateTime(newDate.year, newDate.month, 1);
  await loadMonth();
}

  /// calendar dùng để vẽ dot
  bool hasSchedule(DateTime day) {
    return monthSchedules[_normalize(day)]?.isNotEmpty == true;
  }

  // ======================
  // LOAD DATA
  // ======================

  Future<void> loadMonth() async {
    if (selectedChildId == null) return;

    final token = ++_loadToken;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _repo.getSchedulesByMonth(
        parentUid: scheduleOwnerUid,
        childId: selectedChildId!,
        month: focusedMonth,
      );

      if (token != _loadToken) return;

      monthSchedules = _groupByDay(list);
      final key = _normalize(selectedDate);
      schedules = monthSchedules[key] ?? [];
    } catch (e) {
      if (token != _loadToken) return;
      error = e.toString();
    } finally {
      // ✅ luôn tắt loading nếu đây là request mới nhất
      if (token == _loadToken) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  // ======================
  // CRUD
  // ======================

  Future<void> addSchedule(Schedule s) async {
    await _repo.createSchedule(scheduleOwnerUid, s);
    await loadMonth();
  }

  Future<void> updateSchedule(Schedule s) async {
    await _repo.updateSchedule(scheduleOwnerUid, s);
    await loadMonth();
  }

  Future<void> deleteSchedule(String id) async {
  try {
    // optimistic UI
    schedules.removeWhere((e) => e.id == id);
    for (final entry in monthSchedules.entries) {
      entry.value.removeWhere((e) => e.id == id);
    }
    notifyListeners();

    await _repo.deleteSchedule(scheduleOwnerUid, id);

    // đảm bảo dot + list khớp tuyệt đối với server
    await loadMonth();
  } catch (e) {
    rethrow;
  }
}

  // ======================
  // HELPERS
  // ======================

  Map<DateTime, List<Schedule>> _groupByDay(List<Schedule> list) {
    final map = <DateTime, List<Schedule>>{};
    for (final s in list) {
      final key = _normalize(s.date);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  DateTime _normalize(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

// khi bind session mới (đổi user hoặc đổi owner), gọi hàm này để reset state và load lịch mới
Future<void> bindChildSession({
  required String childUid,
  required String ownerParentUid,
}) async {
  // nếu đổi user / đổi owner thì reset để tránh dính state cũ
  final needReset =
      selectedChildId != childUid || _scheduleOwnerUid != ownerParentUid;

  if (needReset) {
    resetForNewSession();
    setScheduleOwnerUid(ownerParentUid);
    await setChild(childUid); // setChild sẽ gọi loadMonth
  }
}

  // khi logout hoặc chuyển sang bé khác, reset hết state để tránh hiển thị nhầm
  void resetForNewSession() {
    _loadToken++; // invalidate các load cũ
    monthSchedules = {};
    schedules = [];
    error = null;
    isLoading = false;
    selectedChildId = null;

  // reset về today (hoặc giữ nguyên tùy bạn)
  final now = DateTime.now();
  selectedDate = _normalize(now);
  focusedMonth = DateTime(now.year, now.month, 1);

  notifyListeners();
}

}