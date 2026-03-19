import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';

class ChildDetailMapRecentHourGroup {
  final String label;
  final List<LocationData> points;

  const ChildDetailMapRecentHourGroup({
    required this.label,
    required this.points,
  });
}

class ChildDetailMapVm extends ChangeNotifier {
  ChildDetailMapVm(
    this._parentLocationVm, {
    required this.childId,
  }) : _selectedDay = _dayOnly(DateTime.now());

  static const Duration _trackingTzOffset = Duration(hours: 7);
  static const int _initialVisibleRecentHourGroups = 3;
  static const int _loadMoreRecentHourGroups = 2;

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
  int _visibleRecentHourGroups = _initialVisibleRecentHourGroups;

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime get selectedDay => _selectedDay;
  List<LocationData> get cachedHistory => List.unmodifiable(_cachedHistory);
  List<LocationData> get orderedHistory => _cachedHistory.length < 2
      ? _cachedHistory
      : ([..._cachedHistory]..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
  List<LocationData> get recentHistoryNewestFirst =>
      orderedHistory.reversed.toList(growable: false);
  LocationData? get latest => _latest;
  LocationData? get selectedPoint => _selectedPoint;
  bool get historyLoaded => _historyLoaded;
  bool get showDots => _showDots;
  bool get isToday => _dayOnly(_selectedDay) == _dayOnly(DateTime.now());
  bool get isFullDayRange =>
      _rangeStartMinute == 0 && _rangeEndMinute == (24 * 60) - 1;
  int get rangeStartMinute => _rangeStartMinute;
  int get rangeEndMinute => _rangeEndMinute;
  List<ChildDetailMapRecentHourGroup> get recentHourGroups =>
      _groupPointsByHour(recentHistoryNewestFirst);
  int get visibleRecentHourGroupCount {
    final total = recentHourGroups.length;
    if (_visibleRecentHourGroups < 0) return 0;
    if (_visibleRecentHourGroups > total) return total;
    return _visibleRecentHourGroups;
  }

  List<ChildDetailMapRecentHourGroup> get visibleRecentHourGroups =>
      recentHourGroups.take(visibleRecentHourGroupCount).toList(growable: false);

  bool get hasMoreRecentHourGroups =>
      visibleRecentHourGroupCount < recentHourGroups.length;

  String get remainingRecentHourGroupsLabel {
    final remaining = recentHourGroups.length - visibleRecentHourGroupCount;
    final nextLoad = remaining < _loadMoreRecentHourGroups
        ? remaining
        : _loadMoreRecentHourGroups;
    return nextLoad == 1 ? '1 khung gi\u1EDD' : '$nextLoad khung gi\u1EDD';
  }

  String get rangeLabel => isFullDayRange
      ? 'C\u1EA3 ng\u00E0y'
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
    _resetRecentHourGroupsVisibility();
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

  void loadMoreRecentHourGroups() {
    final total = recentHourGroups.length;
    if (_visibleRecentHourGroups >= total) return;
    _visibleRecentHourGroups += _loadMoreRecentHourGroups;
    if (_visibleRecentHourGroups > total) {
      _visibleRecentHourGroups = total;
    }
    notifyListeners();
  }

  void showAllRecentHourGroups() {
    final total = recentHourGroups.length;
    if (_visibleRecentHourGroups == total) return;
    _visibleRecentHourGroups = total;
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

  void _resetRecentHourGroupsVisibility() {
    _visibleRecentHourGroups = _initialVisibleRecentHourGroups;
  }

  List<ChildDetailMapRecentHourGroup> _groupPointsByHour(
    List<LocationData> points,
  ) {
    if (points.isEmpty) return const [];

    final groups = <ChildDetailMapRecentHourGroup>[];
    for (final point in points) {
      final label = _hourBucketLabel(point.dateTime);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(ChildDetailMapRecentHourGroup(label: label, points: [point]));
      } else {
        groups.last.points.add(point);
      }
    }
    return groups;
  }

  String _hourBucketLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    return '$hour:00 - $hour:59';
  }

  Future<void> _loadHistory(DateTime dayOnly) async {
    _historyLoaded = false;
    _resetRecentHourGroupsVisibility();
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
