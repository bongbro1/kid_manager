import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/features/map_engine/controllers/camera_controller.dart';
import 'package:kid_manager/features/safe_route/data/datasources/safe_route_remote_data_source.dart';
import 'package:kid_manager/features/safe_route/data/repositories/safe_route_repository_impl.dart';
import 'package:kid_manager/features/safe_route/domain/entities/route_point.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route.dart';
import 'package:kid_manager/features/safe_route/domain/entities/safe_route_enums.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_active_trip_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_route_by_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_suggested_routes_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/get_trip_history_by_child_id_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/start_trip_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/stream_live_location_usecase.dart';
import 'package:kid_manager/features/safe_route/domain/usecases/update_trip_status_usecase.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_l10n.dart';
import 'package:kid_manager/features/safe_route/presentation/safe_route_tracking_visuals.dart';
import 'package:kid_manager/features/safe_route/presentation/pages/safe_route_history_page.dart';
import 'package:kid_manager/features/safe_route/presentation/states/safe_route_tracking_state.dart';
import 'package:kid_manager/features/safe_route/presentation/viewmodels/safe_route_tracking_view_model.dart';
import 'package:kid_manager/features/safe_route/presentation/widgets/safe_route_bottom_panel.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/services/location/map_avatar_marker_factory.dart';
import 'package:kid_manager/utils/cupertino_time_picker.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/map/app_map_view.dart';
import 'package:kid_manager/widgets/map/map_place_search_sheet.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({
    super.key,
    required this.childId,
    this.childAvatarUrl,
    this.initialStartPoint,
  });

  final String childId;
  final String? childAvatarUrl;
  final RoutePoint? initialStartPoint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ChangeNotifierProvider(
      create: (_) {
        final repository = SafeRouteRepositoryImpl(
          FirebaseSafeRouteRemoteDataSource(),
        );
        final viewModel = SafeRouteTrackingViewModel(
          childId: childId,
          getSuggestedRoutesUseCase: GetSuggestedRoutesUseCase(repository),
          startTripUseCase: StartTripUseCase(repository),
          streamLiveLocationUseCase: StreamLiveLocationUseCase(repository),
          updateTripStatusUseCase: UpdateTripStatusUseCase(repository),
          getActiveTripByChildIdUseCase: GetActiveTripByChildIdUseCase(
            repository,
          ),
          getTripHistoryByChildIdUseCase: GetTripHistoryByChildIdUseCase(
            repository,
          ),
          getRouteByIdUseCase: GetRouteByIdUseCase(repository),
          l10n: l10n,
        );

        if (initialStartPoint != null) {
          viewModel.applyInitialStartPoint(initialStartPoint!);
        }
        viewModel.initialize();
        return viewModel;
      },
      child: _TrackingPageBody(childAvatarUrl: childAvatarUrl),
    );
  }
}

class _TrackingPageBody extends StatefulWidget {
  const _TrackingPageBody({this.childAvatarUrl});

  final String? childAvatarUrl;

  @override
  State<_TrackingPageBody> createState() => _TrackingPageBodyState();
}

class _TrackingPageBodyState extends State<_TrackingPageBody> {
  static const _emptyGeoJson = '{"type":"FeatureCollection","features":[]}';

  static const _routeSourceId = 'safe-route-source';
  static const _progressSourceId = 'safe-route-progress-source';
  static const _altRouteSourceId = 'safe-route-alt-route-source';
  static const _liveSourceId = 'safe-route-live-source';
  static const _startSourceId = 'safe-route-start-source';
  static const _endSourceId = 'safe-route-end-source';
  static const _hazardSourceId = 'safe-route-hazard-source';
  static const _hazardAreaSourceId = 'safe-route-hazard-area-source';
  static const _liveMarkerIconProperty = 'live_icon_id';
  static const _liveAccuracyProperty = 'accuracy_radius';
  static const _childMarkerSafeIconId = 'safe-route-child-marker-safe';
  static const _childMarkerWarningIconId = 'safe-route-child-marker-warning';
  static const _childMarkerDangerIconId = 'safe-route-child-marker-danger';

  static const _corridorLayerId = 'safe-route-corridor-layer';
  static const _altRouteLayerId = 'safe-route-alt-route-layer';
  static const _routeLayerId = 'safe-route-line-layer';
  static const _progressLayerId = 'safe-route-progress-layer';
  static const _liveAccuracyLayerId = 'safe-route-live-accuracy-layer';
  static const _liveLayerId = 'safe-route-live-layer';
  static const _startLayerId = 'safe-route-start-layer';
  static const _endLayerId = 'safe-route-end-layer';
  static const _hazardAreaLayerId = 'safe-route-hazard-area-layer';
  static const _hazardLayerId = 'safe-route-hazard-layer';

  MapboxMap? _map;
  CameraController? _camera;
  String? _lastRenderedRouteId;
  String? _lastErrorMessage;
  bool _focusedOnce = false;
  bool _showHazards = true;
  bool _isAutoFollowEnabled = true;
  bool _safeRouteStyleReady = false;
  Future<void>? _safeRouteStyleSetupFuture;
  RouteSelectionMode _lastSelectionMode = RouteSelectionMode.none;
  int? _lastAutoFollowTimestamp;
  DateTime? _lastAutoFollowAt;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final AppMapViewController _mapViewController = AppMapViewController();

  @override
  void initState() {
    super.initState();
    _prefetchChildMarkerImages();
  }

