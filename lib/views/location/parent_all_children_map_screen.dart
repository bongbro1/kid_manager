import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kid_manager/features/presentation/shared/state/map_view_controller.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/viewmodels/location/parent_location_view_model.dart';
import 'package:kid_manager/widgets/location/child_info_sheet.dart';
import 'package:kid_manager/widgets/location/children_picker_sheet.dart';
import 'package:kid_manager/widgets/location/map_bottom_controls.dart';
import 'package:kid_manager/widgets/location/map_search_bar.dart';
import 'package:kid_manager/widgets/location/map_top_bar.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

bool isValidLatLng(osm.LatLng p) =>
    p.latitude.isFinite &&
        p.longitude.isFinite &&
        p.latitude >= -90 &&
        p.latitude <= 90 &&
        p.longitude >= -180 &&
        p.longitude <= 180;

class ParentAllChildrenMapScreen extends StatelessWidget {
  final List<AppUser> children;

  const ParentAllChildrenMapScreen({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapViewController()),
      ],
      child: _ParentAllChildrenMapView(children: children),
    );
  }
}

class _ParentAllChildrenMapView extends StatefulWidget {
  final List<AppUser> children;

  const _ParentAllChildrenMapView({required this.children});

  @override
  State<_ParentAllChildrenMapView> createState() =>
      _ParentAllChildrenMapViewState();
}

class _ParentAllChildrenMapViewState
    extends State<_ParentAllChildrenMapView> {
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _openInfoSheet({
    required AppUser child,
    required LocationData latest,
  }) {
    final locationVM = context.read<ParentLocationVm>();
    final mapVm = context.read<MapViewController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => ChildInfoSheet(
        child: child,
        latest: latest,
        isSearching: mapVm.isRouteActive,
        onOpenChat: () {},
        onSendQuickMessage: (message) async {
          // TODO: nối ChatRepository/ChatViewModel sau
          // hiện tại demo: chỉ đóng sheet
          // await Future.delayed(const Duration(milliseconds: 200));
        },
        onToggleSearch: () async {
          Navigator.pop(context);

          final history =
          await locationVM.loadLocationHistory(child.uid);

          final points = history
              .map((e) => osm.LatLng(e.latitude, e.longitude))
              .where(isValidLatLng)
              .toList();

          mapVm.toggleRoute(points);
        },
      ),
    );
  }

  void _openChildrenPicker(Map<String, LocationData> latestMap) {
    final mapVm = context.read<MapViewController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => ChildrenPickerSheet(
        children: widget.children,
        latestMap: latestMap,
        onPick: (child, latest) {
          Navigator.pop(context);

          final p = osm.LatLng(latest.latitude, latest.longitude);
          if (!isValidLatLng(p)) return;

          mapVm.moveTo(p);

          _openInfoSheet(
            child: child,
            latest: latest,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationVM = context.watch<ParentLocationVm>();
    final mapVm = context.watch<MapViewController>();

    final latestMap = locationVM.childrenLocations;
    final markers = <Marker>[];

    for (final child in widget.children) {
      final latest = latestMap[child.uid];
      if (latest == null) continue;

      final p = osm.LatLng(latest.latitude, latest.longitude);
      if (!isValidLatLng(p)) continue;

      markers.add(
        Marker(
          key: ValueKey(child.uid),
          point: p,
          width: 90,
          height: 90,
          child: GestureDetector(
            onTap: () {
              mapVm.moveTo(p);
              _openInfoSheet(child: child, latest: latest);
            },
            child: Column(
              children: [
                _ChildLabel(child.displayName ?? ''),
                const Icon(Icons.location_pin,
                    color: Colors.red, size: 44),
              ],
            ),
          ),
        ),
      );
    }

    // fit tất cả marker lần đầu (khi chưa bật route)
    if (!mapVm.isRouteActive) {
      mapVm.fitOnce(markers.map((m) => m.point).toList());
    }

    final safeCenter = markers.isNotEmpty
        ? markers.first.point
        : const osm.LatLng(21.0285, 105.8542);

    final topInset = MediaQuery.paddingOf(context).top;
    final searchTop = topInset + 52 + 10;

    return Stack(
      children: [
        FlutterMap(
          mapController: mapVm.controller,
          options: MapOptions(
            initialCenter: safeCenter,
            initialZoom: 13,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.kid_manager',
            ),

            if (mapVm.isRouteActive)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: mapVm.routePoints,
                    strokeWidth: 6,
                    color: Colors.blue,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                ...markers,
                if (mapVm.routePoints.length >= 2) ...[
                  Marker(
                    point: mapVm.routePoints.first,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin,
                        color: Colors.green, size: 36),
                  ),
                  Marker(
                    point: mapVm.routePoints.last,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 36),
                  ),
                ],
              ],
            ),
          ],
        ),

        MapTopBar(onMenuTap: () {}, onAvatarTap: () {}),

        MapSearchBar(
          controller: _searchCtl,
          topOffset: searchTop,
          onSubmitted: (_) {},
          onFilterTap: () {},
        ),

        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: MapBottomControls(
              children: widget.children,
              onTapChild: (child) {
                final latest = latestMap[child.uid];
                if (latest == null) return;

                final p =
                osm.LatLng(latest.latitude, latest.longitude);
                if (!isValidLatLng(p)) return;

                mapVm.moveTo(p);
                _openInfoSheet(child: child, latest: latest);
              },
              onMore: () => _openChildrenPicker(latestMap),
              onMyLocation: () {
                if (mapVm.isRouteActive) {
                  mapVm.fitRoute();
                } else {
                  mapVm.fitPoints(
                    markers.map((m) => m.point).toList(),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ChildLabel extends StatelessWidget {
  final String text;

  const _ChildLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(blurRadius: 3, color: Colors.black26)
        ],
      ),
      child: Text(
        text,
        style:
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
