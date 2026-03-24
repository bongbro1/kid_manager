import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/features/map_engine/controllers/camera_controller.dart';
import 'package:kid_manager/features/safe_route/data/datasources/safe_route_remote_data_source.dart';
import 'package:kid_manager/features/safe_route/data/repositories/safe_route_repository_impl.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/entities/trip.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_trip_history_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_history_state.dart';
import 'package:kid_manager/features/safe_route/presentation/viewmodels/safe_route_history_view_model.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/services/location/map_avatar_marker_factory.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

class SafeRouteHistoryPage extends StatelessWidget {
  const SafeRouteHistoryPage({
    super.key,
    required this.childId,
    this.childAvatarUrl,
  });

  final String childId;
  final String? childAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final repository = SafeRouteRepositoryImpl(
          FirebaseSafeRouteRemoteDataSource(),
        );
        final viewModel = SafeRouteHistoryViewModel(
          childId: childId,
          getTripHistoryByChildIdUseCase: GetTripHistoryByChildIdUseCase(
            repository,
          ),
          getRouteByIdUseCase: GetRouteByIdUseCase(repository),
        );
        viewModel.initialize();
        return viewModel;
      },
      child: _SafeRouteHistoryPageBody(childAvatarUrl: childAvatarUrl),
    );
  }
}

class _SafeRouteHistoryPageBody extends StatefulWidget {
  const _SafeRouteHistoryPageBody({this.childAvatarUrl});

  final String? childAvatarUrl;

  @override
  State<_SafeRouteHistoryPageBody> createState() =>
      _SafeRouteHistoryPageBodyState();
}

class _SafeRouteHistoryPageBodyState extends State<_SafeRouteHistoryPageBody> {
  static const _emptyGeoJson = '{"type":"FeatureCollection","features":[]}';
  static const _routeSourceId = 'safe-route-history-source';
  static const _altRouteSourceId = 'safe-route-history-alt-source';
  static const _startSourceId = 'safe-route-history-start-source';
  static const _endSourceId = 'safe-route-history-end-source';
  static const _liveSourceId = 'safe-route-history-live-source';
  static const _liveMarkerIconProperty = 'live_icon_id';
  static const _liveMarkerIconId = 'safe-route-history-child-marker';
  static const _altRouteLayerId = 'safe-route-history-alt-layer';
  static const _routeLayerId = 'safe-route-history-layer';
  static const _startLayerId = 'safe-route-history-start-layer';
  static const _endLayerId = 'safe-route-history-end-layer';
  static const _liveLayerId = 'safe-route-history-live-layer';

  final AppMapViewController _mapViewController = AppMapViewController();

  MapboxMap? _map;
  CameraController? _camera;
  bool _styleReady = false;
  Future<void>? _styleSetupFuture;
  String? _lastRenderedRouteId;
  String? _lastErrorMessage;

  Future<void> _ensureHistoryStyle() async {
    if (_styleReady) return;
    final existingSetup = _styleSetupFuture;
    if (existingSetup != null) {
      await existingSetup;
      return;
    }

    final map = _map;
    if (map == null) return;
    final style = map.style;

    Future<void> setup() async {
      Future<void> addSourceIfNeeded(String id) async {
        try {
          await style.addSource(GeoJsonSource(id: id, data: _emptyGeoJson));
        } catch (error) {
          if (!_isAlreadyExistsError(error)) rethrow;
        }
      }

      Future<void> addLayerIfNeeded(Layer layer) async {
        try {
          await style.addLayer(layer);
        } catch (error) {
          if (!_isAlreadyExistsError(error)) rethrow;
        }
      }

      Future<void> addStyleImageIfNeeded(
        String id,
        MapAvatarMarkerImage image,
      ) async {
        try {
          await style.addStyleImage(
            id,
            1.0,
            MbxImage(
              width: image.width,
              height: image.height,
              data: image.bytes,
            ),
            false,
            [],
            [],
            null,
          );
        } catch (error) {
          if (!_isAlreadyExistsError(error)) rethrow;
        }
      }

      await addSourceIfNeeded(_routeSourceId);
      await addSourceIfNeeded(_altRouteSourceId);
      await addSourceIfNeeded(_startSourceId);
      await addSourceIfNeeded(_endSourceId);
      await addSourceIfNeeded(_liveSourceId);

      await addStyleImageIfNeeded(
        _liveMarkerIconId,
        await MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFF2563EB),
          size: 72,
        ),
      );