  void _prefetchChildMarkerImages() {
    unawaited(
      Future.wait([
        MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFF2563EB),
          size: 72,
        ),
        MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFFF59E0B),
          size: 72,
        ),
        MapAvatarMarkerFactory.build(
          photoUrlOrData: widget.childAvatarUrl,
          accentColor: const Color(0xFFEF4444),
          size: 72,
        ),
      ]),
    );
  }

  Future<void> _ensureSafeRouteStyle() async {
    if (_safeRouteStyleReady) return;
    final existingSetup = _safeRouteStyleSetupFuture;
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
        _GeneratedStyleImage image,
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
      await addSourceIfNeeded(_progressSourceId);
      await addSourceIfNeeded(_altRouteSourceId);
      await addSourceIfNeeded(_liveSourceId);
      await addSourceIfNeeded(_startSourceId);
      await addSourceIfNeeded(_endSourceId);
      await addSourceIfNeeded(_hazardSourceId);
      await addSourceIfNeeded(_hazardAreaSourceId);

      await addStyleImageIfNeeded(
        _childMarkerSafeIconId,
        await _buildChildMarkerIcon(const Color(0xFF2563EB)),
      );
      await addStyleImageIfNeeded(
        _childMarkerWarningIconId,
        await _buildChildMarkerIcon(const Color(0xFFF59E0B)),
      );
      await addStyleImageIfNeeded(
        _childMarkerDangerIconId,
        await _buildChildMarkerIcon(const Color(0xFFEF4444)),
      );

      await addLayerIfNeeded(
        FillLayer(
          id: _hazardAreaLayerId,
          sourceId: _hazardAreaSourceId,
          fillColor: 0x33EF4444,
          fillOutlineColor: 0x55F87171,
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
          id: _corridorLayerId,
          sourceId: _routeSourceId,
          lineColor: 0x5534A853,
          lineWidth: 18,
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
        LineLayer(
          id: _progressLayerId,
          sourceId: _progressSourceId,
          lineColor: 0xFF10B981,
          lineWidth: 7,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _hazardLayerId,
          sourceId: _hazardSourceId,
          circleRadius: 6,
          circleColor: 0xFFFFFFFF,
          circleStrokeWidth: 3,
          circleStrokeColor: 0xFFDC2626,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _startLayerId,
          sourceId: _startSourceId,
          circleRadius: 7,
          circleColor: 0xFF2563EB,
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
        CircleLayer(
          id: _liveAccuracyLayerId,
          sourceId: _liveSourceId,
          circleRadius: 20,
          circleColor: 0x002563EB,
          circleStrokeWidth: 1.8,
          circleStrokeColor: 0x4D2563EB,
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

    _safeRouteStyleSetupFuture = setup();
    try {
      await _safeRouteStyleSetupFuture;
      _safeRouteStyleReady = true;
    } finally {
      _safeRouteStyleSetupFuture = null;
    }
  }

  Future<_GeneratedStyleImage> _buildChildMarkerIcon(Color color) async {
    final markerImage = await MapAvatarMarkerFactory.build(
      photoUrlOrData: widget.childAvatarUrl,
      accentColor: color,
      size: 72,
    );
    return _GeneratedStyleImage(
      width: markerImage.width,
      height: markerImage.height,
      bytes: markerImage.bytes,
    );
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
    if (map == null) {
      _log('updateGeoJsonSource skipped: map is null for $sourceId');
      return;
    }

    final source = await map.style.getSource(sourceId);
    final features = featureCollection['features'];
    final featureCount = features is List ? features.length : -1;

    _log(
      'updateGeoJsonSource: sourceId=$sourceId, '
      'sourceType=${source.runtimeType}, '
      'featureCount=$featureCount, '
      'data=${jsonEncode(featureCollection)}',
    );

    if (source is GeoJsonSource) {
      await source.updateGeoJSON(jsonEncode(featureCollection));
      _log('source updated: $sourceId');
    } else {
      _log('source $sourceId is not GeoJsonSource');
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

  Future<void> _showPickedPointMarker(
    RoutePoint point,
    RouteSelectionMode mode,
  ) async {
    await _ensureSafeRouteStyle();
    await _updateGeoJsonSource(
      mode == RouteSelectionMode.selectingEnd ? _endSourceId : _startSourceId,
      _pointCollection(point),
    );
  }

  Map<String, dynamic> _liveLocationCollection(SafeRouteTrackingState state) {
    final live = state.liveLocation;
    if (live == null) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    final visuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: AppLocalizations.of(context),
      fallbackStatusLabel: AppLocalizations.of(context).safeRouteTripStatusActive,
    );
    final iconId = switch (visuals.severity) {
      SafeRouteTrackingSeverity.safe => _childMarkerSafeIconId,
      SafeRouteTrackingSeverity.warning => _childMarkerWarningIconId,
      SafeRouteTrackingSeverity.danger => _childMarkerDangerIconId,
    };

    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [live.longitude, live.latitude],
          },
          'properties': {
            'speed': live.speedKmh,
            'batteryLevel': live.batteryLevel,
            _liveMarkerIconProperty: iconId,
            _liveAccuracyProperty: live.accuracyMeters,
          },
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
          'properties': {
            'routeId': route.id,
            'corridorWidthMeters': route.corridorWidthMeters,
          },
        },
      ],
    };
  }

  Map<String, dynamic> _routeProgressCollection(SafeRouteTrackingState state) {
    final route = state.activeRoute;
    final live = state.liveLocation;
    if (state.activeTrip == null || route == null || live == null) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    final progressPoints = _routeProgressPoints(
      route: route,
      liveLatitude: live.latitude,
      liveLongitude: live.longitude,
    );

    if (progressPoints.length < 2) {
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
              for (final point in progressPoints)
                [point.longitude, point.latitude],
            ],
          },
          'properties': {'routeId': route.id},
        },
      ],
    };
  }

  List<RoutePoint> _routeProgressPoints({
    required SafeRoute route,
    required double liveLatitude,
    required double liveLongitude,
  }) {
    final points = [...route.points]..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (points.length < 2) return const [];

    final projection = _projectLocationOntoRoute(
      latitude: liveLatitude,
      longitude: liveLongitude,
      points: points,
    );

    final progress = <RoutePoint>[];
    for (var index = 0; index <= projection.segmentIndex; index++) {
      progress.add(points[index]);
    }

    final projectedPoint = RoutePoint(
      latitude: projection.projectedLatitude,
      longitude: projection.projectedLongitude,
      sequence: projection.segmentIndex + 1,
    );

    final last = progress.isEmpty ? null : progress.last;
    if (last == null ||
        !_isSameCoordinate(
          last.latitude,
          last.longitude,
          projectedPoint.latitude,
          projectedPoint.longitude,
        )) {
      progress.add(projectedPoint);
    }

    return progress;
  }

  Map<String, dynamic> _alternativeRouteCollection(
    SafeRouteTrackingState state,
  ) {
    final alternatives = state.activeTrip != null
        ? state.activeAlternativeRoutes
            .where((route) => route.points.length >= 2)
            .toList(growable: false)
        : state.suggestedRoutes
            .where(
              (route) =>
                  route.id != state.selectedRoute?.id &&
                  route.points.length >= 2 &&
                  state.selectedAlternativeRouteIds.contains(route.id),
            )
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

  Map<String, dynamic> _hazardCollection(SafeRoute? route) {
    if (route == null || route.hazards.isEmpty) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        for (final hazard in route.hazards)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [hazard.longitude, hazard.latitude],
            },
            'properties': {
              'hazardId': hazard.id,
              'riskLevel': hazard.riskLevel.name,
            },
          },
      ],
    };
  }

  Map<String, dynamic> _hazardAreaCollection(SafeRoute? route) {
    if (route == null || route.hazards.isEmpty) {
      return const {'type': 'FeatureCollection', 'features': []};
    }

    return {
      'type': 'FeatureCollection',
      'features': [
        for (final hazard in route.hazards)
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                _circlePolygon(
                  latitude: hazard.latitude,
                  longitude: hazard.longitude,
                  radiusMeters: hazard.radiusMeters,
                ),
              ],
            },
            'properties': {
              'hazardId': hazard.id,
              'riskLevel': hazard.riskLevel.name,
            },
          },
      ],
    };
  }

  List<List<double>> _circlePolygon({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    int steps = 28,
  }) {
    const earthRadius = 6378137.0;
    final latRad = latitude * math.pi / 180.0;
    final lonRad = longitude * math.pi / 180.0;
    final angularDistance = radiusMeters / earthRadius;

    final coordinates = <List<double>>[];
    for (var index = 0; index <= steps; index++) {
      final bearing = 2 * math.pi * (index / steps);
      final nextLat = math.asin(
        math.sin(latRad) * math.cos(angularDistance) +
            math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
      );
      final nextLon =
          lonRad +
          math.atan2(
            math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
            math.cos(angularDistance) - math.sin(latRad) * math.sin(nextLat),
          );
      coordinates.add([nextLon * 180.0 / math.pi, nextLat * 180.0 / math.pi]);
    }

    return coordinates;
  }

  List<SafeRoute> _visibleRoutes(SafeRouteTrackingState state) {
    if (state.activeTrip != null) {
      return [
        if (state.activeRoute != null) state.activeRoute!,
        ...state.activeAlternativeRoutes.where(
          (route) => route.id != state.activeRoute?.id,
        ),
      ];
    }

    return [
      if (state.selectedRoute != null) state.selectedRoute!,
      ...state.suggestedRoutes.where(
        (route) =>
            route.id != state.selectedRoute?.id &&
            state.selectedAlternativeRouteIds.contains(route.id),
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

  _RouteProjection _projectLocationOntoRoute({
    required double latitude,
    required double longitude,
    required List<RoutePoint> points,
  }) {
    _RouteProjection? best;
    for (var index = 0; index < points.length - 1; index++) {
      final projection = _projectOntoSegment(
        latitude: latitude,
        longitude: longitude,
        start: points[index],
        end: points[index + 1],
        segmentIndex: index,
      );
      if (best == null ||
          projection.distanceFromRouteMeters < best.distanceFromRouteMeters) {
        best = projection;
      }
    }
    return best!;
  }

  _RouteProjection _projectOntoSegment({
    required double latitude,
    required double longitude,
    required RoutePoint start,
    required RoutePoint end,
    required int segmentIndex,
  }) {
    final metersPerLat = 111320.0;
    final cosValue = math.cos(latitude * math.pi / 180.0).abs();
    final metersPerLng = 111320.0 * cosValue.clamp(0.0001, 1.0).toDouble();

    final ax = (start.longitude - longitude) * metersPerLng;
    final ay = (start.latitude - latitude) * metersPerLat;
    final bx = (end.longitude - longitude) * metersPerLng;
    final by = (end.latitude - latitude) * metersPerLat;

    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;

    var t = 0.0;
    if (lengthSquared > 0) {
      t = (-(ax * dx + ay * dy) / lengthSquared).clamp(0.0, 1.0).toDouble();
    }

    final qx = ax + dx * t;
    final qy = ay + dy * t;
    final projectedLongitude = longitude + (qx / metersPerLng);
    final projectedLatitude = latitude + (qy / metersPerLat);

    return _RouteProjection(
      segmentIndex: segmentIndex,
      distanceFromRouteMeters: math.sqrt(qx * qx + qy * qy),
      projectedLatitude: projectedLatitude,
      projectedLongitude: projectedLongitude,
    );
  }

  bool _isSameCoordinate(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return (lat1 - lat2).abs() < 0.000001 && (lng1 - lng2).abs() < 0.000001;
  }

  double _distanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;

  Future<void> _fitToVisibleRoutesIfNeeded(
    SafeRouteTrackingState state,
  ) async {
    final camera = _camera;
    final routes = _visibleRoutes(state);
    if (camera == null || routes.isEmpty) return;

    final routeKey = routes.map((route) => route.id).join('|');
    if (_lastRenderedRouteId == routeKey) return;

    _lastRenderedRouteId = routeKey;
    await camera.fitToRoute(_routesAsLocationData(routes));
  }

  Future<void> _focusVisibleRoutes(SafeRouteTrackingState state) async {
    final camera = _camera;
    final routes = _visibleRoutes(state);
    if (camera == null || routes.isEmpty) return;
    await camera.fitToRoute(_routesAsLocationData(routes));
  }

  Future<void> _focusLiveLocationIfNeeded(SafeRouteTrackingState state) async {
    final map = _map;
    if (map == null || _focusedOnce) return;
    final live = state.liveLocation;
    if (live == null) return;
    _focusedOnce = true;

    await map.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(live.longitude, live.latitude)),
        zoom: 15.5,
      ),
    );
  }

  Future<void> _maybeAutoFollowLiveLocation(
    SafeRouteTrackingState state,
  ) async {
    final map = _map;
    final live = state.liveLocation;
    if (map == null ||
        !_isAutoFollowEnabled ||
        live == null ||
        state.activeTrip == null ||
        state.selectionMode != RouteSelectionMode.none) {
      return;
    }

    final lastTimestamp = _lastAutoFollowTimestamp;
    if (lastTimestamp == live.timestamp) return;

    final now = DateTime.now();
    if (_lastAutoFollowAt != null &&
        now.difference(_lastAutoFollowAt!) < const Duration(seconds: 2)) {
      return;
    }

    final cameraState = await map.getCameraState();
    final center = cameraState.center.coordinates;
    final distanceFromCenter = _distanceMeters(
      center.lat.toDouble(),
      center.lng.toDouble(),
      live.latitude,
      live.longitude,
    );

    final shouldFollow =
        !_focusedOnce ||
        distanceFromCenter > 35 ||
        (_lastAutoFollowAt != null &&
            now.difference(_lastAutoFollowAt!) > const Duration(seconds: 8) &&
            distanceFromCenter > 12);

    if (!shouldFollow) return;

    _lastAutoFollowTimestamp = live.timestamp;
    _lastAutoFollowAt = now;
    _focusedOnce = true;

    await map.easeTo(
      CameraOptions(
        center: Point(coordinates: Position(live.longitude, live.latitude)),
        zoom: math.max(cameraState.zoom, 15.3),
        bearing: cameraState.bearing,
        pitch: cameraState.pitch,
      ),
      MapAnimationOptions(duration: 900),
    );
  }

  void _log(String message) {
    debugPrint('[TrackingPage] $message');
  }

  String _pointLabel(RoutePoint? point) {
    if (point == null) return 'null';
    return '(${point.latitude}, ${point.longitude}, seq=${point.sequence})';
  }

  Future<void> _syncMap(SafeRouteTrackingState state) async {
    final activeOrSelectedRoute = state.activeRoute ?? state.selectedRoute;

    _log(
      'syncMap: '
      'mode=${state.selectionMode}, '
      'selectedStart=${_pointLabel(state.selectedStart)}, '
      'selectedEnd=${_pointLabel(state.selectedEnd)}, '
      'activeRouteStart=${_pointLabel(state.activeRoute?.startPoint)}, '
      'activeRouteEnd=${_pointLabel(state.activeRoute?.endPoint)}, '
      'activeRouteId=${state.activeRoute?.id}, '
      'selectedRouteId=${state.selectedRoute?.id}',
    );

    await _ensureSafeRouteStyle();

    await _updateGeoJsonSource(
      _routeSourceId,
      _routeCollection(activeOrSelectedRoute),
    );
    await _updateGeoJsonSource(
      _progressSourceId,
      _routeProgressCollection(state),
    );

    await _updateGeoJsonSource(
      _altRouteSourceId,
      _alternativeRouteCollection(state),
    );

    await _updateGeoJsonSource(
      _hazardSourceId,
      _showHazards
          ? _hazardCollection(activeOrSelectedRoute)
          : const {'type': 'FeatureCollection', 'features': []},
    );
    await _updateGeoJsonSource(
      _hazardAreaSourceId,
      _showHazards
          ? _hazardAreaCollection(activeOrSelectedRoute)
          : const {'type': 'FeatureCollection', 'features': []},
    );

    await _updateGeoJsonSource(
      _startSourceId,
      _pointCollection(state.selectedStart ?? state.activeRoute?.startPoint),
    );

    await _updateGeoJsonSource(
      _endSourceId,
      _pointCollection(state.selectedEnd ?? state.activeRoute?.endPoint),
    );

    await _updateGeoJsonSource(_liveSourceId, _liveLocationCollection(state));

    await _fitToVisibleRoutesIfNeeded(state);
    await _focusLiveLocationIfNeeded(state);
    await _maybeAutoFollowLiveLocation(state);
  }

  void _scheduleSync(SafeRouteTrackingState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _syncMap(state);
    });
  }

  void _syncSheetForSelectionMode(SafeRouteTrackingState state) {
    if (_lastSelectionMode == state.selectionMode) return;
    _lastSelectionMode = state.selectionMode;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_sheetController.isAttached) return;

      final targetSize = state.selectionMode == RouteSelectionMode.none
          ? (state.activeTrip != null ? 0.28 : 0.46)
          : 0.14;

      try {
        await _sheetController.animateTo(
          targetSize,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    });
  }

  void _maybeShowError(SafeRouteTrackingViewModel vm) {
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

  Widget _buildSelectionBanner(
    SafeRouteTrackingState state,
    SafeRouteTrackingViewModel vm,
  ) {
    if (state.selectionMode == RouteSelectionMode.none) {
      return const SizedBox.shrink();
    }

    final text = state.selectionMode == RouteSelectionMode.selectingStart
        ? AppLocalizations.of(context).safeRouteMapHintTapStart
        : AppLocalizations.of(context).safeRouteMapHintTapEnd;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 122,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: vm.cancelSelection,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _focusLiveLocation(SafeRouteTrackingState state) async {
    final map = _map;
    if (map == null) return;
    final live = state.liveLocation;
    if (live == null) return;

    await map.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(live.longitude, live.latitude)),
        zoom: 15.8,
      ),
    );
  }

  Future<void> _toggleHazards(SafeRouteTrackingState state) async {
    setState(() => _showHazards = !_showHazards);
    await _syncMap(state);
  }

  Future<void> _toggleAutoFollow(SafeRouteTrackingState state) async {
    final nextValue = !_isAutoFollowEnabled;
    setState(() => _isAutoFollowEnabled = nextValue);

    if (nextValue) {
      _lastAutoFollowTimestamp = null;
      _lastAutoFollowAt = null;
      await _focusLiveLocation(state);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(
          nextValue
              ? AppLocalizations.of(context).safeRouteSnackbarAutoFollowEnabled
              : AppLocalizations.of(context).safeRouteSnackbarAutoFollowDisabled,
        ),
      ),
    );
  }

  String _lastUpdatedLabel(SafeRouteTrackingState state) {
    final timestamp = state.liveLocation?.timestamp;
    if (timestamp == null) return '--';

    final updatedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return AppLocalizations.of(context).safeRouteUpdatedLabel(updatedAt);
  }

  String _topTitle(SafeRouteTrackingState state) {
    final l10n = AppLocalizations.of(context);
    return state.activeTrip == null
        ? l10n.safeRoutePageSelectRouteTitle
        : l10n.safeRoutePageJourneyTitle;
  }

  Future<void> _moveCameraToPoint(RoutePoint point) async {
    final map = _map;
    if (map == null) return;
    await map.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(point.longitude, point.latitude)),
        zoom: 15.6,
      ),
    );
  }

  Future<void> _searchStartPlace(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final result = await showMapPlaceSearchSheet(
      context: context,
      title: AppLocalizations.of(context).safeRouteSearchStartTitle,
      hintText: AppLocalizations.of(context).safeRouteSearchStartHint,
      initialQuery: state.selectedStartLabel ?? '',
      proximityLatitude: state.liveLocation?.latitude,
      proximityLongitude: state.liveLocation?.longitude,
    );
    if (!mounted || result == null) return;

    final point = RoutePoint(
      latitude: result.latitude,
      longitude: result.longitude,
      sequence: 0,
    );
    vm.setStartPoint(point, label: result.name);
    await _moveCameraToPoint(point);
  }

  Future<void> _searchEndPlace(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final proximityLat =
        state.selectedStart?.latitude ?? state.liveLocation?.latitude;
    final proximityLng =
        state.selectedStart?.longitude ?? state.liveLocation?.longitude;

    final result = await showMapPlaceSearchSheet(
      context: context,
      title: AppLocalizations.of(context).safeRouteSearchEndTitle,
      hintText: AppLocalizations.of(context).safeRouteSearchEndHint,
      initialQuery: state.selectedEndLabel ?? '',
      proximityLatitude: proximityLat,
      proximityLongitude: proximityLng,
    );
    if (!mounted || result == null) return;

    final point = RoutePoint(
      latitude: result.latitude,
      longitude: result.longitude,
      sequence: 1,
    );
    vm.setEndPoint(point, label: result.name);
    await _moveCameraToPoint(point);
  }

  String _topSubtitle(
    SafeRouteTrackingState state,
    SafeRouteTrackingViewModel vm,
  ) {
    final l10n = AppLocalizations.of(context);
    if (state.activeTrip != null) {
      if (state.activeTrip!.status == TripStatus.planned) {
        return l10n.safeRouteScheduledAutoActivationPrefix(
          _scheduleSummaryLabel(state),
        );
      }
      final visuals = resolveSafeRouteTrackingVisuals(
        state,
        l10n: l10n,
        fallbackStatusLabel: vm.safetyStatusLabel,
      );
      final prefix = switch (visuals.severity) {
        SafeRouteTrackingSeverity.safe => _currentRouteUsageLabel(state),
        SafeRouteTrackingSeverity.warning => l10n.safeRouteTopSubtitleWarning,
        SafeRouteTrackingSeverity.danger => l10n.safeRouteTopSubtitleDanger,
      };
      return '$prefix · ${_formatTime(DateTime.fromMillisecondsSinceEpoch(state.liveLocation?.timestamp ?? DateTime.now().millisecondsSinceEpoch))}';
    }

    final start = state.selectedStart;
    final end = state.selectedEnd;
    if (start != null && end != null) {
      return l10n.safeRouteTopSubtitleReady;
    }
    if (start != null) {
      return l10n.safeRouteTopSubtitleOnlyStart;
    }
    return l10n.safeRouteTopSubtitleChoosePoints;
  }

  String _dateChipLabel(SafeRouteTrackingState state) {
    final l10n = AppLocalizations.of(context);
    if (state.activeTrip != null) {
      final startedAt = state.activeTrip!.startedAt;
      return '${startedAt.day.toString().padLeft(2, '0')}/${startedAt.month.toString().padLeft(2, '0')}/${startedAt.year}';
    }
    final scheduled = state.scheduledDate;
    if (scheduled == null) {
      return l10n.safeRouteTodayLabel;
    }
    final normalized = DateTime(scheduled.year, scheduled.month, scheduled.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (normalized == today) {
      return l10n.safeRouteTodayLabel;
    }
    if (normalized == tomorrow) {
      return l10n.safeRouteTomorrowLabel;
    }
    return '${scheduled.day.toString().padLeft(2, '0')}/${scheduled.month.toString().padLeft(2, '0')}/${scheduled.year}';
  }

  String _timeChipLabel(SafeRouteTrackingState state) {
    if (state.activeTrip != null) {
      final startedAt = state.activeTrip!.startedAt;
      final liveTimestamp =
          state.liveLocation?.timestamp ??
          DateTime.now().millisecondsSinceEpoch;
      return '${_formatTime(startedAt)} – ${_formatTime(DateTime.fromMillisecondsSinceEpoch(liveTimestamp))}';
    }
    return _scheduleSummaryLabel(state);
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _scheduleSummaryLabel(SafeRouteTrackingState state) {
    return AppLocalizations.of(context).safeRouteScheduleSummary(
      state.scheduledTime,
      state.repeatWeekdays,
    );
  }

  String _currentRouteUsageLabel(SafeRouteTrackingState state) {
    final l10n = AppLocalizations.of(context);
    final trip = state.activeTrip;
    final activeRoute = state.activeRoute;
    if (trip == null || activeRoute == null) {
      return l10n.notificationJustNow;
    }
    return l10n.safeRouteCurrentRouteUsageLabel(
      activeRoute.id,
      trip.routeId,
      trip.alternativeRouteIds,
    );
  }

  Future<void> _pickScheduleDate(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.scheduledDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: AppLocalizations.of(context).safeRouteSelectScheduleDateHelp,
      cancelText: AppLocalizations.of(context).cancelButton,
      confirmText: AppLocalizations.of(context).confirmButton,
    );
    if (!mounted || picked == null) return;
    vm.setScheduledDate(picked);
  }

  Future<void> _pickScheduleTime(
    SafeRouteTrackingViewModel vm,
    SafeRouteTrackingState state,
  ) async {
    final picked = await AppWheelTimePicker.show(
      context,
      title: AppLocalizations.of(context).safeRouteSelectScheduleTimeTitle,
      initial: state.scheduledTime,
      primaryColor: const Color(0xFF1A73E8),
      minuteInterval: 1,
    );
    if (!mounted || picked == null) return;
    vm.setScheduledTime(picked);
  }

  Future<void> _showTripHistory(SafeRouteTrackingViewModel vm) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SafeRouteHistoryPage(
          childId: vm.state.childId,
          childAvatarUrl: widget.childAvatarUrl,
        ),
      ),
    );
  }

  Future<void> _showArrivedSuccessDialog(
    SafeRouteTrackingViewModel vm,
  ) async {
    await NotificationDialog.show(
      context,
      type: DialogType.success,
      title: AppLocalizations.of(context).safeRouteArrivedDialogTitle,
      message: AppLocalizations.of(context).safeRouteArrivedDialogMessage,
      confirmText: AppLocalizations.of(context).safeRouteArrivedDialogConfirm,
      onConfirm: vm.returnToRouteSelection,
    );
  }

  Future<void> _handleCompleteTrip(SafeRouteTrackingViewModel vm) async {
    final activeTrip = vm.state.activeTrip;
    if (activeTrip == null) return;

    if (activeTrip.status == TripStatus.completed) {
      vm.returnToRouteSelection();
      return;
    }

    await vm.completeTrip();
    if (!mounted) return;

    if (vm.state.activeTrip?.status == TripStatus.completed) {
      await _showArrivedSuccessDialog(vm);
    }
  }

  Future<void> _confirmCancelTrip(SafeRouteTrackingViewModel vm) async {
    final activeTrip = vm.state.activeTrip;
    if (activeTrip == null) return;

    final isPlanned = activeTrip.status == TripStatus.planned;
    await NotificationDialog.show(
      context,
      type: DialogType.warning,
      title: isPlanned
          ? AppLocalizations.of(context).safeRouteCancelPlannedTitle
          : AppLocalizations.of(context).safeRouteCancelActiveTitle,
      message: isPlanned
          ? AppLocalizations.of(context).safeRouteCancelPlannedMessage
          : AppLocalizations.of(context).safeRouteCancelActiveMessage,
      confirmText: isPlanned
          ? AppLocalizations.of(context).safeRouteCancelPlannedConfirm
          : AppLocalizations.of(context).safeRouteCancelActiveConfirm,
      cancelText: AppLocalizations.of(context).safeRouteDialogBack,
      onConfirm: () {
        unawaited(vm.cancelTrip());
      },
    );
  }

  Widget _buildTopBar(
    SafeRouteTrackingState state,
    SafeRouteTrackingViewModel vm,
  ) {
    final visuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: AppLocalizations.of(context),
      fallbackStatusLabel: vm.safetyStatusLabel,
    );
    final isActiveTrip = state.activeTrip != null;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 14,
      right: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isActiveTrip ? 0.94 : 0.90),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActiveTrip
                    ? visuals.borderColor.withOpacity(0.82)
                    : Colors.white.withOpacity(0.55),
              ),
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
                _buildCircleAction(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _topTitle(state),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color:
                              visuals.severity ==
                                  SafeRouteTrackingSeverity.danger
                              ? const Color(0xFF991B1B)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: visuals.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _topSubtitle(state, vm),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: visuals.accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildChildAvatarBadge(),
                const SizedBox(width: 10),
                _buildCircleAction(
                  icon: Icons.refresh_rounded,
                  onTap: vm.refreshActiveTrip,
                  tint: isActiveTrip ? visuals.softColor : null,
                  iconColor: isActiveTrip ? visuals.accentColor : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeaderChip(
                icon: Icons.calendar_today_rounded,
                label: _dateChipLabel(state),
                tint: isActiveTrip ? visuals.softColor : Colors.white,
                foregroundColor: isActiveTrip
                    ? visuals.accentColor
                    : const Color(0xFF475467),
                borderColor: isActiveTrip
                    ? visuals.borderColor.withOpacity(0.72)
                    : const Color(0xFFE5E7EB),
              ),
              _buildHeaderChip(
                icon: Icons.schedule_rounded,
                label: _timeChipLabel(state),
                tint: isActiveTrip ? visuals.softColor : Colors.white,
                foregroundColor: isActiveTrip
                    ? visuals.accentColor
                    : const Color(0xFF475467),
                borderColor: isActiveTrip
                    ? visuals.borderColor.withOpacity(0.72)
                    : const Color(0xFFE5E7EB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required VoidCallback onTap,
    Color? tint,
    Color? iconColor,
  }) {
    return Material(
      color: tint ?? Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 18,
            color: iconColor ?? const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildChildAvatarBadge() {
    final avatarUrl = widget.childAvatarUrl?.trim() ?? '';
    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFDBEAFE),
          width: 1.6,
        ),
      ),
      child: avatarUrl.isEmpty
          ? const Icon(
              Icons.child_care_rounded,
              size: 18,
              color: Color(0xFF2563EB),
            )
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.child_care_rounded,
                size: 18,
                color: Color(0xFF2563EB),
              ),
            ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required Color tint,
    required Color foregroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls(SafeRouteTrackingState state) {
    final visuals = resolveSafeRouteTrackingVisuals(
      state,
      l10n: AppLocalizations.of(context),
      fallbackStatusLabel: AppLocalizations.of(context).safeRouteTripStatusActive,
    );
    return Positioned(
      right: 14,
      top: MediaQuery.of(context).padding.top + 132,
      child: Column(
        children: [
          _buildMapFab(
            icon: Icons.my_location_rounded,
            onTap: () => _focusLiveLocation(state),
            tooltip: AppLocalizations.of(context).safeRouteTooltipFocusChild,
          ),
          const SizedBox(height: 10),
          _buildMapFab(
            icon: Icons.gps_fixed_rounded,
            onTap: () => _toggleAutoFollow(state),
            active: _isAutoFollowEnabled,
            tooltip: _isAutoFollowEnabled
                ? AppLocalizations.of(context).safeRouteTooltipDisableAutoFollow
                : AppLocalizations.of(context).safeRouteTooltipEnableAutoFollow,
            label: AppLocalizations.of(context).safeRouteAutoFollowLabel,
            showLabel: true,
          ),
          const SizedBox(height: 10),
          _buildMapFab(
            icon: Icons.warning_amber_rounded,
            onTap: () => _toggleHazards(state),
            active: _showHazards,
            activeColor: visuals.accentColor,
            tooltip: _showHazards
                ? AppLocalizations.of(context).safeRouteTooltipHideHazards
                : AppLocalizations.of(context).safeRouteTooltipShowHazards,
          ),
          const SizedBox(height: 10),
          _buildMapFab(
            icon: Icons.layers_rounded,
            onTap: _mapViewController.showMapSelector,
            tooltip: AppLocalizations.of(context).safeRouteTooltipMapType,
          ),
        ],
      ),
    );
  }

  Widget _buildMapFab({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    bool active = false,
    Color activeColor = const Color(0xFF1A73E8),
    String? label,
    bool showLabel = false,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: active ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 3,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
          if (showLabel && label != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: active ? activeColor : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSelectionBottomHint(SafeRouteTrackingState state) {
    if (state.selectionMode == RouteSelectionMode.none) {
      return const SizedBox.shrink();
    }

    final text = state.selectionMode == RouteSelectionMode.selectingStart
        ? AppLocalizations.of(context).safeRouteMapHintPlaceStart
        : AppLocalizations.of(context).safeRouteMapHintPlaceEnd;

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.map_rounded, size: 18, color: Color(0xFF1A73E8)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SafeRouteTrackingViewModel>(
      builder: (context, vm, _) {
        _scheduleSync(vm.state);
        _syncSheetForSelectionMode(vm.state);
        _maybeShowError(vm);

        final state = vm.state;
        final isSelectingOnMap = state.selectionMode != RouteSelectionMode.none;
        final initialSheetSize = isSelectingOnMap
            ? 0.14
            : (state.activeTrip != null ? 0.28 : 0.46);
        final minSheetSize = isSelectingOnMap
            ? 0.12
            : (state.activeTrip != null ? 0.22 : 0.30);

        return Scaffold(
          body: Stack(
            children: [
              AppMapView(
                controller: _mapViewController,
                showInternalMapTypeButton: false,
                onMapCreated: (map) {
                  _map = map;
                  _camera = CameraController(map);
                },
                onStyleLoaded: (map) async {
                  _map = map;
                  _camera = CameraController(map);
                  _safeRouteStyleReady = false;
                  _safeRouteStyleSetupFuture = null;
                  _lastRenderedRouteId = null;
                  _focusedOnce = false;
                  await _ensureSafeRouteStyle();
                  await _syncMap(state);
                },
                onTapListener: (gesture) async {
                  final vm = context.read<SafeRouteTrackingViewModel>();
                  final latestState = vm.state;

                  _log(
                    'tap received with latest mode=${latestState.selectionMode}',
                  );

                  if (latestState.selectionMode == RouteSelectionMode.none) {
                    _log('tap ignored because latest selectionMode = none');
                    return;
                  }

                  final coordinates = gesture.point.coordinates;
                  final mode = latestState.selectionMode;

                  _log(
                    'map tapped: mode=$mode, lat=${coordinates.lat}, lng=${coordinates.lng}',
                  );

                  final pickedPoint = RoutePoint(
                    latitude: coordinates.lat.toDouble(),
                    longitude: coordinates.lng.toDouble(),
                    sequence: mode == RouteSelectionMode.selectingEnd ? 1 : 0,
                  );

                  await _showPickedPointMarker(pickedPoint, mode);

                  vm.onMapPointSelected(
                    pickedPoint.latitude,
                    pickedPoint.longitude,
                  );

                  await _moveCameraToPoint(pickedPoint);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 1200),
                      content: Text(
                        mode == RouteSelectionMode.selectingEnd
                            ? AppLocalizations.of(
                                context,
                              ).safeRouteSnackbarSelectedEndPoint
                            : AppLocalizations.of(
                                context,
                              ).safeRouteSnackbarSelectedStartPoint,
                      ),
                    ),
                  );
                },
              ),
              _buildTopBar(state, vm),
              if (isSelectingOnMap) _buildSelectionBanner(state, vm),
              if (!isSelectingOnMap) _buildFloatingControls(state),
              if (!isSelectingOnMap)
                DraggableScrollableSheet(
                  controller: _sheetController,
                  initialChildSize: initialSheetSize,
                  minChildSize: minSheetSize,
                  maxChildSize: 0.82,
                  builder: (context, scrollController) {
                    return SafeRouteBottomPanel(
                      state: state,
                      safetyStatusLabel: vm.safetyStatusLabel,
                      speedLabel: vm.speedLabel,
                      batteryLabel: vm.batteryLabel,
                      lastUpdatedLabel: _lastUpdatedLabel(state),
                      scrollController: scrollController,
                      onUseLiveLocationAsStart: vm.useLiveLocationAsStart,
                      onSearchStart: () => _searchStartPlace(vm, state),
                      onSearchEnd: () => _searchEndPlace(vm, state),
                      onStartSelectingStart: vm.startSelectingStart,
                      onStartSelectingEnd: vm.startSelectingEnd,
                      onClearStart: vm.clearStartPoint,
                      onClearEnd: vm.clearEndPoint,
                      onSelectTravelMode: vm.selectTravelMode,
                      onSwapPoints: vm.swapSelectedPoints,
                      onPickScheduleDate: () => _pickScheduleDate(vm, state),
                      onPickScheduleTime: () => _pickScheduleTime(vm, state),
                      onResetSchedule: vm.resetSchedule,
                      onToggleRepeatWeekday: vm.toggleRepeatWeekday,
                      onShowHistory: () => _showTripHistory(vm),
                      onFetchSuggestedRoutes: vm.fetchSuggestedRoutes,
                      onSelectRoute: vm.selectSuggestedRoute,
                      onToggleAlternativeRoute: vm.toggleAlternativeSuggestedRoute,
                      onStartTrip: vm.startTrip,
                      onCompleteTrip: () => _handleCompleteTrip(vm),
                      onCancelTrip: () => _confirmCancelTrip(vm),
                      onFocusRoute: () => _focusVisibleRoutes(state),
                    );
                  },
                ),
              _buildMapSelectionBottomHint(state),
              if (state.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GeneratedStyleImage {
  const _GeneratedStyleImage({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final Uint8List bytes;
}

class _RouteProjection {
  const _RouteProjection({
    required this.segmentIndex,
    required this.distanceFromRouteMeters,
    required this.projectedLatitude,
    required this.projectedLongitude,
  });

  final int segmentIndex;
  final double distanceFromRouteMeters;
  final double projectedLatitude;
  final double projectedLongitude;
}

