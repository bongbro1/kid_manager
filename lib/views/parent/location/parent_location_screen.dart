import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/viewmodels/zones/zone_status_vm.dart';
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

class ParentAllChildrenMapScreen extends StatefulWidget {
  const ParentAllChildrenMapScreen({super.key});

  @override
  State<ParentAllChildrenMapScreen> createState() =>
      _ParentAllChildrenMapScreenState();
}

class _ParentAllChildrenMapScreenState extends State<ParentAllChildrenMapScreen> {
  bool _didInitialFit = false;
  mbx.MapboxMap? _map;

  String? _focusedChildId;

  Timer? _camDebounce;
  bool _inited = false;
  bool _didInitialFocus = false;

  late final UserVm _userVm;
  late final ParentLocationVm _locationVm;
  late final MapboxController _controller;
  late final ZoneStatusVm _zoneVm;

  Timer? _syncDebounce;
  Uint8List? _defaultAvatarBytes;

  @override
  void initState() {
    super.initState();
    sosFocusNotifier.addListener(_onSosFocus);

    // cache default bytes 1 lần
    Future.microtask(() async {
      final d = await rootBundle.load("assets/images/avatar_default.png");
      _defaultAvatarBytes = d.buffer.asUint8List();
    });
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

    _zoneVm = context.read<ZoneStatusVm>();
    _zoneVm.addListener(_onZoneBubbleChanged);

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

    final firstChildId = _userVm.children.first.uid;

    // chỉ focus khi có location
    final loc = _locationVm.childrenLocations[firstChildId];
    if (loc == null) return;

    _didInitialFocus = true;

    // ✅ focus và hiện bubble luôn
    await _focusChild(
      childId: firstChildId,
      openSheet: false,
      animate: false,
    );
  }

  Future<void> _focusChild({
    required String childId,
    bool openSheet = false,
    bool animate = false,
  }) async {
    if (!mounted || _map == null) return;

    setState(() => _focusedChildId = childId);

    // clear bubble cũ (đảm bảo chỉ có 1 bubble)
    await _controller.clearFocusBubble();

    // gọi load bubble realtime cho child này
    final myUid = _userVm.me?.uid;
    if (myUid != null) {
      _zoneVm.focus(viewerUid: myUid, childId: childId);
    }

    // zoom tới bé
    if (animate) {
      final duration = await _controller.zoomToChild(childId);
      await Future.delayed(Duration(milliseconds: duration));
    } else {
      // jump (không zoom từ trái đất)
      final pos = _controller.getChildPosition(childId);
      if (pos != null) {
        await _map!.setCamera(
          mbx.CameraOptions(
            center: mbx.Point(coordinates: pos),
            zoom: 16.5,
            pitch: 0,
            bearing: 0,
          ),
        );
      }
    }

    // show bubble ngay lập tức (placeholder), listener sẽ update text thật sau
    await _controller.setFocusBubble(
      childId: childId,
      text: "Đang tải...",
      icon: Icons.home,
    );

    if (openSheet) _openChildInfo(childId);
  }

  void _onZoneBubbleChanged() async {
    if (!mounted) return;
    final childId = _focusedChildId;
    final bubble = _zoneVm.bubble;
    if (childId == null || bubble == null) return;

    await _controller.setFocusBubble(
      childId: childId,
      text: bubble.text,
      icon: bubble.icon,
    );
  }

  void _handleMapOrDataChange() {
    if (!mounted) return;
    if (!_controller.isReady) return;

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 250), () async {
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
    final userVm = context.watch<UserVm>();
    final me = userVm.me;

    if (me == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final myUid = me.uid;
    final familyId = userVm.familyId;
    final children = List.of(userVm.children);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: mbx.MapWidget(
              key: const ValueKey("parent-map"),
              cameraOptions: mbx.CameraOptions(
                zoom: 15.5,
                center: mbx.Point(
                  coordinates: mbx.Position(105.8342, 21.0278),
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

              // ✅ tap vào child marker
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

                // ✅ chỉ gọi 1 nơi
                await _focusChild(
                  childId: childId,
                  openSheet: true,
                  animate: true,
                );
              },

              onStyleLoadedListener: (_) async {
                await _controller.onStyleLoaded();
                if (!mounted) return;

                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;

                  try {
                    final defaultBytes =
                        _defaultAvatarBytes ??
                            (await rootBundle.load("assets/images/avatar_default.png"))
                                .buffer
                                .asUint8List();

                    await _controller.setDefaultAvatar(defaultBytes);

                    final tasks = _userVm.children.map((c) {
                      return _controller.setAvatarSmart(
                        childId: c.uid,
                        photoUrlOrData: c.avatarUrl,
                        defaultBytes: defaultBytes,
                      );
                    }).toList();

                    await Future.wait(tasks);
                    await _syncToMap();
                    await _focusFirstChildOnce();
                  } catch (e, st) {
                    debugPrint("🔥 Setup Error: $e");
                    debugPrint("$st");
                  }
                });
              },

              onCameraChangeListener: (_) {
                if (_focusedChildId == null) return;
                _camDebounce?.cancel();
              },
            ),
          ),

          // SOS button
          Positioned(
            left: 12,
            top: 90,
            child: SafeArea(
              child: SosCircleButton(
                onPressed: () async {
                  final sosVm = context.read<SosViewModel>();
                  final myLocation = _locationVm.myLocation;
                  final displayName = context
                      .select<UserVm, String?>((vm) => vm.me?.displayName)
                      .toString();
                  if (myLocation == null) return;
                  if (sosVm.sending) return;

                  final sosId = await sosVm.triggerSos(
                    lat: myLocation.latitude,
                    lng: myLocation.longitude,
                    acc: myLocation.accuracy,
                    createdByName: displayName,
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sosId != null ? 'Đã gửi SOS' : 'Gửi SOS thất bại'),
                    ),
                  );
                },
              ),
            ),
          ),

          // bottom controls
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: SafeArea(
              child: MapBottomControls(
                children: children,
                onMyLocation: () async {
                  _didInitialFit = false;
                  await _syncToMap();
                },

                // ✅ tap avatar trong thanh dưới
                onTapChild: (child) async {
                  await _syncToMap();
                  await _focusChild(
                    childId: child.uid,
                    openSheet: true,
                    animate: true,
                  );
                },

                // ✅ mở list chọn child
                onMore: () async {
                  final selectedChild = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ParentChildrenListScreen()),
                  );
                  if (selectedChild == null) return;

                  await _syncToMap();
                  await _focusChild(
                    childId: selectedChild.uid,
                    openSheet: true,
                    animate: true,
                  );
                },
              ),
            ),
          ),

          // incoming SOS overlay
          if (familyId != null)
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
    _camDebounce?.cancel();

    _controller.removeListener(_handleMapOrDataChange);
    _locationVm.removeListener(_handleMapOrDataChange);
    _userVm.removeListener(_handleUserChange);

    _controller.clearFocusBubble();
    sosFocusNotifier.removeListener(_onSosFocus);

    _zoneVm.removeListener(_onZoneBubbleChanged);

    _controller.detach();
    super.dispose();
  }
}