import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/features/map_engine/smooth/smooth_mover.dart';
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

class _ChildDetailMapScreenState extends State<ChildDetailMapScreen> {
  MapEngine? _engine;
  StreamSubscription<LocationData>? _sub;

  List<LocationData> _cachedHistory = const [];
  LocationData? _latest;

  final SmoothMover _mover = SmoothMover(durationMs: 650);
  Timer? _animTick;
  Timer? _renderDebounce;
  DateTime _lastMapMatchAt = DateTime.fromMillisecondsSinceEpoch(0);

  // ✅ chọn ngày
  late DateTime _selectedDay;
  DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  bool get _isToday => _dayOnly(_selectedDay) == _dayOnly(DateTime.now());

  // ✅ toggle dots (mặc định ẩn)
  bool _showDots = false;

  // ✅ preload history ngay khi vào màn (không chờ map)
  bool _historyLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dayOnly(DateTime.now());

    // ✅ preload ngay sau frame đầu để context.read an toàn
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
    super.dispose();
  }

  String _transportLabel(TransportMode t) {
    switch (t) {
      case TransportMode.walking:
        return "Đi bộ";
      case TransportMode.bicycle:
        return "Xe đạp";
      case TransportMode.vehicle:
        return "Đi xe";
      case TransportMode.still:
        return "Đứng yên";
      default:
        return "Không rõ";
    }
  }

  String _fmtDay(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  void _startAnimTick() {
    _animTick ??= Timer.periodic(const Duration(milliseconds: 16), (_) async {
      if (!mounted || _engine == null) return;
      if (_mover.isAnimating) {
        final smoothed = _mover.current();
        await _engine!.updateChildDot(smoothed); // chỉ update dot
      }
    });
  }

  void _appendRealtime(LocationData loc) {
    if (_cachedHistory.isEmpty || _cachedHistory.last.timestamp != loc.timestamp) {
      _cachedHistory = [..._cachedHistory, loc];
    }
  }

  Future<void> _toggleDots() async {
    setState(() => _showDots = !_showDots);
    await _engine?.setHistoryDotsVisible(_showDots);

    // Nếu đang bật dots mà style vừa reload, đảm bảo render có dữ liệu
    // (không bắt buộc, nhưng giúp UX)
    if (_engine != null) {
      await _engine!.setHistoryDotsVisible(_showDots);
    }
  }

  /// ✅ Preload lịch sử hôm nay ngay khi vào màn (network bắn ở đây)
  Future<void> _preloadToday() async {
    final vm = context.read<ParentLocationVm>();
    final today = _dayOnly(DateTime.now());

    final history = await vm.loadLocationHistoryByDay(widget.childId, today);

    if (!mounted) return;

    setState(() {
      _selectedDay = today;
      _cachedHistory = history;
      _historyLoaded = true;
      if (_cachedHistory.isNotEmpty) _latest = _cachedHistory.last;
    });
  }

  /// ✅ render lại overlays lên map (dùng khi style đổi / map recreate)
  Future<void> _renderOnMap() async {
    final engine = _engine;
    if (!mounted || engine == null) return;

    // Nếu chưa có data thì không vẽ
    if (_cachedHistory.isEmpty) {
      // vẫn set dots state cho đúng
      await engine.setHistoryDotsVisible(_showDots);
      return;
    }

    engine.resetForNewHistory(); // reset route cache + initial fit
    await engine.loadHistory(_cachedHistory, context);
    await engine.setHistoryDotsVisible(_showDots);
    _lastMapMatchAt = DateTime.now();

    // Nếu đang xem hôm nay thì bật realtime lại
    if (_isToday) {
      await _startRealtime();
    }
  }

  Future<void> _loadForDay(DateTime day) async {
    if (!mounted) return;
    final vm = context.read<ParentLocationVm>();
    final dayOnly = _dayOnly(day);

    // nếu xem ngày khác hôm nay -> stop realtime để khỏi lẫn
    if (dayOnly != _dayOnly(DateTime.now())) {
      await _sub?.cancel();
      _sub = null;
    }

    final history = await vm.loadLocationHistoryByDay(widget.childId, dayOnly);
    if (!mounted) return;

    setState(() {
      _selectedDay = dayOnly;
      _cachedHistory = history;
      if (_cachedHistory.isNotEmpty) _latest = _cachedHistory.last;
    });

    // vẽ lại map ngay
    await _renderOnMap();
  }

  Future<void> _startRealtime() async {
    final vm = context.read<ParentLocationVm>();
    await _sub?.cancel();

    _sub = vm.watchChildLocation(widget.childId).listen((loc) async {
      if (!mounted) return;

      // chỉ realtime khi xem "hôm nay"
      if (!_isToday) return;

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
    );
    if (picked == null) return;
    await _loadForDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;

    final title = _isToday
        ? (latest == null
        ? "Chi tiết vị trí"
        : "Trạng thái: ${_transportLabel(latest.transport)}")
        : "Lịch sử • ${_fmtDay(_selectedDay)}";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: _showDots ? "Ẩn điểm" : "Hiện điểm",
            icon: Icon(_showDots ? Icons.scatter_plot : Icons.scatter_plot_outlined),
            onPressed: _toggleDots,
          ),
          TextButton.icon(
            onPressed: _pickDay,
            icon: const Icon(Icons.history),
            label: const Text("Lịch sử"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.brown, // đổi theo theme của bạn
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppMapView(
        onMapCreated: (_) {},
        onStyleLoaded: (map) async {
          // ✅ MỖI LẦN ĐỔI STYLE: MapWidget recreate -> phải attach lại engine + re-render overlay
          _engine = MapEngine(map);
          await _engine!.init();

          // nếu chưa preload xong thì đợi 1 chút (tránh render rỗng)
          // nhưng vẫn không gọi network ở đây
          if (!_historyLoaded) {
            // fallback: nếu preload chưa chạy kịp, load ngay hôm nay (network)
            await _loadForDay(_dayOnly(DateTime.now()));
            return;
          }

          // render overlay từ cache (không gọi network)
          await _renderOnMap();
        },
      ),
    );
  }
}