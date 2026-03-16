import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';

class ChildDetailMapVm extends ChangeNotifier {
  ChildDetailMapVm(
    this._parentLocationVm, {
    required this.childId,
  }) : _selectedDay = _dayOnly(DateTime.now());

  static const Duration _trackingTzOffset = Duration(hours: 7);

  final ParentLocationVm _parentLocationVm;
  final String childId;

  DateTime _selectedDay;
  int _rangeStartMinute = 0;
  int _rangeEndMinute = (24 * 60) - 1;
  List<LocationData> _cachedHistory = const [];
  LocationData? _latest;
  LocationData? _selectedPoint;
  bool _historyLoaded = false;
  bool _showDots = false;

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime get selectedDay => _selectedDay;
  List<LocationData> get cachedHistory => List.unmodifiable(_cachedHistory);
  LocationData? get latest => _latest;
  LocationData? get selectedPoint => _selectedPoint;
  bool get historyLoaded => _historyLoaded;
  bool get showDots => _showDots;
  bool get isToday => _dayOnly(_selectedDay) == _dayOnly(DateTime.now());
  bool get isFullDayRange =>
      _rangeStartMinute == 0 && _rangeEndMinute == (24 * 60) - 1;
  int get rangeStartMinute => _rangeStartMinute;
  int get rangeEndMinute => _rangeEndMinute;
  String get rangeLabel => isFullDayRange
      ? 'Ca ngay'
      : '${minuteLabel(_rangeStartMinute)} - ${minuteLabel(_rangeEndMinute)}';

  int get selectedFromTs => _fromTsForDay(_selectedDay);
  int get selectedToTs => _toTsForDay(_selectedDay);

  bool get rangeIncludesNow {
    if (!isToday) return false;
    final nowTs = DateTime.now().millisecondsSinceEpoch;
    return nowTs >= selectedFromTs && nowTs <= selectedToTs;
  }

  bool isTsInSelectedRange(int timestamp) =>
      timestamp >= selectedFromTs && timestamp <= selectedToTs;

  String minuteLabel(int minuteOfDay) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> preloadToday() async {
    await _loadHistory(_dayOnly(DateTime.now()));
  }

  Future<void> loadForDay(DateTime day) async {
    await _loadHistory(_dayOnly(day));
  }

  Future<void> applyTimeWindow(int startMinute, int endMinute) async {
    final normalizedStart = startMinute.clamp(0, (24 * 60) - 1).toInt();
    final normalizedEnd = endMinute.clamp(normalizedStart, (24 * 60) - 1).toInt();

    _rangeStartMinute = normalizedStart;
    _rangeEndMinute = normalizedEnd;
    _selectedPoint = null;
    _historyLoaded = false;
    notifyListeners();

    await _loadHistory(_selectedDay);
  }

  void toggleDots() {
    _showDots = !_showDots;
    notifyListeners();
  }

  void setSelectedPoint(LocationData? point) {
    _selectedPoint = point;
    notifyListeners();
  }

  void clearSelectedPoint() {
    if (_selectedPoint == null) return;
    _selectedPoint = null;
    notifyListeners();
  }

  void appendRealtime(LocationData point) {
    if (!isTsInSelectedRange(point.timestamp)) {
      return;
    }

    _latest = point;
    if (_cachedHistory.isEmpty ||
        _cachedHistory.last.timestamp != point.timestamp) {
      _cachedHistory = [..._cachedHistory, point];
    }
    notifyListeners();
  }

  DateTime _trackingDateTimeForMinute(DateTime day, int minuteOfDay) {
    final dayStartUtc = DateTime.utc(day.year, day.month, day.day)
        .subtract(_trackingTzOffset);
    return dayStartUtc.add(Duration(minutes: minuteOfDay));
  }

  int _fromTsForDay(DateTime day) =>
      _trackingDateTimeForMinute(day, _rangeStartMinute)
          .millisecondsSinceEpoch;

  int _toTsForDay(DateTime day) =>
      _trackingDateTimeForMinute(day, _rangeEndMinute)
          .add(const Duration(seconds: 59, milliseconds: 999))
          .millisecondsSinceEpoch;

  Future<void> _loadHistory(DateTime dayOnly) async {
    _historyLoaded = false;
    notifyListeners();

    final history = await _parentLocationVm.loadLocationHistoryByDay(
      childId,
      dayOnly,
      fromTs: _fromTsForDay(dayOnly),
      toTs: _toTsForDay(dayOnly),
    );

    _selectedDay = dayOnly;
    _cachedHistory = history;
    _selectedPoint = null;
    _latest = history.isNotEmpty ? history.last : null;
    _historyLoaded = true;
    notifyListeners();
  }
}
