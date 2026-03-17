import 'package:flutter/material.dart';
import 'package:kid_manager/models/birthday_event.dart';
import 'package:kid_manager/repositories/birthday_repository.dart';

class BirthdayViewModel extends ChangeNotifier {
  BirthdayViewModel(this._repo);

  final BirthdayRepository _repo;

  String? _familyId;
  int _monthToken = 0;
  List<BirthdayEvent> _allBirthdays = const <BirthdayEvent>[];
  bool _hasLoadedFamilyData = false;

  DateTime focusedMonth = DateTime.now();
  DateTime selectedDate = DateTime.now();

  bool isLoading = false;
  String? error;

  Map<DateTime, List<BirthdayEvent>> monthBirthdays = {};
  List<BirthdayEvent> birthdaysOfSelectedDay = [];

  DateTime _normalize(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void resetForNewSession({bool clearFamilyId = true}) {
    _monthToken++;
    if (clearFamilyId) {
      _familyId = null;
    }
    _allBirthdays = const <BirthdayEvent>[];
    _hasLoadedFamilyData = false;
    monthBirthdays = {};
    birthdaysOfSelectedDay = [];
    error = null;
    isLoading = false;

    notifyListeners();
  }

  void setFamilyId(String familyId) {
    final normalized = familyId.trim();
    if (normalized.isEmpty || _familyId == normalized) return;
    _familyId = normalized;
    resetForNewSession(clearFamilyId: false);
  }

  void bindCalendarState({
    required DateTime focusedMonth,
    required DateTime selectedDate,
  }) {
    this.focusedMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    this.selectedDate = _normalize(selectedDate);
  }

  bool hasBirthday(DateTime day) {
    return monthBirthdays[_normalize(day)]?.isNotEmpty == true;
  }

  Future<void> loadMonth() async {
    final familyId = _familyId;
    if (familyId == null || familyId.isEmpty) return;

    final token = ++_monthToken;
    final shouldFetchRemote = !_hasLoadedFamilyData;

    if (shouldFetchRemote) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      if (shouldFetchRemote) {
        _allBirthdays = await _repo.getFamilyBirthdays(familyId: familyId);
        _hasLoadedFamilyData = true;
      }
      if (token != _monthToken) return;

      _applyCurrentMonth();
    } catch (e) {
      if (token != _monthToken) return;
      error = e.toString();
    } finally {
      if (token == _monthToken) {
        if (shouldFetchRemote) {
          isLoading = false;
        }
        notifyListeners();
      }
    }
  }

  Future<void> refreshFamilyBirthdays({bool forceSync = false}) async {
    final familyId = _familyId;
    if (forceSync && familyId != null && familyId.isNotEmpty) {
      await _repo.syncFamilyMembers(familyId: familyId, force: true);
    }
    _hasLoadedFamilyData = false;
    await loadMonth();
  }

  Map<DateTime, List<BirthdayEvent>> _groupByDay(List<BirthdayEvent> items) {
    final map = <DateTime, List<BirthdayEvent>>{};

    for (final birthday in items) {
      final occurrence = birthday.occurrenceOnYear(focusedMonth.year);
      final key = _normalize(occurrence);
      map.putIfAbsent(key, () => <BirthdayEvent>[]).add(birthday);
    }

    for (final entry in map.entries) {
      entry.value.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    }

    return map;
  }

  void setDate(DateTime date) {
    selectedDate = _normalize(date);
    birthdaysOfSelectedDay = monthBirthdays[selectedDate] ?? [];
    notifyListeners();
  }

  Future<void> changeMonth(DateTime newMonth) async {
    focusedMonth = DateTime(newMonth.year, newMonth.month, 1);
    selectedDate = DateTime(newMonth.year, newMonth.month, 1);
    await loadMonth();
  }

  void _applyCurrentMonth() {
    final filtered = _allBirthdays.where((birthday) {
      return birthday.occurrenceOnYear(focusedMonth.year).month ==
          focusedMonth.month;
    }).toList();

    monthBirthdays = _groupByDay(filtered);
    birthdaysOfSelectedDay = monthBirthdays[_normalize(selectedDate)] ?? [];
  }
}
