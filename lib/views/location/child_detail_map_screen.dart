import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/features/map_engine/smooth/smooth_mover.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/views/parent/zones/child_zones_screen.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/features/map_engine/map_engine.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';

class ChildDetailMapScreen extends StatefulWidget {
  final String childId;
  const ChildDetailMapScreen({super.key, required this.childId});

  @override
  State<ChildDetailMapScreen> createState() => _ChildDetailMapScreenState();
}

class _ChildDetailMapScreenState extends State<ChildDetailMapScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _trackingTzOffset = Duration(hours: 7);

  MapEngine? _engine;
  StreamSubscription<LocationData>? _sub;

  List<LocationData> _cachedHistory = const [];
  LocationData? _latest;

  final SmoothMover _mover = SmoothMover(durationMs: 650);
  Timer? _animTick;
  Timer? _renderDebounce;
  DateTime _lastMapMatchAt = DateTime.fromMillisecondsSinceEpoch(0);
  AppLocalizations get l10n => AppLocalizations.of(context);

  late DateTime _selectedDay;
  int _rangeStartMinute = 0;
  int _rangeEndMinute = (24 * 60) - 1;
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool get _isToday => _dayOnly(_selectedDay) == _dayOnly(DateTime.now());
  bool get _isFullDayRange =>
      _rangeStartMinute == 0 && _rangeEndMinute == (24 * 60) - 1;

  bool _showDots = false;
  bool _historyLoaded = false;

  // -- animation controller cho bottom card ----------------------------------
  late final AnimationController _cardAnim;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  LocationData? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dayOnly(DateTime.now());

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _preloadToday();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animTick?.cancel();
    _renderDebounce?.cancel();
    _cardAnim.dispose();
    super.dispose();
  }

  // -- helpers ---------------------------------------------------------------
  Widget _buildSelectedPointCard(LocationData point) {
    final baseColor = _transportColor(point.transport);
    final icon = _transportIcon(point.transport);
    final stopDuration = _computeStopDuration(point);

    final summary = _buildPointSummary(point, stopDuration);
    final title = summary.$1;
    final subtitle = summary.$2;

    final isStart = _cachedHistory.isNotEmpty &&
        point.timestamp == _cachedHistory.first.timestamp;
    final isEnd = _cachedHistory.isNotEmpty &&
        point.timestamp == _cachedHistory.last.timestamp;

    final gpsLost = point.accuracy > 30;
    final gpsVeryBad = point.accuracy > 80;

    final displayColor = gpsLost
        ? const Color(0xFFC5221F)
        : baseColor;

    final statusBg = gpsLost
        ? const Color(0xFFFDE2E1)
        : displayColor.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: gpsLost
              ? Border.all(
            color: const Color(0xFFF28B82),
            width: 1.2,
          )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    gpsLost ? Icons.gps_off_rounded : icon,
                    color: displayColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: gpsLost
                              ? const Color(0xFFC5221F)
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedPoint = null),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isStart)
                  _tagChip(
                    l10n.childLocationTagStart,
                    const Color(0xFFDDF5E3),
                    const Color(0xFF188038),
                  ),
                if (isEnd)
                  _tagChip(
                    l10n.childLocationTagEnd,
                    const Color(0xFFFDE2E1),
                    const Color(0xFFC5221F),
                  ),
                _tagChip(
                  point.timeLabel,
                  const Color(0xFFF1F3F4),
                  const Color(0xFF5F6368),
                ),
                if (gpsVeryBad)
                  _tagChip(
                    l10n.childLocationTagGpsVeryWeak,
                    const Color(0xFFFCE8E6),
                    const Color(0xFFC5221F),
                  )
                else if (gpsLost)
                  _tagChip(
                    l10n.childLocationTagGpsLost,
                    const Color(0xFFFCE8E6),
                    const Color(0xFFC5221F),
                  )
                else
                  _tagChip(
                    _transportLabel(point.transport),
                    displayColor.withOpacity(0.12),
                    displayColor,
                  ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    label: l10n.childLocationStayedHereLabel,
                    value: gpsLost
                        ? l10n.childLocationStayedHereUnavailable
                        : _formatDuration(stopDuration),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoTile(
                    label: l10n.childLocationSpeedLabel,
                    value: gpsLost
                        ? l10n.childLocationSpeedUnavailable
                        : _speedLabel(point),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    label: l10n.childLocationGpsAccuracyLabel,
                    value: _accuracyLabel(point),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoTile(
                    label: l10n.childLocationMockGpsLabel,
                    value: point.isMock
                        ? l10n.childLocationMockGpsDetected
                        : l10n.childLocationNoLabel,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                l10n.childLocationTechnicalDetailsTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              children: [
                _detailRow(l10n.childLocationDetailFullTimeLabel, point.fullLabel),
                _detailRow(
                  l10n.childLocationDetailHeadingLabel,
                  '${point.heading.toStringAsFixed(0)}°',
                ),
                _detailRow(
                  l10n.childLocationDetailCoordinatesLabel,
                  '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                ),
                _detailRow(
                  l10n.childLocationDetailAccuracyLabel,
                  '${point.accuracy.toStringAsFixed(0)} m',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String get _rangeLabel => _isFullDayRange
      ? l10n.childLocationRangeAllDay
      : '${_minuteLabel(_rangeStartMinute)} - ${_minuteLabel(_rangeEndMinute)}';

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

  int get _selectedFromTs => _fromTsForDay(_selectedDay);

  int get _selectedToTs => _toTsForDay(_selectedDay);

  bool get _rangeIncludesNow {
    if (!_isToday) return false;
    final nowTs = DateTime.now().millisecondsSinceEpoch;
    return nowTs >= _selectedFromTs && nowTs <= _selectedToTs;
  }

  bool _isTsInSelectedRange(int timestamp) =>
      timestamp >= _selectedFromTs && timestamp <= _selectedToTs;

  String _minuteLabel(int minuteOfDay) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Duration _computeStopDuration(LocationData point) {
    if (_cachedHistory.isEmpty) return Duration.zero;

    final sorted = [..._cachedHistory]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final selectedIndex =
    sorted.indexWhere((e) => e.timestamp == point.timestamp);

    if (selectedIndex == -1) return Duration.zero;

    const double stopRadiusMeters = 30;
    const double movingSpeedThresholdKmh = 2.5;

    int startIndex = selectedIndex;
    int endIndex = selectedIndex;

    bool isStopPoint(LocationData a, LocationData center) {
      final distMeters = a.distanceTo(center) * 1000.0;
      return distMeters <= stopRadiusMeters &&
          a.speedKmh <= movingSpeedThresholdKmh;
    }

    while (startIndex > 0 &&
        isStopPoint(sorted[startIndex - 1], point)) {
      startIndex--;
    }

    while (endIndex < sorted.length - 1 &&
        isStopPoint(sorted[endIndex + 1], point)) {
      endIndex++;
    }

    final start = sorted[startIndex];
    final end = sorted[endIndex];

    final diffMs = end.timestamp - start.timestamp;
    if (diffMs <= 0) return Duration.zero;

    return Duration(milliseconds: diffMs);
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return l10n.childLocationDurationZeroMinutes;

    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return l10n.childLocationDurationHoursMinutes(hours, minutes);
    }
    if (minutes > 0) {
      return l10n.childLocationDurationMinutes(minutes);
    }
    return l10n.childLocationDurationSeconds(seconds);
  }

  IconData _transportIcon(TransportMode t) {
    switch (t) {
      case TransportMode.walking:
        return Icons.directions_walk_rounded;
      case TransportMode.bicycle:
        return Icons.directions_bike_rounded;
      case TransportMode.vehicle:
        return Icons.directions_car_rounded;
      case TransportMode.still:
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Widget _infoTile({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8EAED),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
  (String title, String subtitle) _buildPointSummary(
      LocationData point,
      Duration stopDuration,
      ) {
    final isStart = _cachedHistory.isNotEmpty &&
        point.timestamp == _cachedHistory.first.timestamp;
    final isEnd = _cachedHistory.isNotEmpty &&
        point.timestamp == _cachedHistory.last.timestamp;

    final gpsLost = point.accuracy > 30;
    final gpsVeryBad = point.accuracy > 80;
    final isStoppedLongEnough = stopDuration.inMinutes >= 3;

    if (gpsVeryBad) {
      return (
      l10n.childLocationGpsLostTitle,
      l10n.childLocationGpsVeryWeakSubtitle,
      );
    }

    if (gpsLost) {
      return (
      l10n.childLocationGpsLostTitle,
      l10n.childLocationGpsLostSubtitle(point.accuracy.toStringAsFixed(0)),
      );
    }

    if (isStoppedLongEnough) {
      if (isEnd && _isToday) {
        return (
        l10n.childLocationStoppedNowTitle,
        l10n.childLocationStoppedNowSubtitle(_formatDuration(stopDuration)),
        );
      }
      return (
      l10n.childLocationStoppedHereTitle,
      l10n.childLocationStoppedHereSubtitle(_formatDuration(stopDuration)),
      );
    }

    if (isStart) {
      return (
      _transportHeadline(point.transport),
      l10n.childLocationJourneyStartSubtitle,
      );
    }

    if (isEnd) {
      return (
      _transportHeadline(point.transport),
      _isToday
          ? l10n.childLocationUpdatedAt(point.timeLabel)
          : l10n.childLocationJourneyEndSubtitle,
      );
    }

    return (
    _transportHeadline(point.transport),
    l10n.childLocationPassedAt(point.timeLabel),
    );
  }

  String _transportHeadline(TransportMode t) {
    switch (t) {
      case TransportMode.walking:
        return l10n.childLocationHeadlineWalking;
      case TransportMode.bicycle:
        return l10n.childLocationHeadlineBicycle;
      case TransportMode.vehicle:
        return l10n.childLocationHeadlineVehicle;
      case TransportMode.still:
        return l10n.childLocationHeadlineStill;
      default:
        return l10n.childLocationHeadlineUnknown;
    }
  }

  String _speedLabel(LocationData point) {
    final kmh = point.speedKmh;
    if (kmh <= 1) return l10n.childLocationSpeedAlmostStill;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String _accuracyLabel(LocationData point) {
    final acc = point.accuracy.toStringAsFixed(0);

    if (point.accuracy > 80) return l10n.childLocationAccuracySevere;
    if (point.accuracy > 30) return l10n.childLocationAccuracyLost;
    if (point.accuracy <= 15) {
      return l10n.childLocationAccuracyGood(acc);
    }
    return l10n.childLocationAccuracyModerate(acc);
  }
  Color _transportColor(TransportMode t) {
    switch (t) {
      case TransportMode.walking:
        return const Color(0xFF34A853);
      case TransportMode.bicycle:
        return const Color(0xFF4285F4);
      case TransportMode.vehicle:
        return const Color(0xFFFF6D00);
      case TransportMode.still:
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF757575);
    }
  }

  String _transportLabel(TransportMode t) {
    switch (t) {
      case TransportMode.walking:
        return l10n.childLocationTransportWalking;
      case TransportMode.bicycle:
        return l10n.childLocationTransportBicycle;
      case TransportMode.vehicle:
        return l10n.childLocationTransportVehicle;
      case TransportMode.still:
        return l10n.childLocationTransportStill;
      default:
        return l10n.childLocationTransportUnknown;
    }
  }

  String _fmtDay(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  String _fmtTime(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  // -- core logic (unchanged) ------------------------------------------------

  void _startAnimTick() {
    _animTick ??= Timer.periodic(const Duration(milliseconds: 16), (_) async {
      if (!mounted || _engine == null) return;
      if (_mover.isAnimating) {
        final smoothed = _mover.current();
        await _engine!.updateChildDot(smoothed);
      }
    });
  }

  void _appendRealtime(LocationData loc) {
    if (!_isTsInSelectedRange(loc.timestamp)) {
      return;
    }
    if (_cachedHistory.isEmpty ||
        _cachedHistory.last.timestamp != loc.timestamp) {
      _cachedHistory = [..._cachedHistory, loc];
    }
  }

  Future<void> _toggleDots() async {
    setState(() => _showDots = !_showDots);
    await _engine?.setHistoryDotsVisible(_showDots);
  }

  Future<void> _preloadToday() async {
    final vm = context.read<ParentLocationVm>();
    final today = _dayOnly(DateTime.now());
    final history = await vm.loadLocationHistoryByDay(
      widget.childId,
      today,
      fromTs: _fromTsForDay(today),
      toTs: _toTsForDay(today),
    );
    if (!mounted) return;
    setState(() {
      _selectedDay = today;
      _cachedHistory = history;
      _historyLoaded = true;
      if (_cachedHistory.isNotEmpty) {
        _latest = _cachedHistory.last;
        _cardAnim.forward();
      }
    });
  }

  Future<void> _renderOnMap() async {
    final engine = _engine;
    if (!mounted || engine == null) return;
    engine.resetForNewHistory();
    if (_cachedHistory.isEmpty) {
      await engine.setHistoryDotsVisible(_showDots);
      if (_isToday && _rangeIncludesNow) {
        await _startRealtime();
      } else {
        await _sub?.cancel();
        _sub = null;
      }
      return;
    }
    await engine.loadHistory(_cachedHistory, context);
    await engine.setHistoryDotsVisible(_showDots);
    _lastMapMatchAt = DateTime.now();
    if (_isToday && _rangeIncludesNow) {
      await _startRealtime();
    } else {
      await _sub?.cancel();
      _sub = null;
    }
  }

  Future<void> _loadForDay(DateTime day) async {
    if (!mounted) return;
    final vm = context.read<ParentLocationVm>();
    final dayOnly = _dayOnly(day);
    setState(() {
      _historyLoaded = false;
    });
    if (dayOnly != _dayOnly(DateTime.now())) {
      await _sub?.cancel();
      _sub = null;
    }
    final history = await vm.loadLocationHistoryByDay(
      widget.childId,
      dayOnly,
      fromTs: _fromTsForDay(dayOnly),
      toTs: _toTsForDay(dayOnly),
    );
    if (!mounted) return;
    setState(() {
      _selectedDay = dayOnly;
      _cachedHistory = history;
      _selectedPoint = null;
      _historyLoaded = true;
      if (_cachedHistory.isNotEmpty) {
        _latest = _cachedHistory.last;
      } else {
        _latest = null;
      }
    });
    await _renderOnMap();
  }

  Future<void> _startRealtime() async {
    final vm = context.read<ParentLocationVm>();
    await _sub?.cancel();
    _sub = vm.watchChildLocation(widget.childId).listen((loc) async {
      if (!mounted || !_isToday) return;
      if (!_isTsInSelectedRange(loc.timestamp)) {
        await _sub?.cancel();
        _sub = null;
        return;
      }
      _latest = loc;
      _appendRealtime(loc);
      _mover.push(loc);
      _startAnimTick();
      _renderDebounce?.cancel();
      _renderDebounce = Timer(const Duration(milliseconds: 300), () async {
        if (!mounted || _engine == null) return;
        await _engine!.renderHistoryFast(_cachedHistory, context);
      });
      final now = DateTime.now();
      if (now.difference(_lastMapMatchAt) >= const Duration(seconds: 20) &&
          _cachedHistory.length >= 6) {
        _lastMapMatchAt = now;
        await _engine!.updateMatchedRouteIncremental(_cachedHistory, context);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _applyTimeWindow(int startMinute, int endMinute) async {
    final normalizedStart = startMinute.clamp(0, (24 * 60) - 1).toInt();
    final normalizedEnd = endMinute.clamp(normalizedStart, (24 * 60) - 1).toInt();

    setState(() {
      _rangeStartMinute = normalizedStart;
      _rangeEndMinute = normalizedEnd;
      _historyLoaded = false;
      _selectedPoint = null;
    });

    await _loadForDay(_selectedDay);
    if (!mounted) return;
    setState(() {
      _historyLoaded = true;
    });
  }

  Future<void> _pickTimeWindow() async {
    final selection = await showModalBottomSheet<_TimeWindowSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        var draftStart = _rangeStartMinute.toDouble();
        var draftEnd = _rangeEndMinute.toDouble();

        void applyPreset(StateSetter setSheetState, int start, int end) {
          setSheetState(() {
            draftStart = start.toDouble();
            draftEnd = end.toDouble();
          });
        }

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final startLabel = _minuteLabel(draftStart.round());
            final endLabel = _minuteLabel(draftEnd.round());

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.childLocationTimeWindowTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.childLocationTimeWindowSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RangePresetChip(
                          label: l10n.childLocationRangeAllDay,
                          selected: draftStart.round() == 0 &&
                              draftEnd.round() == (24 * 60) - 1,
                          onTap: () => applyPreset(
                            setSheetState,
                            0,
                            (24 * 60) - 1,
                          ),
                        ),
                        _RangePresetChip(
                          label: l10n.childLocationPresetMorning,
                          selected: draftStart.round() == 6 * 60 &&
                              draftEnd.round() == (11 * 60) + 59,
                          onTap: () => applyPreset(
                            setSheetState,
                            6 * 60,
                            (11 * 60) + 59,
                          ),
                        ),
                        _RangePresetChip(
                          label: l10n.childLocationPresetAfternoon,
                          selected: draftStart.round() == 12 * 60 &&
                              draftEnd.round() == (17 * 60) + 59,
                          onTap: () => applyPreset(
                            setSheetState,
                            12 * 60,
                            (17 * 60) + 59,
                          ),
                        ),
                        _RangePresetChip(
                          label: l10n.childLocationPresetEvening,
                          selected: draftStart.round() == 18 * 60 &&
                              draftEnd.round() == (23 * 60) + 59,
                          onTap: () => applyPreset(
                            setSheetState,
                            18 * 60,
                            (23 * 60) + 59,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8EAED)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SummaryChip(
                              label: l10n.commonStartLabel,
                              value: startLabel,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _SummaryChip(
                              label: l10n.commonEndLabel,
                              value: endLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RangeSlider(
                      values: RangeValues(draftStart, draftEnd),
                      min: 0,
                      max: ((24 * 60) - 1).toDouble(),
                      divisions: (24 * 4) - 1,
                      labels: RangeLabels(startLabel, endLabel),
                      onChanged: (values) {
                        setSheetState(() {
                          draftStart = values.start.roundToDouble();
                          draftEnd = values.end.roundToDouble();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(l10n.cancelButton),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(
                              _TimeWindowSelection(
                                startMinute: draftStart.round(),
                                endMinute: draftEnd.round(),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(l10n.applyButton),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selection == null) return;
    await _applyTimeWindow(selection.startMinute, selection.endMinute);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(ctx).colorScheme.primary,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    await _loadForDay(picked);
  }

  // -- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final latest = _latest;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(cs),
      body: Stack(
        children: [
          // -- Map fullscreen ----------------------------------------------
          AppMapView(
            onMapCreated: (_) {},
            onTapListener: (gesture) {
              _engine?.handleMapTap(gesture);
            },
            onStyleLoaded: (map) async {
              _engine = MapEngine(
                map,
                onHistoryPointSelected: (point) {
                  if (!mounted) return;
                  setState(() {
                    _selectedPoint = point;
                  });
                },
              );
              await _engine!.init();
              if (!_historyLoaded) {
                await _loadForDay(_dayOnly(DateTime.now()));
                return;
              }
              await _renderOnMap();
            },
          ),
          if (_selectedPoint == null && _historyLoaded && _cachedHistory.isEmpty)
            Positioned(
              left: 12,
              right: 68,
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
              child: _buildEmptyStateCard(),
            ),
          if (_selectedPoint != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: latest != null ? 108 : 16,
              child: _buildSelectedPointCard(_selectedPoint!),
            ),
          // -- Floating action row (dots + zones) --------------------------
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: _buildFabColumn(cs),
          ),

          // -- Bottom status card ------------------------------------------
          if (latest != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: _buildBottomCard(latest, cs),
                ),
              ),
            ),

          // -- Loading shimmer ---------------------------------------------
          if (!_historyLoaded)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.55),
              Colors.transparent,
            ],
          ),
        ),
      ),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isToday
                ? l10n.childLocationCurrentJourneyTitle
                : l10n.childLocationTravelHistoryTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            '${_fmtDay(_selectedDay)} - $_rangeLabel',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        _AppBarChip(
          icon: Icons.calendar_today_rounded,
          label: _isToday ? l10n.childLocationTodayLabel : _fmtDay(_selectedDay),
          onTap: _pickDay,
        ),
        const SizedBox(width: 8),
        _AppBarChip(
          icon: Icons.schedule_rounded,
          label: _rangeLabel,
          onTap: _pickTimeWindow,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFabColumn(ColorScheme cs) {
    return Column(
      spacing: 10,
      children: [
        // Toggle dots
        _MapFab(
          tooltip: _showDots
              ? l10n.childLocationTooltipHideDots
              : l10n.childLocationTooltipShowDots,
          icon: _showDots
              ? Icons.scatter_plot_rounded
              : Icons.scatter_plot_outlined,
          active: _showDots,
          onTap: _toggleDots,
        ),
        // Vùng an toàn
        _MapFab(
          tooltip: l10n.childLocationZonesButton,
          icon: Icons.shield_outlined,
          active: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildZonesScreen(childId: widget.childId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.childLocationNoDataTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.childLocationNoDataSubtitle,
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  label: l10n.childLocationSummaryDateLabel,
                  value: _fmtDay(_selectedDay),
                ),
                _SummaryChip(
                  label: l10n.childLocationSummaryTimeRangeLabel,
                  value: _rangeLabel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomCard(LocationData latest, ColorScheme cs) {
    final color = _transportColor(latest.transport);
    final icon = _transportIcon(latest.transport);
    final label = _transportLabel(latest.transport);
    final time = _fmtTime(latest.dateTime);
    final pointCount = _cachedHistory.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Transport icon badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),

            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isToday
                              ? const Color(0xFF34A853)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isToday
                            ? l10n.childLocationLiveLabel
                            : l10n.childLocationHistoryButton,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isToday
                              ? const Color(0xFF34A853)
                              : Colors.grey,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Right: time + point count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.childLocationPointCount(pointCount),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -- Small reusable widgets ----------------------------------------------------

class _AppBarChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AppBarChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _MapFab({
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active ? primary : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _TimeWindowSelection {
  final int startMinute;
  final int endMinute;

  const _TimeWindowSelection({
    required this.startMinute,
    required this.endMinute,
  });
}

class _RangePresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangePresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.14) : const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE0E3E7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? primary : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
