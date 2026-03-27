import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/services/location/device_time_zone_service.dart';
import 'package:kid_manager/services/location/location_day_key_resolver.dart';
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
    this.childTimeZone,
    LocationDayKeyResolver? dayKeyResolver,
  }) : _dayKeyResolver = dayKeyResolver ?? LocationDayKeyResolver(),
       _selectedDay = _dayOnly(DateTime.now());

  static const int _initialVisibleRecentHourGroups = 3;
  static const int _loadMoreRecentHourGroups = 2;

  final ParentLocationVm _parentLocationVm;
  final String childId;
  final String? childTimeZone;
  final LocationDayKeyResolver _dayKeyResolver;

  DateTime _selectedDay;
  String? _selectedDayKey;
  int _rangeStartMinute = 0;
  int _rangeEndMinute = (24 * 60) - 1;
  List<LocationData> _cachedHistory = const [];
  LocationData? _latest;
  LocationData? _selectedPoint;
  bool _historyLoaded = false;
  bool _showDots = false;
  int _visibleRecentHourGroups = _initialVisibleRecentHourGroups;
  int? _selectedFromTs;
  int? _selectedToTs;
  String? _currentLocalDayKey;
  int? _currentLocalMinuteOfDay;
  final Map<int, LocalTimeZoneParts> _localPartsByTimestamp = {};
  bool _disposed = false;

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime get selectedDay => _selectedDay;
  List<LocationData> get cachedHistory => List.unmodifiable(_cachedHistory);
  List<LocationData> get orderedHistory => _cachedHistory.length < 2
      ? _cachedHistory
      : ([..._cachedHistory]
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
  List<LocationData> get recentHistoryNewestFirst =>
      orderedHistory.reversed.toList(growable: false);
  LocationData? get latest => _latest;
  LocationData? get selectedPoint => _selectedPoint;
  bool get historyLoaded => _historyLoaded;
  bool get showDots => _showDots;
  bool get isToday =>
      (_selectedDayKey ?? _dayKeyResolver.localDayKeyFromDate(_selectedDay)) ==
      (_currentLocalDayKey ??
          _dayKeyResolver.localDayKeyFromDate(DateTime.now()));
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
      recentHourGroups
          .take(visibleRecentHourGroupCount)
          .toList(growable: false);

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

  int get selectedFromTs => _selectedFromTs ?? 0;
  int get selectedToTs => _selectedToTs ?? 0;

  bool get rangeIncludesNow {
    if (!isToday) return false;
    final currentMinute = _currentLocalMinuteOfDay;
    if (currentMinute == null) {
      return false;
    }
    return currentMinute >= _rangeStartMinute &&
        currentMinute <= _rangeEndMinute;
  }

  DateTime get currentLocalDay => _currentLocalDayKey == null
      ? _dayOnly(DateTime.now())
      : _dayKeyResolver.parseLocalDayKey(_currentLocalDayKey!);

  bool isTsInSelectedRange(int timestamp) =>
      timestamp >= selectedFromTs && timestamp <= selectedToTs;

  String minuteLabel(int minuteOfDay) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> preloadToday() async {
    final today = await _resolveToday();
    await _loadHistory(today);
  }

  Future<void> loadForDay(DateTime day) async {
    await _loadHistory(_dayOnly(day));
  }

  Future<void> applyTimeWindow(int startMinute, int endMinute) async {
    final normalizedStart = startMinute.clamp(0, (24 * 60) - 1).toInt();
    final normalizedEnd = endMinute
        .clamp(normalizedStart, (24 * 60) - 1)
        .toInt();

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
    if (!_localPartsByTimestamp.containsKey(point.timestamp)) {
      _cacheLocalParts([point.timestamp], notifyAfter: true);
    }
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

  void _resetRecentHourGroupsVisibility() {
    _visibleRecentHourGroups = _initialVisibleRecentHourGroups;
  }

  List<ChildDetailMapRecentHourGroup> _groupPointsByHour(
    List<LocationData> points,
  ) {
    if (points.isEmpty) return const [];

    final groups = <ChildDetailMapRecentHourGroup>[];
    for (final point in points) {
      final label = hourBucketLabelForTimestamp(point.timestamp);
      if (groups.isEmpty || groups.last.label != label) {
        groups.add(
          ChildDetailMapRecentHourGroup(label: label, points: [point]),
        );
      } else {
        groups.last.points.add(point);
      }
    }
    return groups;
  }

  String _hourBucketLabel(int hour) {
    final value = hour.toString().padLeft(2, '0');
    return '$value:00 - $value:59';
  }

  String hourBucketLabelForTimestamp(int timestamp) {
    final parts = _localPartsByTimestamp[timestamp];
    if (parts != null) {
      return _hourBucketLabel(parts.hour);
    }
    final fallback = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return _hourBucketLabel(fallback.hour);
  }

  String formatTimeLabelForTimestamp(
    int timestamp, {
    bool includeSeconds = false,
  }) {
    final parts = _localPartsByTimestamp[timestamp];
    if (parts != null) {
      final hh = parts.hour.toString().padLeft(2, '0');
      final mm = parts.minute.toString().padLeft(2, '0');
      if (!includeSeconds) {
        return '$hh:$mm';
      }
      final ss = parts.second.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }

    final fallback = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hh = fallback.hour.toString().padLeft(2, '0');
    final mm = fallback.minute.toString().padLeft(2, '0');
    if (!includeSeconds) {
      return '$hh:$mm';
    }
    final ss = fallback.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  String formatDateLabelForTimestamp(int timestamp) {
    final parts = _localPartsByTimestamp[timestamp];
    if (parts != null) {
      return '${parts.day.toString().padLeft(2, '0')}/'
          '${parts.month.toString().padLeft(2, '0')}/'
          '${parts.year}';
    }

    final fallback = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${fallback.day.toString().padLeft(2, '0')}/'
        '${fallback.month.toString().padLeft(2, '0')}/'
        '${fallback.year}';
  }

  String formatFullLabelForTimestamp(int timestamp) {
    return '${formatDateLabelForTimestamp(timestamp)}  '
        '${formatTimeLabelForTimestamp(timestamp)}';
  }

  Future<void> _cacheLocalParts(
    Iterable<int> timestamps, {
    bool notifyAfter = false,
  }) async {
    final unresolved = timestamps
        .where(
          (timestamp) =>
              timestamp > 0 && !_localPartsByTimestamp.containsKey(timestamp),
        )
        .toSet();
    if (unresolved.isEmpty) {
      return;
    }

    final timeZone = await _resolvedTimeZone();
    final entries = await Future.wait(
      unresolved.map((timestamp) async {
        final parts = await _dayKeyResolver.localPartsForTimestamp(
          timestampMs: timestamp,
          timeZone: timeZone,
        );
        return MapEntry(timestamp, parts);
      }),
    );

    for (final entry in entries) {
      _localPartsByTimestamp[entry.key] = entry.value;
    }
    if (notifyAfter && !_disposed) {
      notifyListeners();
    }
  }

  Future<String> _resolvedTimeZone() {
    return _dayKeyResolver.normalizeTimeZone(childTimeZone);
  }

  Future<DateTime> _resolveToday() async {
    final timeZone = await _resolvedTimeZone();
    final nowParts = await _dayKeyResolver.localPartsForTimestamp(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      timeZone: timeZone,
    );
    _currentLocalDayKey = nowParts.dayKey;
    _currentLocalMinuteOfDay = nowParts.minuteOfDay;
    return _dayKeyResolver.parseLocalDayKey(nowParts.dayKey);
  }

  Future<void> _refreshSelectedRange(DateTime dayOnly) async {
    final timeZone = await _resolvedTimeZone();
    final range = await _dayKeyResolver.utcRangeForLocalDay(
      day: dayOnly,
      timeZone: timeZone,
      startMinuteOfDay: _rangeStartMinute,
      endMinuteOfDay: _rangeEndMinute,
    );
    _selectedFromTs = range.fromTs;
    _selectedToTs = range.toTs;
    _selectedDayKey = _dayKeyResolver.localDayKeyFromDate(dayOnly);

    final nowParts = await _dayKeyResolver.localPartsForTimestamp(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      timeZone: timeZone,
    );
    _currentLocalDayKey = nowParts.dayKey;
    _currentLocalMinuteOfDay = nowParts.minuteOfDay;
  }

  Future<void> _loadHistory(DateTime dayOnly) async {
    _historyLoaded = false;
    _resetRecentHourGroupsVisibility();
    notifyListeners();

    await _refreshSelectedRange(dayOnly);

    final history = await _parentLocationVm.loadLocationHistoryByDay(
      childId,
      dayOnly,
      fromTs: _selectedFromTs,
      toTs: _selectedToTs,
      startMinuteOfDay: _rangeStartMinute,
      endMinuteOfDay: _rangeEndMinute,
    );
    await _cacheLocalParts(
      history.expand((point) sync* {
        yield point.timestamp;
        if (point.gapStartTimestamp != null) {
          yield point.gapStartTimestamp!;
        }
        if (point.gapEndTimestamp != null) {
          yield point.gapEndTimestamp!;
        }
      }),
    );

    _selectedDay = dayOnly;
    _cachedHistory = history;
    _selectedPoint = null;
    _latest = history.isNotEmpty ? history.last : null;
    _historyLoaded = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