      await addLayerIfNeeded(
        LineLayer(
          id: _altRouteLayerId,
          sourceId: _altRouteSourceId,
          lineColor: 0xFFBFCCD9,
          lineWidth: 4,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        LineLayer(
          id: _routeLayerId,
          sourceId: _routeSourceId,
          lineColor: 0xFF1A73E8,
          lineWidth: 5,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _startLayerId,
          sourceId: _startSourceId,
          circleRadius: 7,
          circleColor: 0xFF1A73E8,
          circleStrokeWidth: 4,
          circleStrokeColor: 0xFFFFFFFF,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _endLayerId,
          sourceId: _endSourceId,
          circleRadius: 7,
          circleColor: 0xFF10B981,
          circleStrokeWidth: 4,
          circleStrokeColor: 0xFFFFFFFF,
        ),
      );
      await addLayerIfNeeded(
        SymbolLayer(
          id: _liveLayerId,
          sourceId: _liveSourceId,
          iconImageExpression: ['get', _liveMarkerIconProperty],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1.0,
        ),
      );
    }

    _styleSetupFuture = setup();
    try {
      await _styleSetupFuture;
      _styleReady = true;
    } finally {
      _styleSetupFuture = null;
    }
  }

  bool _isAlreadyExistsError(Object error) {
    return error is PlatformException &&
        (error.message?.contains('already exists') ?? false);
  }

  Future<void> _updateGeoJsonSource(
    String sourceId,
    Map<String, dynamic> featureCollection,
  ) async {
    final map = _map;
    if (map == null) return;
    final source = await map.style.getSource(sourceId);
    if (source is GeoJsonSource) {
      await source.updateGeoJSON(jsonEncode(featureCollection));
    }
  }

  Map<String, dynamic> _pointCollection(RoutePoint? point) {
    if (point == null) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [point.longitude, point.latitude],
          },
          'properties': {'sequence': point.sequence},
        },
      ],
    };
  }

  Map<String, dynamic> _routeCollection(SafeRoute? route) {
    if (route == null || route.points.length < 2) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final point in route.points)
                [point.longitude, point.latitude],
            ],
          },
          'properties': {'routeId': route.id},
        },
      ],
    };
  }

  Map<String, dynamic> _liveLocationCollection(SafeRouteHistoryState state) {
    final live = state.selectedTrip?.lastLocation;
    if (live == null) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [live.longitude, live.latitude],
          },
          'properties': {_liveMarkerIconProperty: _liveMarkerIconId},
        },
      ],
    };
  }

  Map<String, dynamic> _alternativeRouteCollection(
    SafeRouteHistoryState state,
  ) {
    final alternatives = state.selectedAlternativeRoutes
        .where((route) => route.points.length >= 2)
        .toList(growable: false);

    if (alternatives.isEmpty) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        for (final route in alternatives)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                for (final point in route.points)
                  [point.longitude, point.latitude],
              ],
            },
            'properties': {'routeId': route.id},
          },
      ],
    };
  }

  List<SafeRoute> _visibleRoutes(SafeRouteHistoryState state) {
    return [
      if (state.selectedRoute != null) state.selectedRoute!,
      ...state.selectedAlternativeRoutes.where(
        (route) => route.id != state.selectedRoute?.id,
      ),
    ];
  }

  List<LocationData> _routesAsLocationData(Iterable<SafeRoute> routes) {
    final points = <LocationData>[];
    final seen = <String>{};

    for (final route in routes) {
      for (final point in route.points) {
        final key = '${point.latitude},${point.longitude}';
        if (seen.add(key)) {
          points.add(
            LocationData(
              latitude: point.latitude,
              longitude: point.longitude,
              accuracy: 0,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }
    }

    return points;
  }

  List<LocationData> _viewportPoints(SafeRouteHistoryState state) {
    final points = _routesAsLocationData(_visibleRoutes(state));
    final live = state.selectedTrip?.lastLocation;
    if (live != null) {
      points.add(
        LocationData(
          latitude: live.latitude,
          longitude: live.longitude,
          accuracy: live.accuracyMeters,
          timestamp: live.timestamp,
        ),
      );
    }
    return points;
  }

  Future<void> _fitToRoutesIfNeeded(SafeRouteHistoryState state) async {
    final camera = _camera;
    final points = _viewportPoints(state);
    if (camera == null || points.isEmpty) return;
    final routeKey =
        '${state.selectedTrip?.id ?? 'none'}|${state.selectedTrip?.lastLocation?.timestamp ?? 0}|'
        '${_visibleRoutes(state).map((route) => route.id).join('|')}';
    if (_lastRenderedRouteId == routeKey) return;
    _lastRenderedRouteId = routeKey;
    await camera.fitToRoute(points);
  }

  Future<void> _syncMap(SafeRouteHistoryState state) async {
    await _ensureHistoryStyle();
    await _updateGeoJsonSource(
      _routeSourceId,
      _routeCollection(state.selectedRoute),
    );
    await _updateGeoJsonSource(
      _altRouteSourceId,
      _alternativeRouteCollection(state),
    );
    await _updateGeoJsonSource(
      _startSourceId,
      _pointCollection(state.selectedRoute?.startPoint),
    );
    await _updateGeoJsonSource(
      _endSourceId,
      _pointCollection(state.selectedRoute?.endPoint),
    );
    await _updateGeoJsonSource(_liveSourceId, _liveLocationCollection(state));
    await _fitToRoutesIfNeeded(state);
  }

  void _scheduleSync(SafeRouteHistoryState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _syncMap(state);
    });
  }

  void _maybeShowError(SafeRouteHistoryViewModel vm) {
    final error = vm.state.errorMessage;
    if (error == null || error == _lastErrorMessage) return;
    _lastErrorMessage = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      vm.clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SafeRouteHistoryViewModel>(
      builder: (context, vm, _) {
        final state = vm.state;
        _scheduleSync(state);
        _maybeShowError(vm);
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          backgroundColor: scheme.background,
          body: Stack(
            children: [
              Positioned.fill(
                child: AppMapView(
                  controller: _mapViewController,
                  showInternalMapTypeButton: false,
                  followThemeForStreetStyle: false,
                  onMapCreated: (map) {
                    _map = map;
                    _camera = CameraController(map);
                    _styleReady = false;
                    _styleSetupFuture = null;
                  },
                  onStyleLoaded: (map) async {
                    _map = map;
                    _styleReady = false;
                    _styleSetupFuture = null;
                    await _ensureHistoryStyle();
                    await _syncMap(state);
                  },
                ),
              ),
              _buildTopBar(state, vm),
              Positioned(
                right: 14,
                top: MediaQuery.of(context).padding.top + 82,
                child: Column(
                  children: [
                    _CircleActionButton(
                      icon: Icons.layers_rounded,
                      onTap: _mapViewController.showMapSelector,
                    ),
                    const SizedBox(height: 10),
                    _CircleActionButton(
                      icon: Icons.refresh_rounded,
                      onTap: vm.refresh,
                    ),
                  ],
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.42,
                minChildSize: 0.24,
                maxChildSize: 0.82,
                builder: (context, scrollController) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: locationPanelColor(scheme).withOpacity(0.97),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, -8),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: locationPanelBorderColor(scheme),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).safeRouteHistoryPageTitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.trips.isEmpty
                              ? AppLocalizations.of(
                                  context,
                                ).safeRouteHistoryTripsEmpty
                              : AppLocalizations.of(
                                  context,
                                ).safeRouteHistoryPageReviewSaved,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                        if (state.selectedTrip != null) ...[
                          const SizedBox(height: 14),
                          _SelectedTripSummaryCard(
                            trip: state.selectedTrip!,
                            route: state.selectedRoute,
                            alternativeRoutes: state.selectedAlternativeRoutes,
                            isLoadingRoute: state.isLoadingRoute,
                          ),
                        ],
                        const SizedBox(height: 14),
                        if (state.trips.isEmpty)
                          const _EmptyHistoryPageState()
                        else
                          ...state.trips.map(
                            (trip) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _HistoryTripCard(
                                trip: trip,
                                selected: state.selectedTrip?.id == trip.id,
                                onTap: () => vm.selectTrip(trip),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              if (state.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: CircularProgressIndicator(color: scheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(
    SafeRouteHistoryState state,
    SafeRouteHistoryViewModel vm,
  ) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final selectedTrip = state.selectedTrip;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 14,
      right: 14,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: locationPanelColor(scheme).withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _CircleActionButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.safeRouteHistoryPageTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedTrip == null
                        ? l10n.safeRouteHistoryPageReviewSaved
                        : '${_statusLabel(context, selectedTrip.status)} · ${_updatedLabel(context, selectedTrip.updatedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildChildAvatarBadge(),
            const SizedBox(width: 10),
            _CircleActionButton(icon: Icons.refresh_rounded, onTap: vm.refresh),
          ],
        ),
      ),
    );
  }

  Widget _buildChildAvatarBadge() {
    final scheme = Theme.of(context).colorScheme;
    final avatarUrl = widget.childAvatarUrl?.trim() ?? '';
    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locationPanelColor(scheme),
        border: Border.all(color: locationPanelBorderColor(scheme), width: 1.6),
      ),
      child: avatarUrl.isEmpty
          ? Icon(
              Icons.child_care_rounded,
              size: 18,
              color: scheme.primary,
            )
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.child_care_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ),
    );
  }

  String _statusLabel(BuildContext context, TripStatus status) {
    return AppLocalizations.of(context).safeRouteTripStatusLabel(status);
  }

  String _updatedLabel(BuildContext context, DateTime value) {
    return AppLocalizations.of(context).safeRouteDateTimeShortLabel(value);
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: locationPanelColor(scheme),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _SelectedTripSummaryCard extends StatelessWidget {
  const _SelectedTripSummaryCard({
    required this.trip,
    required this.route,
    required this.alternativeRoutes,
    required this.isLoadingRoute,
  });

  final Trip trip;
  final SafeRoute? route;
  final List<SafeRoute> alternativeRoutes;
  final bool isLoadingRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: locationPanelMutedColor(scheme),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: locationPanelBorderColor(scheme)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.routeName?.trim().isNotEmpty == true
                      ? trip.routeName!
                      : l10n.safeRouteSelectedRouteFallbackName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: trip.status),
            ],
          ),
          const SizedBox(height: 10),
          if (route != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.route_rounded,
                  label: l10n.safeRouteDistanceLabel(route!.distanceMeters),
                ),
                _InfoChip(
                  icon: Icons.schedule_rounded,
                  label: l10n.safeRouteDurationLabel(route!.durationSeconds),
                ),
                _InfoChip(
                  icon: Icons.warning_amber_rounded,
                  label: l10n.safeRouteHazardCount(route!.hazards.length),
                ),
              ],
            )
          else if (isLoadingRoute)
            const LinearProgressIndicator(minHeight: 4),
          const SizedBox(height: 10),
          Text(
            _scheduleSummary(l10n, trip),
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _scheduleSummary(AppLocalizations l10n, Trip trip) {
    final parts = <String>[];
    if (trip.scheduledStartAt != null) {
      parts.add(l10n.safeRouteDateTimeLabel(trip.scheduledStartAt!));
    } else {
      parts.add(l10n.safeRouteTrackNowLabel);
    }
    if (trip.repeatWeekdays.isNotEmpty) {
      parts.add(l10n.safeRouteRepeatSummary(trip.repeatWeekdays));
    }
    return parts.join(' · ');
  }
}

