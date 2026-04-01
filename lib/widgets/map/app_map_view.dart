import 'package:flutter/material.dart';
import 'package:kid_manager/core/enums/enums.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';
import 'package:kid_manager/widgets/map/map_ornaments.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class AppMapView extends StatefulWidget {
  final Function(MapboxMap) onMapCreated;
  final Future<void> Function(MapboxMap map)? onStyleLoaded;
  final void Function(MapContentGestureContext context)? onTapListener;
  final AppMapViewController? controller;
  final bool showInternalMapTypeButton;
  final bool followThemeForStreetStyle;

  const AppMapView({
    super.key,
    required this.onMapCreated,
    this.onStyleLoaded,
    this.onTapListener,
    this.controller,
    this.showInternalMapTypeButton = true,
    this.followThemeForStreetStyle = true,
  });

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class AppMapViewController {
  VoidCallback? _openMapSelector;

  void _bind(VoidCallback callback) {
    _openMapSelector = callback;
  }

  void _unbind() {
    _openMapSelector = null;
  }

  void showMapSelector() {
    _openMapSelector?.call();
  }
}

class _AppMapViewState extends State<AppMapView> {
  MapboxMap? _map;
  AppMapType _type = AppMapType.street;
  bool _disposed = false;
  int _mapGeneration = 0;

  /// Lưu camera để restore khi đổi style (tránh zoom lại)
  CameraOptions? _pendingCameraRestore;

  /// Camera mặc định (chỉ dùng khi lần đầu mở map)
  CameraOptions get _defaultCamera => CameraOptions(
    center: Point(coordinates: Position(105.8542, 21.0285)),
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(_showMapSelector);
  }

  @override
  void didUpdateWidget(covariant AppMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._unbind();
      widget.controller?._bind(_showMapSelector);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _mapGeneration++;
    _map = null;
    widget.controller?._unbind();
    super.dispose();
  }

  String get _styleUri {
    switch (_type) {
      case AppMapType.street:
        return widget.followThemeForStreetStyle &&
                Theme.of(context).brightness == Brightness.dark
            ? 'mapbox://styles/mapbox/dark-v11'
            : 'mapbox://styles/mapbox/streets-v12';
      case AppMapType.satellite:
        return 'mapbox://styles/mapbox/satellite-streets-v12';
      case AppMapType.terrain:
        return 'mapbox://styles/mapbox/outdoors-v12';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        MapWidget(
          key: ValueKey('app-map-$_styleUri'),
          styleUri: _styleUri,

          // ✅ set camera ngay từ đầu để tránh flash "zoom trái đất"
          cameraOptions: _pendingCameraRestore ?? _defaultCamera,

          // ✅ Mapbox v2.18 yêu cầu pixelRatio
          mapOptions: MapOptions(
            pixelRatio: MediaQuery.of(context).devicePixelRatio,
          ),
          onMapCreated: (map) {
            _mapGeneration++;
            _map = map;
            widget.onMapCreated(map);
          },
          onTapListener: widget.onTapListener,
          onStyleLoadedListener: (_) async {
            try {
              final map = _map;
              final generation = _mapGeneration;
              if (map == null) return;
              if (!_isMapGenerationActive(generation, map)) return;

              await hideMapOrnaments(map);
              if (!_isMapGenerationActive(generation, map)) return;

              // ✅ restore camera sau khi style load xong
              if (_pendingCameraRestore != null) {
                await map.setCamera(_pendingCameraRestore!);
                if (!_isMapGenerationActive(generation, map)) return;
                _pendingCameraRestore = null;
              }

              final cb = widget.onStyleLoaded;
              if (cb != null && _isMapGenerationActive(generation, map)) {
                await cb(map);
              }
            } catch (error) {
              if (_isMapLifecycleError(error)) {
                return;
              }
              rethrow;
            }
          },
        ),

        if (widget.showInternalMapTypeButton)
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: locationPanelColor(scheme),
              foregroundColor: scheme.primary,
              onPressed: _showMapSelector,
              child: const Icon(Icons.layers),
            ),
          ),
      ],
    );
  }

  Future<void> _showMapSelector() async {
    if (!mounted || _disposed) return;
    final scheme = Theme.of(context).colorScheme;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: locationPanelColor(scheme),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final l10n = AppLocalizations.of(context);

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
                    Expanded(
                      child: Text(
                        l10n.mapTypeSheetTitle,
                        style: const TextStyle(
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
                      title: l10n.mapTypeDefault,
                      type: AppMapType.street,
                      preview: _previewDefault(),
                    ),
                    _mapTypeCard(
                      title: l10n.mapTypeSatellite,
                      type: AppMapType.satellite,
                      preview: _previewSatellite(),
                    ),
                    _mapTypeCard(
                      title: l10n.mapTypeTerrain,
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
    final scheme = Theme.of(context).colorScheme;
    final selected = _type == type;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        if (!mounted || _disposed) return;
        // ✅ lưu camera hiện tại trước khi đổi style
        final map = _map;
        if (map != null) {
          final cs = await map.getCameraState();
          if (!mounted || _disposed) return;
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
                color: selected
                    ? scheme.primary
                    : locationPanelBorderColor(scheme),
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
              color: selected ? scheme.primary : scheme.onSurface,
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

  bool _isMapGenerationActive(int generation, MapboxMap map) {
    return mounted &&
        !_disposed &&
        generation == _mapGeneration &&
        identical(_map, map);
  }

  bool _isMapLifecycleError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('mapboxcontroller was used after being disposed') ||
        text.contains('unable to establish connection on channel') ||
        text.contains('flutterjni was detached');
  }
}
