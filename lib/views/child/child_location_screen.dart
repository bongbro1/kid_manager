import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:kid_manager/features/map_engine/map_engine.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/widgets/location/map_bottom_controls.dart';
import 'package:kid_manager/widgets/location/map_top_bar.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';

class ChildLocationScreen extends StatefulWidget {
  const ChildLocationScreen({super.key});

  @override
  State<ChildLocationScreen> createState() => _ChildLocationScreenState();
}

class _ChildLocationScreenState extends State<ChildLocationScreen> {
  MapboxMap? _map;
  MapEngine? _engine;

  bool _autoFollow = true;
  VoidCallback? _vmListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildLocationViewModel>().startLocationSharing();
    });
  }
  @override
  void dispose() {
    final vm = context.read<ChildLocationViewModel>();
    if (_vmListener != null) vm.removeListener(_vmListener!);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChildLocationViewModel>();

    return Stack(
      children: [
        AppMapView(
          onMapCreated: (map) {
            _map = map;
          },
            onStyleLoaded: (map) async {
              _engine = MapEngine(map, enableChildDot: true); // ✅ quan trọng
              await _engine!.init();

              final vm = context.read<ChildLocationViewModel>();

              // remove listener cũ nếu có
              if (_vmListener != null) vm.removeListener(_vmListener!);

              _vmListener = () {
                final loc = vm.currentLocation;
                if (loc == null) return;

                _engine?.updateChildRealtime(loc);

                if (_autoFollow) {
                  _map?.easeTo(
                    CameraOptions(
                      center: Point(coordinates: Position(loc.longitude, loc.latitude)),
                      zoom: 16,
                    ),
                    MapAnimationOptions(duration: 600),
                  );
                }
              };

              vm.addListener(_vmListener!);

              // update ngay nếu có
              final loc = vm.currentLocation;
              if (loc != null) await _engine!.updateChildRealtime(loc);
            },
        ),

        MapTopBar(
          onMenuTap: () {},
          onAvatarTap: () {},
        ),

        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: MapBottomControls(
              children: const [],
              onMyLocation: () {
                final loc = vm.currentLocation;
                if (loc == null) return;

                _autoFollow = true;

                _map?.easeTo(
                  CameraOptions(
                    center: Point(coordinates: Position(loc.longitude, loc.latitude)),
                    zoom: 16,
                  ),
                  MapAnimationOptions(duration: 600),
                );
              },
            ),
          ),
        ),

        if (vm.error != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: _ErrorBanner(message: vm.error!),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}