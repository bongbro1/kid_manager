import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/features/map_engine/map_engine.dart';
import 'package:kid_manager/features/map_engine/smooth/smooth_mover.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/child_detail_map_vm.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_cards.dart';
import 'package:kid_manager/views/location/child_detail_map/child_detail_map_controls.dart';
import 'package:kid_manager/views/parent/zones/child_zones_screen.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';
import 'package:provider/provider.dart';

class ChildDetailMapScreen extends StatelessWidget {
  final String childId;

  const ChildDetailMapScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ChildDetailMapVm(context.read<ParentLocationVm>(), childId: childId),
      child: _ChildDetailMapBody(childId: childId),
    );
  }
}

class _ChildDetailMapBody extends StatefulWidget {
  final String childId;

  const _ChildDetailMapBody({required this.childId});

  @override
  State<_ChildDetailMapBody> createState() => _ChildDetailMapBodyState();
}

class _ChildDetailMapBodyState extends State<_ChildDetailMapBody>
    with SingleTickerProviderStateMixin {
  MapEngine? _engine;
  StreamSubscription<LocationData>? _sub;

  final SmoothMover _mover = SmoothMover(durationMs: 650);
  Timer? _animTick;
  Timer? _renderDebounce;
  DateTime _lastMapMatchAt = DateTime.fromMillisecondsSinceEpoch(0);

  late final AnimationController _cardAnim;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  bool _hideEmptyCard = false;
  ChildDetailMapVm get _vm => context.read<ChildDetailMapVm>();
  ParentLocationVm get _parentVm => context.read<ParentLocationVm>();

  @override
  void initState() {
    super.initState();

    _cardAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnim, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(parent: _cardAnim, curve: Curves.easeIn);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _vm.preloadToday();
      if (!mounted) return;
      _syncCardAnimation();
      if (_engine != null) {
        await _renderOnMap();
      }
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

  void _syncCardAnimation() {
    if (_vm.latest == null) {
      if (_cardAnim.status != AnimationStatus.dismissed) {
        _cardAnim.reverse();
      }
      return;
    }

    if (_cardAnim.status != AnimationStatus.forward &&
        _cardAnim.status != AnimationStatus.completed) {
      _cardAnim.forward();
    }
  }

  void _startAnimTick() {
    _animTick ??= Timer.periodic(const Duration(milliseconds: 16), (_) async {
      if (!mounted || _engine == null) return;
      if (_mover.isAnimating) {
        final smoothed = _mover.current();
        await _engine!.updateChildDot(smoothed);
      }
    });
  }

  Future<void> _renderOnMap() async {
    final engine = _engine;
    if (!mounted || engine == null) return;

    await engine.resetForNewHistory();
    final history = _vm.cachedHistory;

    if (history.isEmpty) {
      await engine.setHistoryDotsVisible(_vm.showDots);
      if (_vm.isToday && _vm.rangeIncludesNow) {
        await _startRealtime();
      } else {
        await _sub?.cancel();
        _sub = null;
      }
      _syncCardAnimation();
      return;
    }

    await engine.loadHistory(history, context);
    await engine.setHistoryDotsVisible(_vm.showDots);
    _lastMapMatchAt = DateTime.now();

    if (_vm.isToday && _vm.rangeIncludesNow) {
      await _startRealtime();
    } else {
      await _sub?.cancel();
      _sub = null;
    }

    _syncCardAnimation();
  }

  Future<void> _loadForDay(DateTime day) async {
    setState(() {
      _hideEmptyCard = false;
    });
    final dayOnly = DateTime(day.year, day.month, day.day);
    final today = DateTime.now();
    final isToday =
        dayOnly.year == today.year &&
        dayOnly.month == today.month &&
        dayOnly.day == today.day;

    if (!isToday) {
      await _sub?.cancel();
      _sub = null;
    }

    await _vm.loadForDay(dayOnly);
    if (!mounted) return;

    _syncCardAnimation();
    await _renderOnMap();
  }

  Future<void> _startRealtime() async {
    await _sub?.cancel();
    _sub = _parentVm.watchChildLocation(widget.childId).listen((loc) async {
      if (!mounted || !_vm.isToday) return;
      if (!_vm.isTsInSelectedRange(loc.timestamp)) {
        await _sub?.cancel();
        _sub = null;
        return;
      }

      _vm.appendRealtime(loc);
      _syncCardAnimation();

      _mover.push(loc);
      _startAnimTick();

      _renderDebounce?.cancel();
      _renderDebounce = Timer(const Duration(milliseconds: 300), () async {
        if (!mounted || _engine == null) return;
        await _engine!.renderHistoryFast(_vm.cachedHistory, context);
      });

      final now = DateTime.now();
      if (_engine != null &&
          now.difference(_lastMapMatchAt) >= const Duration(seconds: 20) &&
          _vm.cachedHistory.length >= 6) {
        _lastMapMatchAt = now;
        await _engine!.updateMatchedRouteIncremental(
          _vm.cachedHistory,
          context,
        );
      }
    });
  }

  Future<void> _applyTimeWindow(int startMinute, int endMinute) async {
    setState(() {
      _hideEmptyCard = false;
    });
    await _vm.applyTimeWindow(startMinute, endMinute);
    if (!mounted) return;

    _syncCardAnimation();
    await _renderOnMap();
  }

  Future<void> _pickTimeWindow() async {
    final selection = await showChildDetailTimeWindowSheet(
      context: context,
      initialStartMinute: _vm.rangeStartMinute,
      initialEndMinute: _vm.rangeEndMinute,
      minuteLabel: _vm.minuteLabel,
    );
    if (selection == null) return;

    await _applyTimeWindow(selection.startMinute, selection.endMinute);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vm.selectedDay,
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

  Future<void> _toggleDots() async {
    _vm.toggleDots();
    await _engine?.setHistoryDotsVisible(_vm.showDots);
  }

  String _fmtDay(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  PreferredSizeWidget _buildAppBar(ChildDetailMapVm vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.55), Colors.transparent],
          ),
        ),
      ),
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.isToday ? 'Hành trình hiện tại' : 'Lịch sử di chuyển',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            '${_fmtDay(vm.selectedDay)} - ${vm.rangeLabel}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        ChildDetailMapAppBarChip(
          icon: Icons.calendar_today_rounded,
          label: vm.isToday ? 'Hôm nay' : _fmtDay(vm.selectedDay),
          onTap: _pickDay,
        ),
        const SizedBox(width: 8),
        ChildDetailMapAppBarChip(
          icon: Icons.schedule_rounded,
          label: vm.rangeLabel,
          onTap: _pickTimeWindow,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFabColumn(ChildDetailMapVm vm) {
    return Column(
      children: [
        ChildDetailMapFab(
          tooltip: vm.showDots ? 'Ẩn điểm dừng' : 'Hiện điểm dừng',
          icon: vm.showDots
              ? Icons.scatter_plot_rounded
              : Icons.scatter_plot_outlined,
          active: vm.showDots,
          onTap: _toggleDots,
        ),
        const SizedBox(height: 10),
        ChildDetailMapFab(
          tooltip: 'Quản lý vùng',
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

  Widget _buildOverlay(ChildDetailMapVm vm) {
    final latest = vm.latest;

    return Stack(
      children: [
        if (!_hideEmptyCard &&
            vm.selectedPoint == null &&
            vm.historyLoaded &&
            vm.cachedHistory.isEmpty)
          Positioned(
            left: 12,
            right: 68,
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
            child: ChildDetailEmptyStateCard(
              dayLabel: _fmtDay(vm.selectedDay),
              rangeLabel: vm.rangeLabel,
              onClose: () {
                setState(() {
                  _hideEmptyCard = true;
                });
              },
            ),
          ),
        if (vm.selectedPoint != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: latest != null ? 108 : 16,
            child: ChildDetailSelectedPointCard(
              point: vm.selectedPoint!,
              history: vm.cachedHistory,
              isToday: vm.isToday,
              onClose: _vm.clearSelectedPoint,
            ),
          ),
        Positioned(
          top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
          right: 12,
          child: _buildFabColumn(vm),
        ),
        if (latest != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _cardSlide,
              child: FadeTransition(
                opacity: _cardFade,
                child: ChildDetailBottomCard(
                  latest: latest,
                  isToday: vm.isToday,
                  pointCount: vm.cachedHistory.length,
                ),
              ),
            ),
          ),
        if (!vm.historyLoaded)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Consumer<ChildDetailMapVm>(
          builder: (context, vm, _) => _buildAppBar(vm),
        ),
      ),
      body: Stack(
        children: [
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
                  _vm.setSelectedPoint(point);
                },
              );
              await _engine!.init();
              if (_vm.historyLoaded) {
                await _renderOnMap();
              }
            },
          ),
          Consumer<ChildDetailMapVm>(
            builder: (context, vm, _) => _buildOverlay(vm),
          ),
        ],
      ),
    );
  }
}
