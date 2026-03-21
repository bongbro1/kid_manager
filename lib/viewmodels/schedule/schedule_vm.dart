import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/schedule/schedule_notification_service.dart';

import '../../models/schedule.dart';
import '../../repositories/schedule_repository.dart';
import '../../utils/exceptions.dart';
import '../auth_vm.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleRepository _repo;
  final AuthVM _authVM;
  final ScheduleNotificationService _scheduleNotificationService;

  ScheduleViewModel(
    this._repo,
    this._authVM,
    this._scheduleNotificationService,
  );

  int _loadToken = 0;

  DateTime focusedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();
  String? selectedChildId;

  bool isLoading = false;
  String? error;

  Map<DateTime, List<Schedule>> monthSchedules = {};
  List<Schedule> schedules = [];

  String get actorUid {
    final uid = _authVM.user?.uid;
    if (uid == null) {
      throw Exception('USER_NOT_LOGGED_IN');
    }
    return uid;
  }

  String? _scheduleOwnerUid;

  String get scheduleOwnerUid {
    final uid = _scheduleOwnerUid;
    if (uid == null) throw Exception('SCHEDULE_OWNER_UID_NOT_SET');
    return uid;
  }

  bool get hasBoundScheduleOwner =>
      _scheduleOwnerUid != null && _scheduleOwnerUid!.trim().isNotEmpty;

  void setScheduleOwnerUid(String ownerParentUid) {
    // Phase 2: Handle owner mapping for guardian. The schedule owner path is
    // the parent namespace, which can differ from the logged-in actor uid.
    final normalized = ownerParentUid.trim();
    if (normalized.isEmpty) {
      _scheduleOwnerUid = null;
      return;
    }
    _scheduleOwnerUid = normalized;
  }

  Future<void> setChild(String id) async {
    selectedChildId = id;

    final now = DateTime.now();
    selectedDate = _normalize(now);
    focusedMonth = DateTime(now.year, now.month, 1);

    if (!hasBoundScheduleOwner) {
      notifyListeners();
      return;
    }

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
    if (selectedChildId == null || !hasBoundScheduleOwner) return;

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
      error = _cleanErrorMessage(e);
    } finally {
      if (token == _loadToken) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addSchedule(Schedule s, {required AppLocalizations l10n}) async {
    final overlapped = await _findOverlapOnDay(
      childId: s.childId,
      day: s.date,
      newStart: s.startAt,
      newEnd: s.endAt,
    );

    if (overlapped != null) {
      throw ScheduleOverlapException(
        l10n.scheduleOverlapConflictMessage(
          overlapped.title,
          _hhmm(overlapped.startAt),
          _hhmm(overlapped.endAt),
        ),
      );
    }

    final normalized = s.copyWith(parentUid: scheduleOwnerUid);
    final createdId = await _repo.createSchedule(scheduleOwnerUid, normalized);
    final createdSchedule = normalized.copyWith(id: createdId);

    await _safeNotifyCreated(createdSchedule);
    await loadMonth();
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> updateSchedule(
    Schedule s, {
    required AppLocalizations l10n,
  }) async {
    final overlapped = await _findOverlapOnDay(
      childId: s.childId,
      day: s.date,
      newStart: s.startAt,
      newEnd: s.endAt,
      ignoreScheduleId: s.id,
    );

    if (overlapped != null) {
      throw ScheduleOverlapException(
        l10n.scheduleOverlapConflictMessage(
          overlapped.title,
          _hhmm(overlapped.startAt),
          _hhmm(overlapped.endAt),
        ),
      );
    }

    final normalized = s.copyWith(parentUid: scheduleOwnerUid);
    await _repo.updateSchedule(scheduleOwnerUid, normalized);
    await _safeNotifyUpdated(normalized);
    await loadMonth();
  }

  Future<void> deleteSchedule(String id) async {
    final deletedSchedule = _findScheduleById(id);

    try {
      schedules.removeWhere((e) => e.id == id);
      for (final entry in monthSchedules.entries) {
        entry.value.removeWhere((e) => e.id == id);
      }
      notifyListeners();

      await _repo.deleteSchedule(scheduleOwnerUid, id);

      if (deletedSchedule != null) {
        unawaited(_safeNotifyDeleted(deletedSchedule));
      }
    } catch (e) {
      await loadMonth();
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
      await setChild(childUid);
    }
  }

  // khi logout hoặc chuyển sang bé khác, reset hết state để tránh hiển thị nhầm
  void resetForNewSession() {
    _loadToken++;
    _scheduleOwnerUid = null;
    monthSchedules = {};
    schedules = [];
    error = null;
    isLoading = false;
    selectedChildId = null;

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
    // Phase 2: Export always reads from parents/{scheduleOwnerUid}/..., even
    // when the current actor is a guardian.
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final endExclusive = DateTime(toDate.year, toDate.month, toDate.day + 1);

    final list = await _repo.getSchedulesByRange(
      parentUid: scheduleOwnerUid,
      childId: childId,
      start: start,
      end: endExclusive,
    );

    list.sort((a, b) {
      final dateCmp = DateTime(
        a.date.year,
        a.date.month,
        a.date.day,
      ).compareTo(DateTime(b.date.year, b.date.month, b.date.day));
      if (dateCmp != 0) return dateCmp;
      return a.startAt.compareTo(b.startAt);
    });

    return list;
  }

  Future<void> _safeNotifyCreated(Schedule schedule) async {
    try {
      await _scheduleNotificationService.notifyCreated(
        actorUid: actorUid,
        scheduleOwnerUid: scheduleOwnerUid,
        schedule: schedule,
      );
    } catch (e) {
      debugPrint('[SCHEDULE_NOTIFY][created] $e');
    }
  }

  Future<void> _safeNotifyUpdated(Schedule schedule) async {
    try {
      await _scheduleNotificationService.notifyUpdated(
        actorUid: actorUid,
        scheduleOwnerUid: scheduleOwnerUid,
        schedule: schedule,
      );
    } catch (e) {
      debugPrint('[SCHEDULE_NOTIFY][updated] $e');
    }
  }

  Future<void> _safeNotifyDeleted(Schedule schedule) async {
    try {
      await _scheduleNotificationService.notifyDeleted(
        actorUid: actorUid,
        scheduleOwnerUid: scheduleOwnerUid,
        schedule: schedule,
      );
    } catch (e) {
      debugPrint('[SCHEDULE_NOTIFY][deleted] $e');
    }
  }

  Schedule? _findScheduleById(String id) {
    for (final s in schedules) {
      if (s.id == id) return s;
    }

    for (final entry in monthSchedules.entries) {
      for (final s in entry.value) {
        if (s.id == id) return s;
      }
    }
    return null;
  }

  Future<void> openFromNotification({
    required String ownerParentUid,
    required String childId,
    required DateTime date,
  }) async {
    _loadToken++;

    setScheduleOwnerUid(ownerParentUid);
    selectedChildId = childId;

    focusedMonth = DateTime(date.year, date.month, 1);
    selectedDate = _normalize(date);

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _repo.getSchedulesByMonth(
        parentUid: scheduleOwnerUid,
        childId: childId,
        month: focusedMonth,
      );

      monthSchedules = _groupByDay(list);
      schedules = monthSchedules[selectedDate] ?? [];
    } catch (e) {
      error = _cleanErrorMessage(e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}

extension _TimeOverlap on ScheduleViewModel {
  bool _isOverlapping(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
  }

  Future<Schedule?> _findOverlapOnDay({
    required String childId,
    required DateTime day,
    required DateTime newStart,
    required DateTime newEnd,
    String? ignoreScheduleId,
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
