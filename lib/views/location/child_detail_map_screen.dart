import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/features/map_engine/map_engine.dart';
import 'package:kid_manager/features/map_engine/smooth/smooth_mover.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/presentation/pages/tracking_page.dart';
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
  final String? childAvatarUrl;

  const ChildDetailMapScreen({
    super.key,
    required this.childId,
    this.childAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ChildDetailMapVm(context.read<ParentLocationVm>(), childId: childId),
      child: _ChildDetailMapBody(
        childId: childId,
        childAvatarUrl: childAvatarUrl,
      ),
    );
  }
}

class _ChildDetailMapBody extends StatefulWidget {
  final String childId;
  final String? childAvatarUrl;

  const _ChildDetailMapBody({
    required this.childId,
    this.childAvatarUrl,
  });

  @override
  State<_ChildDetailMapBody> createState() => _ChildDetailMapBodyState();
}

class _ChildDetailMapBodyState extends State<_ChildDetailMapBody>
    with SingleTickerProviderStateMixin {
  MapEngine? _engine;
  StreamSubscription<LocationData>? _sub;

  final SmoothMover _mover = SmoothMover(durationMs: 650);
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Timer? _animTick;
  Timer? _renderDebounce;
  DateTime _lastMapMatchAt = DateTime.fromMillisecondsSinceEpoch(0);
  final AppMapViewController _mapViewController = AppMapViewController();
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
    _sheetController.dispose();
    super.dispose();
  }

  void _syncCardAnimation() {
    if (_vm.latest == null && _vm.selectedPoint == null) {
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

  Future<void> _expandSheetForSelection() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.68,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _collapseSheet() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      0.24,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  LocationData _canonicalHistoryPoint(LocationData point) {
    for (final entry in _vm.cachedHistory) {
      if (entry.timestamp == point.timestamp) {
        return entry;
      }
    }
    return point;
  }

  Future<void> _showPointDetails(LocationData point) async {
    final resolvedPoint = _canonicalHistoryPoint(point);
    _vm.setSelectedPoint(resolvedPoint);
    _syncCardAnimation();
    await _expandSheetForSelection();
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
    setState(() => _hideEmptyCard = false);
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
    setState(() => _hideEmptyCard = false);
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

  String _fmtDay(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  String _buildAppBarSubtitle(ChildDetailMapVm vm) {
    final latest = vm.latest;
    if (latest == null) {
      return '${_fmtDay(vm.selectedDay)} \u00B7 ${vm.rangeLabel}';
    }

    final diff = DateTime.now().difference(latest.dateTime);
    final freshness = diff.inMinutes <= 0
        ? 'C\u1EADp nh\u1EADt v\u1EEBa xong'
        : diff.inMinutes == 1
        ? 'C\u1EADp nh\u1EADt 1 ph\u00FAt tr\u01B0\u1EDBc'
        : 'C\u1EADp nh\u1EADt ${diff.inMinutes} ph\u00FAt tr\u01B0\u1EDBc';

    return '$freshness \u00B7 ${vm.rangeLabel}';
  }

  String _buildAvatarLabel() {
    final compact = widget.childId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (compact.length >= 2) {
      return compact.substring(0, 2).toUpperCase();
    }
    if (compact.isNotEmpty) {
      return compact.toUpperCase();
    }
    return 'BE';
  }

  Widget _buildAvatarBadge() {
    final avatarUrl = widget.childAvatarUrl?.trim() ?? '';
    return Container(
      width: 36,
      height: 36,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4CAF7D),
      ),
      child: ClipOval(
        child: avatarUrl.isEmpty
            ? Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  _buildAvatarLabel(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF64748B),
                  alignment: Alignment.center,
                  child: Text(
                    _buildAvatarLabel(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChildDetailMapVm vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 110,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.86),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.90)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0x1A2196F3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.isToday
                              ? 'H\u00E0nh tr\u00ECnh hi\u1EC7n t\u1EA1i'
                              : 'L\u1ECBch s\u1EED di chuy\u1EC3n',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _buildAppBarSubtitle(vm),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildAvatarBadge(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChildDetailMapAppBarChip(
                      icon: Icons.calendar_today_rounded,
                      label: vm.isToday
                          ? 'H\u00F4m nay'
                          : _fmtDay(vm.selectedDay),
                      onTap: _pickDay,
                      highlighted: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChildDetailMapAppBarChip(
                      icon: Icons.schedule_rounded,
                      label: vm.rangeLabel,
                      onTap: _pickTimeWindow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFabColumn(ChildDetailMapVm vm) {
    final startPointSource = vm.selectedPoint ?? vm.latest;
    final startPoint = startPointSource == null
        ? null
        : RoutePoint(
            latitude: startPointSource.latitude,
            longitude: startPointSource.longitude,
            sequence: 0,
          );

    return Column(
      children: [
        ChildDetailMapFab(
          tooltip: 'Ẩn điểm dừng/Hiện điểm dừng',
          icon: Icons.more_vert_rounded,
          active: vm.showDots,
          onTap: _toggleDots,
        ),
        const SizedBox(height: 10),
        ChildDetailMapFab(
          tooltip: 'Quản lý vùng',
          icon: Icons.hexagon_outlined,
          active: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChildZonesScreen(childId: widget.childId),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ChildDetailMapFab(
          tooltip: 'Tuyến đường an toàn',
          icon: Icons.route_rounded,
          active: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TrackingPage(
                childId: widget.childId,
                childAvatarUrl: widget.childAvatarUrl,
                initialStartPoint: startPoint,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ChildDetailMapFab(
          tooltip: 'Chọn bản đồ',
          icon: Icons.layers_outlined,
          active: false,
          onTap: _mapViewController.showMapSelector,
        ),
      ],
    );
  }

  Widget _buildOverlay(ChildDetailMapVm vm) {
    final topInset = MediaQuery.of(context).padding.top;

    // chiÃ¡Â»Âu cao vÃƒÂ¹ng header Ã„â€˜ang dÃƒÂ¹ng:
    // AppBar 110 + khoÃ¡ÂºÂ£ng Ã„â€˜Ã¡Â»â€¡m nhÃƒÂ¬n thÃ¡Â»Â±c tÃ¡ÂºÂ¿ thÃƒÂªm mÃ¡Â»â„¢t chÃƒÂºt
    final fabTop = topInset + 112 + 18;

    return Stack(
      children: [
        if (!_hideEmptyCard &&
            vm.selectedPoint == null &&
            vm.historyLoaded &&
            vm.cachedHistory.isEmpty)
          Positioned(
            left: 12,
            right: 72,
            top: fabTop,
            child: ChildDetailEmptyStateCard(
              dayLabel: _fmtDay(vm.selectedDay),
              rangeLabel: vm.rangeLabel,
              onClose: () => setState(() => _hideEmptyCard = true),
            ),
          ),

        Positioned(top: fabTop, right: 12, child: _buildFabColumn(vm)),

        if (vm.latest != null || vm.selectedPoint != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: SlideTransition(
                position: _cardSlide,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: ChildDetailMapBottomSheet(
                    vm: vm,
                    onPointSelected: _showPointDetails,
                    onClosePoint: () async {
                      _vm.clearSelectedPoint();
                      await _collapseSheet();
                    },
                    controller: _sheetController,
                  ),
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
        preferredSize: const Size.fromHeight(110),
        child: Consumer<ChildDetailMapVm>(
          builder: (context, vm, _) => _buildAppBar(vm),
        ),
      ),
      body: Stack(
        children: [
          AppMapView(
            controller: _mapViewController,
            showInternalMapTypeButton: false,

            onMapCreated: (_) {},
            onTapListener: (gesture) {
              _engine?.handleMapTap(gesture);
            },
            onStyleLoaded: (map) async {
              _engine = MapEngine(
                map,
                enableChildDot: true,
                childAvatarUrl: widget.childAvatarUrl,
                onHistoryPointSelected: (point) async {
                  if (!mounted) return;
                  await _showPointDetails(point);
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