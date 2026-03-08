import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../repositories/schedule_repository.dart';
import 'auth_vm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/exceptions.dart';

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
    // ✅ check overlap trước khi tạo
    final overlapped = await _findOverlapOnDay(
      childId: s.childId,
      day: s.date,
      newStart: s.startAt,
      newEnd: s.endAt,
    );

    if (overlapped != null) {
      throw ScheduleOverlapException(
        'Trùng với lịch "${overlapped.title}" '
        '(${_hhmm(overlapped.startAt)} - ${_hhmm(overlapped.endAt)}). '
        'Vui lòng chọn giờ khác.',
      );
    }

    await _repo.createSchedule(scheduleOwnerUid, s);
    await loadMonth();
  }

  // helper format
  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> updateSchedule(Schedule s) async {
    final overlapped = await _findOverlapOnDay(
      childId: s.childId,
      day: s.date,
      newStart: s.startAt,
      newEnd: s.endAt,
      ignoreScheduleId: s.id,
    );

    if (overlapped != null) {
      throw ScheduleOverlapException(
        'Trùng với lịch "${overlapped.title}" '
        '(${_hhmm(overlapped.startAt)} - ${_hhmm(overlapped.endAt)}). '
        'Vui lòng chọn giờ khác.',
      );
    }

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
    loadMonth(); // reload để đồng bộ lại UI nếu xóa thất bại
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

//xuất lịch theo khoảng thời gian (dùng cho export Excel)
  Future<List<Schedule>> getSchedulesForExport({
    required String childId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final endExclusive = DateTime(toDate.year, toDate.month, toDate.day + 1);

    final list = await _repo.getSchedulesByRange(
      parentUid: scheduleOwnerUid,
      childId: childId,
      start: start,
      end: endExclusive,
    );

    list.sort((a, b) {
      final dateCmp = DateTime(a.date.year, a.date.month, a.date.day)
          .compareTo(DateTime(b.date.year, b.date.month, b.date.day));
      if (dateCmp != 0) return dateCmp;
      return a.startAt.compareTo(b.startAt);
    });

    return list;
  }
}

// Extension để check overlap khi add/update schedule

extension _TimeOverlap on ScheduleViewModel {
  bool _isOverlapping(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
    // cho phép liền kề: end == start => KHÔNG overlap
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  Future<Schedule?> _findOverlapOnDay({
    required String childId,
    required DateTime day,
    required DateTime newStart,
    required DateTime newEnd,
    String? ignoreScheduleId, // dùng cho update
  }) async {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Lấy các schedule bắt đầu trong ngày (đủ đúng với rule hiện tại: schedule không qua ngày)
    final list = await _repo.getSchedulesByRange(
      parentUid: scheduleOwnerUid,
      childId: childId,
      start: dayStart,
      end: dayEnd,
    );

    for (final s in list) {
      if (ignoreScheduleId != null && s.id == ignoreScheduleId) continue;
      if (_isOverlapping(newStart, newEnd, s.startAt, s.endAt)) return s;
    }
    return null;
  }
}