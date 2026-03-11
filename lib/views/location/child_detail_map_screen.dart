import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/features/map_engine/smooth/smooth_mover.dart';
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
  MapEngine? _engine;
  StreamSubscription<LocationData>? _sub;

  List<LocationData> _cachedHistory = const [];
  LocationData? _latest;

  final SmoothMover _mover = SmoothMover(durationMs: 650);
  Timer? _animTick;
  Timer? _renderDebounce;
  DateTime _lastMapMatchAt = DateTime.fromMillisecondsSinceEpoch(0);

  late DateTime _selectedDay;
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool get _isToday => _dayOnly(_selectedDay) == _dayOnly(DateTime.now());

  bool _showDots = false;
  bool _historyLoaded = false;

  // ── animation controller cho bottom card ──────────────────────────────────
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

  // ── helpers ───────────────────────────────────────────────────────────────
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
                    'Bắt đầu',
                    const Color(0xFFDDF5E3),
                    const Color(0xFF188038),
                  ),
                if (isEnd)
                  _tagChip(
                    'Kết thúc',
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
                    'GPS rất yếu',
                    const Color(0xFFFCE8E6),
                    const Color(0xFFC5221F),
                  )
                else if (gpsLost)
                  _tagChip(
                    'Mất GPS',
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
                    label: 'Ở đây được',
                    value: gpsLost
                        ? 'Không xác định ổn định'
                        : _formatDuration(stopDuration),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoTile(
                    label: 'Tốc độ',
                    value: gpsLost ? 'Không ổn định' : _speedLabel(point),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _infoTile(
                    label: 'Sai số GPS',
                    value: _accuracyLabel(point),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _infoTile(
                    label: 'GPS giả lập',
                    value: point.isMock ? 'Có dấu hiệu' : 'Không',
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
                'Xem chi tiết kỹ thuật',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              children: [
                _detailRow('Thời gian đầy đủ', point.fullLabel),
                _detailRow('Hướng di chuyển', '${point.heading.toStringAsFixed(0)}°'),
                _detailRow(
                  'Tọa độ',
                  '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                ),
                _detailRow(
                  'Độ chính xác',
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
    if (d.inSeconds <= 0) return '0 phút';

    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;

    if (hours > 0) {
      return '${hours} giờ ${minutes} phút';
    }
    if (minutes > 0) {
      return '${minutes} phút';
    }
    return '${seconds} giây';
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
      'Mất GPS định vị',
      'Tín hiệu GPS rất yếu, vị trí có thể không chính xác',
      );
    }

    if (gpsLost) {
      return (
      'Mất GPS định vị',
      'Sai số lớn hơn ${point.accuracy.toStringAsFixed(0)} m',
      );
    }

    if (isStoppedLongEnough) {
      if (isEnd && _isToday) {
        return (
        'Đang đứng yên',
        'Dừng tại đây ${_formatDuration(stopDuration)}',
        );
      }
      return (
      'Đứng yên tại đây',
      'Dừng khoảng ${_formatDuration(stopDuration)}',
      );
    }

    if (isStart) {
      return (
      _transportHeadline(point.transport),
      'Điểm bắt đầu hành trình',
      );
    }

    if (isEnd) {
      return (
      _transportHeadline(point.transport),
      _isToday
          ? 'Cập nhật lúc ${point.timeLabel}'
          : 'Điểm kết thúc hành trình',
      );
    }

    return (
    _transportHeadline(point.transport),
    'Đi qua điểm này lúc ${point.timeLabel}',
    );
  }

  String _transportHeadline(TransportMode t) {
    switch (t) {
      case TransportMode.walking:
        return 'Đang đi bộ';
      case TransportMode.bicycle:
        return 'Đang đi xe đạp';
      case TransportMode.vehicle:
        return 'Đang đi xe';
      case TransportMode.still:
        return 'Đang đứng yên';
      default:
        return 'Không rõ trạng thái';
    }
  }

  String _speedLabel(LocationData point) {
    final kmh = point.speedKmh;
    if (kmh <= 1) return 'Gần như không di chuyển';
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String _accuracyLabel(LocationData point) {
    final acc = point.accuracy.toStringAsFixed(0);

    if (point.accuracy > 80) return 'Mất GPS nghiêm trọng';
    if (point.accuracy > 30) return 'Mất GPS định vị';
    if (point.accuracy <= 15) return 'Khá chính xác (${acc} m)';
    return 'Chính xác vừa (${acc} m)';
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
        return "Đi bộ";
      case TransportMode.bicycle:
        return "Xe đạp";
      case TransportMode.vehicle:
        return "Đang đi xe";
      case TransportMode.still:
        return "Đứng yên";
      default:
        return "Không rõ";
    }
  }

  String _fmtDay(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  String _fmtTime(DateTime d) =>
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  // ── core logic (unchanged) ────────────────────────────────────────────────

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
    final history =
    await vm.loadLocationHistoryByDay(widget.childId, today);
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
    if (_cachedHistory.isEmpty) {
      await engine.setHistoryDotsVisible(_showDots);
      return;
    }
    engine.resetForNewHistory();
    await engine.loadHistory(_cachedHistory, context);
    await engine.setHistoryDotsVisible(_showDots);
    _lastMapMatchAt = DateTime.now();
    if (_isToday) await _startRealtime();
  }

  Future<void> _loadForDay(DateTime day) async {
    if (!mounted) return;
    final vm = context.read<ParentLocationVm>();
    final dayOnly = _dayOnly(day);
    if (dayOnly != _dayOnly(DateTime.now())) {
      await _sub?.cancel();
      _sub = null;
    }
    final history =
    await vm.loadLocationHistoryByDay(widget.childId, dayOnly);
    if (!mounted) return;
    setState(() {
      _selectedDay = dayOnly;
      _cachedHistory = history;
      _selectedPoint = null;
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

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final latest = _latest;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(cs),
      body: Stack(
        children: [
          // ── Map fullscreen ──────────────────────────────────────────────
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
          if (_selectedPoint != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: latest != null ? 108 : 16,
              child: _buildSelectedPointCard(_selectedPoint!),
            ),
          // ── Floating action row (dots + zones) ──────────────────────────
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
            right: 12,
            child: _buildFabColumn(cs),
          ),

          // ── Bottom status card ──────────────────────────────────────────
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

          // ── Loading shimmer ─────────────────────────────────────────────
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
            _isToday ? "Vị trí hiện tại" : "Lịch sử",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            _isToday ? "Hôm nay" : _fmtDay(_selectedDay),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        // Chọn ngày
        _AppBarChip(
          icon: Icons.calendar_today_rounded,
          label: _isToday ? "Hôm nay" : _fmtDay(_selectedDay),
          onTap: _pickDay,
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
          tooltip: _showDots ? "Ẩn điểm dừng" : "Hiện điểm dừng",
          icon: _showDots
              ? Icons.scatter_plot_rounded
              : Icons.scatter_plot_outlined,
          active: _showDots,
          onTap: _toggleDots,
        ),
        // Vùng an toàn
        _MapFab(
          tooltip: "Quản lý vùng",
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

  Widget _buildBottomCard(LocationData latest, ColorScheme cs) {
    final color = _transportColor(latest.transport);
    final icon = _transportIcon(latest.transport);
    final label = _transportLabel(latest.transport);
    final time = _fmtTime(latest.dateOnly);
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
                        _isToday ? "Trực tiếp" : "Lịch sử",
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
                  "$pointCount điểm",
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

// ── Small reusable widgets ────────────────────────────────────────────────────

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