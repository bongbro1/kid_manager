import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/views/parent/location/parent_children_list_screen.dart';
import 'package:kid_manager/widgets/sos/incoming_sos_overlay.dart';
import 'package:kid_manager/widgets/sos/sos_view.dart';
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

class _ParentAllChildrenMapScreenState
    extends State<ParentAllChildrenMapScreen> {
  bool _didInitialFit = false;
  mbx.MapboxMap? _map;

  bool _inited = false;
  late final UserVm _userVm;
  late final ParentLocationVm _locationVm;
  late final MapboxController _controller;

  @override
  void initState() {
    super.initState();
    sosFocusNotifier.addListener(_onSosFocus);
  }

  void _onSosFocus() async {
    final focus = sosFocusNotifier.value;
    if (!mounted || focus == null) return;

    // ✅ chỉ xử lý nếu đúng family (optional)
    final myFamilyId = context.read<UserVm>().familyId;
    if (myFamilyId != null && focus.familyId != myFamilyId) return;

    // map có thể chưa tạo xong
    if (_map == null) return;

    await _map!.easeTo(
      mbx.CameraOptions(
        center: mbx.Point(coordinates: mbx.Position(focus.lng, focus.lat)),
        zoom: 16,
      ),
      mbx.MapAnimationOptions(duration: 700),
    );

    // nếu muốn, có thể mở sheet theo childUid (nếu bạn lưu childUid)
    // if (focus.childUid != null) _openChildInfo(focus.childUid!);

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
    } // Add listeners ngay khi đã có instance
    _controller.addListener(_handleMapOrDataChange);
    _locationVm.addListener(_handleMapOrDataChange);
    _userVm.addListener(_handleUserChange);

    // Nếu cần chạy sau frame để chắc UI/build xong thì giữ postFrame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ tránh dùng context, dùng biến đã cache
      if (_userVm.childrenIds.isNotEmpty) {
        _locationVm.syncWatching(_userVm.childrenIds);
      }
    });
  }

  void _handleMapOrDataChange() {
    if (!mounted) return;

    if (_controller.isReady && _locationVm.childrenLocations.isNotEmpty) {
      _syncToMap();
    }
  }

  void _handleUserChange() {
    if (!mounted) return;

    if (_userVm.childrenIds.isNotEmpty &&
        _locationVm.childrenLocations.isEmpty) {
      _locationVm.syncWatching(_userVm.childrenIds);
    }
  }

  Future<void> _syncToMap() async {
    final controller = context.read<MapboxController>();
    final locationVm = context.read<ParentLocationVm>();
    final userVm = context.read<UserVm>();

    if (!controller.isReady) return;

    final positions = <String, mbx.Position>{};
    final headings = <String, double>{};
    final names = <String, String>{};

    final childMap = {for (final c in userVm.children) c.uid: c};

    for (final entry in locationVm.childrenLocations.entries) {
      final child = childMap[entry.key];
      if (child == null) continue;

      final loc = entry.value;
      positions[child.uid] = mbx.Position(loc.longitude, loc.latitude);
      headings[child.uid] = loc.heading ?? 0;
      names[child.uid] = child.displayName ?? "";
    }

    controller.scheduleUpdate(
      positions: positions,
      headings: headings,
      names: names,
    );

    if (!_didInitialFit && positions.isNotEmpty) {
      _didInitialFit = true;
      await controller.fitPoints(positions.values.toList());
    }
  }

  void _openChildInfo(String childId) {
    final locationVm = context.read<ParentLocationVm>();
    final userVm = context.read<UserVm>();

    final child = userVm.children.firstWhere((c) => c.uid == childId);

    final latest = locationVm.childrenLocations[child.uid];

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
    final familyId = context.watch<UserVm>().familyId;
    debugPrint("Building ParentAllChildrenMapScreen with familyId=$familyId");
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                mbx.MapWidget(
                  key: const ValueKey("parent-map"),
                  styleUri: "mapbox://styles/mapbox/streets-v12",

                  onMapCreated: (map) {
                    _map = map;
                    context.read<MapboxController>().attach(map);
                    print("Map created and controller attached");
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

                    debugPrint("TAP features count = ${features.length}");

                    if (features.isEmpty) return;

                    final queried = features.first?.queriedFeature;
                    if (queried == null) return;

                    final rawFeature =
                        queried.feature as Map<String?, Object?>?;

                    if (rawFeature == null) return;

                    final props = rawFeature["properties"] as Map?;

                    if (props == null) return;

                    final childId = props["id"]?.toString();
                    if (childId == null) return;

                    debugPrint("TAP childId = $childId");

                    _openChildInfo(childId);
                    await context.read<MapboxController>().zoomToChild(childId);
                  },

                  onStyleLoadedListener: (_) async {
                    final controller = context.read<MapboxController>();
                    await controller.onStyleLoaded();

                    if (!mounted) return;

                    //  Dùng addPostFrameCallback để đảm bảo native map hoàn toàn sẵn sàng
                    WidgetsBinding.instance.addPostFrameCallback((_) async {
                      if (!mounted) return;
                      try {
                        final data = await rootBundle.load(
                          "assets/images/avatar_default.png",
                        );
                        await controller.setDefaultAvatar(
                          data.buffer.asUint8List(),
                        );
                        if (mounted) await _syncToMap();
                      } catch (e) {
                        debugPrint("🔥 Setup Error: $e");
                      }
                    });
                  },
                ),
              ],
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
                children: context.watch<UserVm>().children,
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
                    MaterialPageRoute(
                      builder: (_) => ParentChildrenListScreen(),
                    ),
                  );

                  if (selectedChild == null) return;

                  final childId = selectedChild.uid;

                  final duration = await context
                      .read<MapboxController>()
                      .zoomToChild(childId);

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
                  final locationVm = context.read<ParentLocationVm>();
                  final myLocation =
                      locationVm.myLocation; // bạn cần expose cái này

                  if (myLocation == null) return;

                  // optional: chống double tap
                  if (sosVm.sending) return;

                  final sosId = await sosVm.triggerSos(
                    lat: myLocation.latitude,
                    lng: myLocation.longitude,
                    acc: myLocation.accuracy,
                  );

                  if (!context.mounted) return;

                  if (sosId != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Đã gửi SOS')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gửi SOS thất bại')),
                    );
                  }
                },

                child: const Icon(Icons.sos, color: Colors.white),
              ),
            ),
          ),
          if (familyId != null) IncomingSosOverlay(familyId: familyId),
        ],
      ),
    );
  }

  // @override
  // void dispose() {
  //   final controller = context.read<MapboxController>();

  //   controller.removeListener(_handleMapOrDataChange);

  //   context.read<ParentLocationVm>().removeListener(_handleMapOrDataChange);

  //   context.read<UserVm>().removeListener(_handleUserChange);
  //   controller.detach(); // <--- THÊM DÒNG NÀY (rất quan trọng)

  //   super.dispose();
  // }

  @override
  void dispose() {
    //  remove listener bằng biến đã cache
    _controller.removeListener(_handleMapOrDataChange);
    _locationVm.removeListener(_handleMapOrDataChange);
    _userVm.removeListener(_handleUserChange);
    sosFocusNotifier.removeListener(_onSosFocus);
    //  detach controller (rất quan trọng)
    _controller.detach();

    super.dispose();
  }
}
