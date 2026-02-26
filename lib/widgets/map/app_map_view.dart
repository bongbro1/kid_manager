import 'package:flutter/material.dart';
import 'package:kid_manager/core/enums/enums.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AppMapView extends StatefulWidget {
  final Function(MapboxMap) onMapCreated;
  final Future<void> Function(MapboxMap map)? onStyleLoaded;

  const AppMapView({
    super.key,
    required this.onMapCreated,
    this.onStyleLoaded,
  });

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  MapboxMap? _map;
  AppMapType _type = AppMapType.street;

  /// Lưu camera để restore khi đổi style (tránh zoom lại)
  CameraOptions? _pendingCameraRestore;

  /// Camera mặc định (chỉ dùng khi lần đầu mở map)
  CameraOptions get _defaultCamera => CameraOptions(
    center: Point(coordinates: Position(105.8542, 21.0285)),
    zoom: 13,
  );

  String get _styleUri {
    switch (_type) {
      case AppMapType.street:
        return Theme.of(context).brightness == Brightness.dark
            ? "mapbox://styles/mapbox/dark-v11"
            : "mapbox://styles/mapbox/streets-v12";
      case AppMapType.satellite:
        return "mapbox://styles/mapbox/satellite-streets-v12";
      case AppMapType.terrain:
        return "mapbox://styles/mapbox/outdoors-v12";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          // key theo style => đổi style sẽ reload đúng
          key: ValueKey("app-map-$_styleUri"),
          styleUri: _styleUri,

          // ✅ set camera ngay từ đầu để tránh flash "zoom trái đất"
          cameraOptions: _pendingCameraRestore ?? _defaultCamera,

          // ✅ Mapbox v2.18 yêu cầu pixelRatio
          mapOptions: MapOptions(
            pixelRatio: MediaQuery.of(context).devicePixelRatio,
          ),

          onMapCreated: (map) async {
            _map = map;
            widget.onMapCreated(map);
          },

          onStyleLoadedListener: (_) async {
            final map = _map;
            if (map == null) return;

            // ✅ restore camera sau khi style load xong
            if (_pendingCameraRestore != null) {
              await map.setCamera(_pendingCameraRestore!);
              _pendingCameraRestore = null;
            }

            final cb = widget.onStyleLoaded;
            if (cb != null) await cb(map);
          },
        ),

        Positioned(
          right: 16,
          bottom: 120,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.white,
            onPressed: _showMapSelector,
            child: const Icon(Icons.layers, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Future<void> _showMapSelector() async {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Loại bản đồ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                  children: [
                    _mapTypeCard(
                      title: "Mặc định",
                      type: AppMapType.street,
                      preview: _previewDefault(),
                    ),
                    _mapTypeCard(
                      title: "Vệ tinh",
                      type: AppMapType.satellite,
                      preview: _previewSatellite(),
                    ),
                    _mapTypeCard(
                      title: "Địa hình",
                      type: AppMapType.terrain,
                      preview: _previewTerrain(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mapTypeCard({
    required String title,
    required AppMapType type,
    required Widget preview,
  }) {
    final selected = _type == type;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        // ✅ lưu camera hiện tại trước khi đổi style
        final map = _map;
        if (map != null) {
          final cs = await map.getCameraState();
          _pendingCameraRestore = CameraOptions(
            center: cs.center,
            zoom: cs.zoom,
            bearing: cs.bearing,
            pitch: cs.pitch,
          );
        }

        setState(() => _type = type);
        if (mounted) Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? const Color(0xFF1A73E8) : Colors.transparent,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 74,
                width: double.infinity,
                child: preview,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? const Color(0xFF1A73E8) : null,
            ),
          ),
        ],
      ),
    );
  }

  // --- Preview thumbnails (tạm thời). Bạn có thể thay bằng Image.asset() sau.

  Widget _previewDefault() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF2FF), Color(0xFFD7F5E5)],
        ),
      ),
      child: const Center(child: Icon(Icons.map_outlined)),
    );
  }

  Widget _previewSatellite() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E2E2E), Color(0xFF6B6B6B)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.satellite_alt_outlined, color: Colors.white),
      ),
    );
  }

  Widget _previewTerrain() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE7F4E4), Color(0xFFCDE7FF)],
        ),
      ),
      child: const Center(child: Icon(Icons.terrain_outlined)),
    );
  }
}