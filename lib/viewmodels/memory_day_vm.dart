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

  // ==========================
  // TOKEN TÁCH RIÊNG
  // ==========================
  int _monthToken = 0;
  int _allToken = 0;

  DateTime focusedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String? error;

  Map<DateTime, List<MemoryDay>> monthMemories = {};
  List<MemoryDay> memoriesOfSelectedDay = [];

  List<MemoryDay> allMemories = [];
  bool isAllLoading = false;
  String? allError;

  DateTime _normalize(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  // ==========================
  // RESET KHI ĐỔI SESSION
  // ==========================
  void resetForNewSession() {
    _monthToken++;
    _allToken++;

    monthMemories = {};
    memoriesOfSelectedDay = [];
    allMemories = [];
    error = null;
    allError = null;
    isLoading = false;
    isAllLoading = false;

    notifyListeners();
  }

  void setOwnerUid(String uid) {
    if (_ownerUid == uid) return;
    _ownerUid = uid;
    resetForNewSession();
  }

  void bindCalendarState({
    required DateTime focusedMonth,
    required DateTime selectedDate,
  }) {
    this.focusedMonth =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    this.selectedDate = _normalize(selectedDate);
  }

  bool hasMemory(DateTime day) {
    return monthMemories[_normalize(day)]?.isNotEmpty == true;
  }

  // ==========================
  // LOAD MONTH
  // ==========================
  Future<void> loadMonth() async {
    final uid = _ownerUid;
    if (uid == null) return;

    final token = ++_monthToken;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final list =
          await _repo.getByMonth(ownerParentUid: uid, month: focusedMonth);

      if (token != _monthToken) return;

      final filtered = list.where((m) {
        if (m.repeatYearly) return true;
        return m.date.year == focusedMonth.year;
      }).toList();

      monthMemories = _groupByDay(filtered);
      memoriesOfSelectedDay =
          monthMemories[_normalize(selectedDate)] ?? [];
    } catch (e) {
      if (token != _monthToken) return;
      error = e.toString();
    } finally {
      if (token == _monthToken) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Map<DateTime, List<MemoryDay>> _groupByDay(
      List<MemoryDay> list) {
    final map = <DateTime, List<MemoryDay>>{};
    for (final m in list) {
      final key = DateTime(
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
    memoriesOfSelectedDay =
        monthMemories[selectedDate] ?? [];
    notifyListeners();
  }

  Future<void> changeMonth(DateTime newMonth) async {
    focusedMonth =
        DateTime(newMonth.year, newMonth.month, 1);
    selectedDate =
        DateTime(newMonth.year, newMonth.month, 1);
    await loadMonth();
  }

  // ==========================
  // CRUD
  // ==========================
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

  // ==========================
  // LOAD ALL
  // ==========================
  Future<void> loadAll() async {
    final uid = _ownerUid;
    if (uid == null) return;

    final token = ++_allToken;

    isAllLoading = true;
    allError = null;
    notifyListeners();

    try {
      final list =
          await _repo.getAll(ownerParentUid: uid);

      if (token != _allToken) return;

      allMemories = list;
    } catch (e) {
      if (token != _allToken) return;
      allError = e.toString();
    } finally {
      if (token == _allToken) {
        isAllLoading = false;
        notifyListeners();
      }
    }
  }

  int daysUntilNextOccurrence(MemoryDay m) {
    final now = _normalize(DateTime.now());
    DateTime next =
        DateTime(now.year, m.month, m.day);

    if (next.isBefore(now)) {
      next =
          DateTime(now.year + 1, m.month, m.day);
    }

    if (!m.repeatYearly) {
      next = _normalize(m.date);
    }

    return next.difference(now).inDays;
  }
}