class _HistoryTripCard extends StatelessWidget {
  const _HistoryTripCard({
    required this.trip,
    required this.selected,
    required this.onTap,
  });

  final Trip trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? locationPanelHighlightColor(scheme)
          : locationPanelMutedColor(scheme),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: locationPanelBorderColor(scheme),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? locationPanelHighlightColor(scheme)
                      : locationPanelColor(scheme),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.alt_route_rounded,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.routeName?.trim().isNotEmpty == true
                          ? trip.routeName!
                          : l10n.safeRouteRouteFallbackName(trip.routeId),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(l10n, trip),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: trip.status),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, Trip trip) {
    final parts = <String>[];
    parts.add(l10n.safeRouteDateTimeShortLabel(trip.updatedAt));
    if (trip.repeatWeekdays.isNotEmpty) {
      parts.add(l10n.safeRouteRepeatSummary(trip.repeatWeekdays));
    }
    return parts.join(' · ');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyle(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: style.foreground,
        ),
      ),
    );
  }

  _HistoryBadgeStyle _badgeStyle(BuildContext context, TripStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case TripStatus.completed:
        return _HistoryBadgeStyle(
          label: l10n.safeRouteTripStatusCompleted,
          background: const Color(0xFFE8F7ED),
          foreground: const Color(0xFF15803D),
        );
      case TripStatus.deviated:
        return _HistoryBadgeStyle(
          label: l10n.safeRouteTripStatusDeviated,
          background: const Color(0xFFFFE9E5),
          foreground: const Color(0xFFB93815),
        );
      case TripStatus.temporarilyDeviated:
        return _HistoryBadgeStyle(
          label: l10n.safeRouteTripStatusTemporarilyDeviated,
          background: const Color(0xFFFFF4DF),
          foreground: const Color(0xFFB45309),
        );
      case TripStatus.cancelled:
        return _HistoryBadgeStyle(
          label: l10n.safeRouteTripStatusCancelled,
          background: const Color(0xFFF1F5F9),
          foreground: const Color(0xFF475569),
        );
      case TripStatus.planned:
        return _HistoryBadgeStyle(
          label: l10n.safeRouteTripStatusPlanned,
          background: const Color(0xFFEFF6FF),
          foreground: const Color(0xFF1D4ED8),
        );
      case TripStatus.active:
        return _HistoryBadgeStyle(
          label: l10n.safeRouteTripStatusActive,
          background: const Color(0xFFEAF2FF),
          foreground: const Color(0xFF1A73E8),
        );
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: locationPanelColor(scheme),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: locationPanelBorderColor(scheme)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryPageState extends StatelessWidget {
  const _EmptyHistoryPageState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: locationPanelMutedColor(scheme),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: locationPanelBorderColor(scheme)),
      ),
      child: Text(
        AppLocalizations.of(context).safeRouteHistoryEmptyState,
        style: TextStyle(
          fontSize: 12,
          color: scheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    );
  }
}

class _HistoryBadgeStyle {
  const _HistoryBadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}
