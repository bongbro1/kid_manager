import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/views/parent/location/parent_children_list_screen.dart';
import 'package:kid_manager/widgets/sos/incoming_sos_overlay.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

import 'package:kid_manager/features/presentation/shared/state/mapbox_controller.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/location/child_info_sheet.dart';
import 'package:kid_manager/widgets/location/map_bottom_controls.dart';
import 'package:kid_manager/widgets/location/map_top_bar.dart';

class ParentAllChildrenMapScreen extends StatefulWidget {
  const ParentAllChildrenMapScreen({super.key});

  @override
  State<ParentAllChildrenMapScreen> createState() =>
      _ParentAllChildrenMapScreenState();
}

class _ParentAllChildrenMapScreenState extends State<ParentAllChildrenMapScreen> {
  bool _didInitialFit = false;
  mbx.MapboxMap? _map;

  bool _inited = false;
  bool _didInitialFocus = false;
  late final UserVm _userVm;
  late final ParentLocationVm _locationVm;
  late final MapboxController _controller;

  Timer? _syncDebounce;
  bool _avatarSet = false;

  @override
  void initState() {
    super.initState();
    sosFocusNotifier.addListener(_onSosFocus);
  }

  Future<void> _onSosFocus() async {
    final focus = sosFocusNotifier.value;
    if (!mounted || focus == null) return;

    // optional: chỉ xử lý đúng family
    final myFamilyId = _userVm.familyId;
    if (myFamilyId != null && focus.familyId != myFamilyId) return;

    if (_map == null) return;

    await _map!.easeTo(
      mbx.CameraOptions(
        center: mbx.Point(coordinates: mbx.Position(focus.lng, focus.lat)),
        zoom: 16,
      ),
      mbx.MapAnimationOptions(duration: 700),
    );

    sosFocusNotifier.value = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;

    _userVm = context.read<UserVm>();
    _locationVm = context.read<ParentLocationVm>();
    _controller = context.read<MapboxController>();

    try {
      _locationVm.startMyLocation();
    } catch (e, st) {
      debugPrint('🔥 startMyLocation failed: $e');
      debugPrint('$st');
    }

    _controller.addListener(_handleMapOrDataChange);
    _locationVm.addListener(_handleMapOrDataChange);
    _userVm.addListener(_handleUserChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_userVm.childrenIds.isNotEmpty) {
        _locationVm.syncWatching(_userVm.childrenIds);
      }
    });
  }


  Future<void> _focusFirstChildOnce() async {
    if (_didInitialFocus) return;
    if (_map == null) return;
    if (_userVm.children.isEmpty) return;

    // lấy child đầu tiên trong danh sách userVm.children
    final firstChildId = _userVm.children.first.uid;
    final loc = _locationVm.childrenLocations[firstChildId];
    if (loc == null) return;

    _didInitialFocus = true;

    //  setCamera / jumpTo để KHÔNG có zoom từ trái đất
    await _map!.setCamera(
      mbx.CameraOptions(
        center: mbx.Point(coordinates: mbx.Position(loc.longitude, loc.latitude)),
        zoom: 16.5,
        pitch: 0,
        bearing: 0,
      ),
    );
  }
  void _handleMapOrDataChange() {
    if (!mounted) return;
    if (!_controller.isReady) return;

    // debounce để tránh spam scheduleUpdate
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 250), () async{
      if (!mounted) return;
      if (_locationVm.childrenLocations.isNotEmpty) {
        await _syncToMap();
         await _focusFirstChildOnce();

      }
    });
  }

  void _handleUserChange() {
    if (!mounted) return;

    if (_userVm.childrenIds.isNotEmpty && _locationVm.childrenLocations.isEmpty) {
      _locationVm.syncWatching(_userVm.childrenIds);
    }
  }

  Future<void> _syncToMap() async {
    if (!_controller.isReady) return;

    final positions = <String, mbx.Position>{};
    final headings = <String, double>{};
    final names = <String, String>{};

    final childMap = {for (final c in _userVm.children) c.uid: c};

    for (final entry in _locationVm.childrenLocations.entries) {
      final child = childMap[entry.key];
      if (child == null) continue;

      final loc = entry.value;
      positions[child.uid] = mbx.Position(loc.longitude, loc.latitude);
      headings[child.uid] = loc.heading ?? 0;
      names[child.uid] = child.displayName ?? "";
    }

    _controller.scheduleUpdate(
      positions: positions,
      headings: headings,
      names: names,
    );


  }

  void _openChildInfo(String childId) {
    final child = _userVm.children.firstWhere((c) => c.uid == childId);
    final latest = _locationVm.childrenLocations[child.uid];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChildInfoSheet(
        child: child,
        latest: latest,
        isSearching: false,
        onToggleSearch: () {},
        onOpenChat: () {},
        onSendQuickMessage: (msg) async {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //  select để tránh rebuild toàn màn theo UserVm
    final familyId = context.select<UserVm, String?>((vm) => vm.familyId);
    final children = context.select<UserVm, List<dynamic>>(
          (vm) => List.of(vm.children),
    );
    final myUid = context.select<UserVm, String?>((vm) => vm.me?.uid);

    debugPrint("Building ParentAllChildrenMapScreen with familyId=$familyId");

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: mbx.MapWidget(
              key: const ValueKey("parent-map"),
              cameraOptions: mbx.CameraOptions(
                zoom: 15.5,
                center: mbx.Point(
                  coordinates: mbx.Position(105.8342, 21.0278), // fallback
                ),
              ),
              styleUri: "mapbox://styles/mapbox/streets-v12",

              onMapCreated: (map) {
                _map = map;
                _controller.attach(map);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _onSosFocus();
                });
              },
              onTapListener: (tapContext) async {
                if (_map == null) return;

                final features = await _map!.queryRenderedFeatures(
                  mbx.RenderedQueryGeometry.fromScreenCoordinate(
                    tapContext.touchPosition,
                  ),
                  mbx.RenderedQueryOptions(
                    layerIds: ["children-layer"],
                    filter: null,
                  ),
                );

                if (features.isEmpty) return;

                final queried = features.first?.queriedFeature;
                if (queried == null) return;

                final rawFeature = queried.feature as Map<String?, Object?>?;
                if (rawFeature == null) return;

                final props = rawFeature["properties"] as Map?;
                if (props == null) return;

                final childId = props["id"]?.toString();
                if (childId == null) return;

                _openChildInfo(childId);
                await _controller.zoomToChild(childId);
              },
              onStyleLoadedListener: (_) async {
                try {
                  await _controller.onStyleLoaded();
                } catch (e, st) {
                  debugPrint("🔥 onStyleLoaded failed: $e");
                  debugPrint("$st");
                }

                if (!mounted) return;

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  try {
                    // chỉ set avatar 1 lần
                    if (!_avatarSet) {
                      _avatarSet = true;
                      final data = await rootBundle.load(
                        "assets/images/avatar_default.png",
                      );
                      await _controller.setDefaultAvatar(
                        data.buffer.asUint8List(),
                      );
                    }

                    await _syncToMap();
                    await _focusFirstChildOnce();
                  } catch (e, st) {
                    debugPrint("🔥 Setup Error: $e");
                    debugPrint("$st");
                  }
                });
              },
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: MapTopBar(onMenuTap: () {}, onAvatarTap: () {}),
          ),

          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: SafeArea(
              child: MapBottomControls(
                children: children.cast(), // nếu type khác thì đổi
                onMyLocation: () async {
                  _didInitialFit = false;
                  await _syncToMap();
                },
                onTapChild: (child) {
                  _openChildInfo(child.uid);
                },
                onMore: () async {
                  final selectedChild = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ParentChildrenListScreen()),
                  );

                  if (selectedChild == null) return;

                  final childId = selectedChild.uid;

                  final duration = await _controller.zoomToChild(childId);
                  await Future.delayed(Duration(milliseconds: duration));
                  _openChildInfo(childId);
                },
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 96,
            child: SafeArea(
              child: FloatingActionButton(
                heroTag: 'parent_sos_fab',
                backgroundColor: Colors.red.shade700,
                onPressed: () async {
                  final sosVm = context.read<SosViewModel>();
                  final myLocation = _locationVm.myLocation;
                  if (myLocation == null) return;
                  if (sosVm.sending) return;

                  final sosId = await sosVm.triggerSos(
                    lat: myLocation.latitude,
                    lng: myLocation.longitude,
                    acc: myLocation.accuracy,
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sosId != null ? 'Đã gửi SOS' : 'Gửi SOS thất bại'),
                    ),
                  );
                },
                child: const Icon(Icons.sos, color: Colors.white),
              ),
            ),
          ),

          // Overlay ổn định: chỉ rebuild khi familyId đổi
          if (familyId != null && myUid != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 110,
              child: IncomingSosOverlay(
                key: ValueKey('sos-$familyId'),
                familyId: familyId,
                myUid: myUid,
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();

    _controller.removeListener(_handleMapOrDataChange);
    _locationVm.removeListener(_handleMapOrDataChange);
    _userVm.removeListener(_handleUserChange);

    sosFocusNotifier.removeListener(_onSosFocus);

    _controller.detach();
    super.dispose();
  }
}