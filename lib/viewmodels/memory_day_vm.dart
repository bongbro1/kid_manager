import 'dart:async';

import 'package:flutter/material.dart';

import '../models/memory_day.dart';
import '../repositories/memory_day_repository.dart';
import '../services/memory_day/memory_day_reminder_sync_service.dart';
import '../services/schedule/schedule_notification_service.dart';
import '../viewmodels/auth_vm.dart';

class MemoryDayViewModel extends ChangeNotifier {
  MemoryDayViewModel(
    this._repo,
    this._authVm,
    this._notify,
    this._reminderSync,
  );

  final MemoryDayRepository _repo;
  final AuthVM _authVm;
  final ScheduleNotificationService _notify;
  final MemoryDayReminderSyncService _reminderSync;

  String? _ownerUid;

  String get ownerUid {
    final value = _ownerUid;
    if (value == null) {
      throw Exception('Owner uid is not set');
    }
    return value;
  }

  String? get _actorUid => _authVm.user?.uid;

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

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void resetForNewSession({bool clearOwnerUid = true}) {
    _monthToken++;
    _allToken++;
    if (clearOwnerUid) {
      _ownerUid = null;
    }

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
    // Phase 2: Handle owner mapping for guardian. Memory Day data always lives
    // under the resolved parent owner namespace.
    final normalized = uid.trim();
    if (normalized.isEmpty || _ownerUid == normalized) return;
    _ownerUid = normalized;
    resetForNewSession(clearOwnerUid: false);
  }

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

    final token = ++_monthToken;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _repo.getByMonth(
        ownerParentUid: uid,
        month: focusedMonth,
      );

      if (token != _monthToken) return;

      final filtered = list.where((memory) {
        if (memory.repeatYearly) return true;
        return memory.date.year == focusedMonth.year;
      }).toList();

      monthMemories = _groupByDay(filtered);
      memoriesOfSelectedDay = monthMemories[_normalize(selectedDate)] ?? [];
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

  Map<DateTime, List<MemoryDay>> _groupByDay(List<MemoryDay> list) {
    final map = <DateTime, List<MemoryDay>>{};
    for (final memory in list) {
      final key = DateTime(
        memory.repeatYearly ? focusedMonth.year : memory.date.year,
        memory.month,
        memory.day,
      );
      final normalizedKey = _normalize(key);
      map.putIfAbsent(normalizedKey, () => []).add(memory);
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

  Future<void> addMemory(MemoryDay memory) async {
    final persisted = await _repo.create(ownerUid, memory);
    await Future.wait([loadMonth(), loadAll()]);

    unawaited(_safeSyncReminder(persisted));

    final actorUid = _actorUid;
    if (actorUid != null && actorUid.isNotEmpty) {
      try {
        await _notify.notifyMemoryDayCreated(
          actorUid: actorUid,
          ownerParentUid: ownerUid,
          memoryDay: persisted,
        );
      } catch (e) {
        debugPrint('[MEMORY_DAY_VM] notify created failed: $e');
      }
    }
  }

  Future<void> updateMemory(MemoryDay memory) async {
    await _repo.update(ownerUid, memory);
    await Future.wait([loadMonth(), loadAll()]);

    unawaited(_safeSyncReminder(memory));

    final actorUid = _actorUid;
    if (actorUid != null && actorUid.isNotEmpty) {
      try {
        await _notify.notifyMemoryDayUpdated(
          actorUid: actorUid,
          ownerParentUid: ownerUid,
          memoryDay: memory,
        );
      } catch (e) {
        debugPrint('[MEMORY_DAY_VM] notify updated failed: $e');
      }
    }
  }

  Future<void> deleteMemory(String id) async {
    final existing =
        _findMemoryById(id) ??
        await _repo.getById(ownerParentUid: ownerUid, id: id);

    debugPrint(
      '[MEMORY_DAY_VM] deleteMemory id=$id existing=${existing?.title} ownerUid=$ownerUid actorUid=$_actorUid',
    );

    try {
      _removeMemoryLocally(id);
      await _repo.delete(ownerUid, id);
      unawaited(_safeDeleteReminder(id));

      final actorUid = _actorUid;
      if (existing != null && actorUid != null && actorUid.isNotEmpty) {
        unawaited(
          _notify
              .notifyMemoryDayDeleted(
                actorUid: actorUid,
                ownerParentUid: ownerUid,
                memoryDay: existing,
              )
              .catchError((Object e) {
                debugPrint('[MEMORY_DAY_VM] notify deleted failed: $e');
              }),
        );
      }
    } catch (e) {
      await Future.wait([loadMonth(), loadAll()]);
      rethrow;
    }
  }

  Future<void> loadAll() async {
    final uid = _ownerUid;
    if (uid == null) return;

    final token = ++_allToken;

    isAllLoading = true;
    allError = null;
    notifyListeners();

    try {
      final list = await _repo.getAll(ownerParentUid: uid);

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

  int daysUntilNextOccurrence(MemoryDay memory) {
    final now = _normalize(DateTime.now());
    DateTime next = DateTime(now.year, memory.month, memory.day);

    if (next.isBefore(now)) {
      next = DateTime(now.year + 1, memory.month, memory.day);
    }

    if (!memory.repeatYearly) {
      next = _normalize(memory.date);
    }

    return next.difference(now).inDays;
  }

  MemoryDay? _findMemoryById(String id) {
    for (final memory in memoriesOfSelectedDay) {
      if (memory.id == id) return memory;
    }

    for (final memory in allMemories) {
      if (memory.id == id) return memory;
    }

    for (final entry in monthMemories.entries) {
      for (final memory in entry.value) {
        if (memory.id == id) return memory;
      }
    }

    return null;
  }

  void _removeMemoryLocally(String id) {
    memoriesOfSelectedDay.removeWhere((memory) => memory.id == id);
    allMemories.removeWhere((memory) => memory.id == id);

    for (final entry in monthMemories.entries) {
      entry.value.removeWhere((memory) => memory.id == id);
    }

    notifyListeners();
  }

  Future<void> _safeSyncReminder(MemoryDay memory) async {
    try {
      await _reminderSync.syncMemoryDay(
        ownerParentUid: ownerUid,
        memory: memory,
        actorUid: _actorUid,
      );
    } catch (e) {
      debugPrint(
        '[MEMORY_DAY_VM] reminder sync failed ownerUid=$ownerUid actorUid=$_actorUid error=$e',
      );
    }
  }

  Future<void> _safeDeleteReminder(String memoryId) async {
    try {
      await _reminderSync.deleteMemoryDay(
        ownerParentUid: ownerUid,
        memoryDayId: memoryId,
      );
    } catch (e) {
      debugPrint('[MEMORY_DAY_VM] reminder delete sync failed: $e');
    }
  }
}
