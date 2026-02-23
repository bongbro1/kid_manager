import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as osm;

import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/widgets/location/map_bottom_controls.dart';
import 'package:kid_manager/widgets/location/map_top_bar.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';

class ChildLocationScreen extends StatefulWidget {
  const ChildLocationScreen({super.key});

  @override
  State<ChildLocationScreen> createState() =>
      _ChildLocationScreenState();
}

class _ChildLocationScreenState
    extends State<ChildLocationScreen> {

  MapboxMap? _map;
  PointAnnotationManager? _annotationManager;
  PointAnnotation? _marker;

  bool _autoFollow = true;

  // =========================================================
  // START GPS
  // =========================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChildLocationViewModel>()
          .startLocationSharing();
    });
  }

  // =========================================================
  // UPDATE MARKER
  // =========================================================

  Future<void> _updateLocation(
      double lat,
      double lng,
      ) async {

    if (_map == null) return;

    final point = Point(
      coordinates: Position(lng, lat),
    );

    if (_annotationManager == null) {
      _annotationManager =
      await _map!.annotations
          .createPointAnnotationManager();
    }

    if (_marker == null) {
      _marker =
      await _annotationManager!.create(
        PointAnnotationOptions(
          geometry: point,
          iconSize: 1.2,
        ),
      );
    } else {
      _marker!.geometry = point;
      await _annotationManager!
          .update(_marker!);
    }

    if (_autoFollow) {
      await _map!.easeTo(
        CameraOptions(
          center: point,
          zoom: 16,
        ),
        MapAnimationOptions(duration: 600),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final vm =
    context.watch<ChildLocationViewModel>();

    final loc = vm.currentLocation;

    if (loc != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        _updateLocation(
          loc.latitude,
          loc.longitude,
        );
      });
    }

    return Stack(
      children: [
        /// MAPBOX
        AppMapView(
          onMapCreated: (map) {
            _map = map;
          },
        ),

        /// TOP BAR
        MapTopBar(
          onMenuTap: () {},
          onAvatarTap: () {},
        ),

        /// MY LOCATION BUTTON
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
                    center: Point(
                      coordinates: Position(
                        loc.longitude,
                        loc.latitude,
                      ),
                    ),
                    zoom: 16,
                  ),
                  MapAnimationOptions(duration: 600),
                );
              },
            ),
          ),
        ),

        /// ERROR
        if (vm.error != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: _ErrorBanner(
              message: vm.error!,
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade600,
      borderRadius:
      BorderRadius.circular(12),
      child: Padding(
        padding:
        const EdgeInsets.all(12),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}