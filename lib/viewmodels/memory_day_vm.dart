import 'package:flutter/material.dart';
import '../models/memory_day.dart';
import '../repositories/memory_day_repository.dart';

class MemoryDayViewModel extends ChangeNotifier {
  final MemoryDayRepository _repo;

  MemoryDayViewModel(this._repo);

  String? _ownerUid;
  String get ownerUid {
    final v = _ownerUid;
    if (v == null) throw Exception('Chưa set ownerUid');
    return v;
  }

  void setOwnerUid(String uid) {
    _ownerUid = uid;
  }

  int _loadToken = 0;

  DateTime focusedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String? error;

  /// key normalized yyyy-mm-dd
  Map<DateTime, List<MemoryDay>> monthMemories = {};

  /// list cho ngày đang chọn
  List<MemoryDay> memoriesOfSelectedDay = [];

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<MemoryDay> allMemories = [];
    bool isAllLoading = false;
    String? allError;

  void bindCalendarState({
    required DateTime focusedMonth,
    required DateTime selectedDate,
  }) {
    this.focusedMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    this.selectedDate = _normalize(selectedDate);
  }

  bool hasMemory(DateTime day) {
    return monthMemories[_normalize(day)]?.isNotEmpty == true;
  }

  Future<void> loadMonth() async {
    final uid = _ownerUid;
    if (uid == null) return;

    final token = ++_loadToken;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _repo.getByMonth(ownerParentUid: uid, month: focusedMonth);
      if (token != _loadToken) return;

      // Lọc: cùng năm hoặc repeatYearly
      final filtered = list.where((m) {
        if (m.repeatYearly) return true;
        return m.date.year == focusedMonth.year;
      }).toList();

      monthMemories = _groupByDay(filtered);
      memoriesOfSelectedDay = monthMemories[_normalize(selectedDate)] ?? [];
    } catch (e) {
      if (token != _loadToken) return;
      error = e.toString();
    } finally {
      if (token == _loadToken) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Map<DateTime, List<MemoryDay>> _groupByDay(List<MemoryDay> list) {
    final map = <DateTime, List<MemoryDay>>{};
    for (final m in list) {
      final key = DateTime(
        // Với repeatYearly: dùng year của focusedMonth để map đúng ô lịch đang xem
        m.repeatYearly ? focusedMonth.year : m.date.year,
        m.month,
        m.day,
      );
      final nk = _normalize(key);
      map.putIfAbsent(nk, () => []).add(m);
    }
    return map;
  }

  void setDate(DateTime date) {
    selectedDate = _normalize(date);
    memoriesOfSelectedDay = monthMemories[selectedDate] ?? [];
    notifyListeners();
  }

  Future<void> changeMonth(DateTime newMonth) async {
    focusedMonth = DateTime(newMonth.year, newMonth.month, 1);
    selectedDate = DateTime(newMonth.year, newMonth.month, 1);
    await loadMonth();
  }

  Future<void> addMemory(MemoryDay m) async {
  await _repo.create(ownerUid, m);
  await Future.wait([loadMonth(), loadAll()]);
}

Future<void> updateMemory(MemoryDay m) async {
  await _repo.update(ownerUid, m);
  await Future.wait([loadMonth(), loadAll()]);
}

Future<void> deleteMemory(String id) async {
  await _repo.delete(ownerUid, id);
  await Future.wait([loadMonth(), loadAll()]);
}

  /// Đếm ngược: còn X ngày tới lần tới (tính từ hôm nay)
  int daysUntilNextOccurrence(MemoryDay m) {
    final now = _normalize(DateTime.now());
    DateTime next = DateTime(now.year, m.month, m.day);

    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, m.month, m.day);
    }

    // Nếu không repeatYearly: dùng date thật
    if (!m.repeatYearly) {
      next = _normalize(m.date);
    }

    return next.difference(now).inDays;
  }

  Future<void> loadAll() async {
    final uid = _ownerUid;
    if (uid == null) return;

    final token = ++_loadToken;

    isAllLoading = true;
    allError = null;
    notifyListeners();

    try {
      final list = await _repo.getAll(ownerParentUid: uid);
      if (token != _loadToken) return;

      allMemories = list;
    } catch (e) {
      if (token != _loadToken) return;
      allError = e.toString();
    } finally {
      if (token == _loadToken) {
        isAllLoading = false;
        notifyListeners();
      }
    }
  }
}