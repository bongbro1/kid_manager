import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:provider/provider.dart';

import 'package:kid_manager/features/presentation/shared/state/map_view_controller.dart';
import 'package:kid_manager/features/presentation/shared/map_config.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/viewmodels/location/parent_location_view_model.dart';
import 'package:kid_manager/widgets/location/map_bottom_controls.dart';
import 'package:kid_manager/widgets/location/map_search_bar.dart';
import 'package:kid_manager/widgets/location/map_top_bar.dart';

class MapBaseView extends StatefulWidget {
  final List<AppUser> children;
  final MapConfig config;
  final void Function(AppUser child)? onPickChild;
  final void Function(AppUser child)? onOpenChat;

  const MapBaseView({
    super.key,
    required this.children,
    required this.config,
    this.onPickChild,
    this.onOpenChat,
  });

  @override
  State<MapBaseView> createState() => _MapBaseViewState();
}

class _MapBaseViewState extends State<MapBaseView> {
  late final TextEditingController _searchCtl;

  @override
  void initState() {
    super.initState();
    _searchCtl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapVm = context.watch<MapViewController>();

    // ⚠️ Parent mới cần locationVm
    final ParentLocationVm? locationVm =
    widget.config.showChildrenPicker || widget.config.showSearch
        ? context.watch<ParentLocationVm>()
        : null;

    final markers = locationVm == null
        ? const <Marker>[]
        : mapVm.buildMarkers(
      children: widget.children,
      latestMap: locationVm.childrenLocations,
      onTapChild: widget.onPickChild,
    );

    return Stack(
      children: [
        /// ================= MAP =================
        FlutterMap(
          mapController: mapVm.controller,
          options: MapOptions(
            initialCenter: const osm.LatLng(21.0285, 105.8542),
            initialZoom: 13,
            onPositionChanged: (_, hasGesture) {
              if (hasGesture) {
                mapVm.setAutoFollow(false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),

        /// ================= TOP BAR =================
        MapTopBar(
          onMenuTap: () {},
          onAvatarTap: () {},
        ),

        /// ================= SEARCH =================
        if (widget.config.showSearch)
          MapSearchBar(
            controller: _searchCtl,
            topOffset: MediaQuery.paddingOf(context).top + 60,
            onSubmitted: (_) {},
            onFilterTap: () {},
          ),

        /// ================= BOTTOM CONTROLS =================
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: MapBottomControls(
              children: widget.children,
              onTapChild: widget.onPickChild,
              onMore: widget.config.showChildrenPicker
                  ? () {
              }
                  : null,
              onMyLocation: () => mapVm.fitCurrent(),
            ),
          ),
        ),
      ],
    );
  }
}
