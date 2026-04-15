part of kid_manager.safe_route.tracking_page;

extension _TrackingPageMapSync on _TrackingPageBodyState {
  Future<void> _ensureSafeRouteStyle() async {
    final map = _map;
    if (map == null) return;
    final session = _mapSession;
    if (!_isMapSessionActive(map, session)) return;
    if (_safeRouteStyleReady) return;

    final styleLoaded = await _runMapQuery<bool>(
      map: map,
      session: session,
      label: 'isStyleLoaded:safeRoute',
      call: () => map.style.isStyleLoaded(),
    );
    if (styleLoaded != true || !_isMapSessionActive(map, session)) {
      return;
    }

    final existingSetup = _safeRouteStyleSetupFuture;
    if (existingSetup != null && _safeRouteStyleSetupSession == session) {
      await existingSetup;
      return;
    }
    final style = map.style;

    Future<void> setup() async {
      Future<void> addSourceIfNeeded(String id) async {
        try {
          await _runMapWrite(
            map: map,
            session: session,
            label: 'addSource:$id',
            call: () => style.addSource(
              GeoJsonSource(id: id, data: _TrackingPageBodyState._emptyGeoJson),
            ),
          );
        } catch (error) {
          if (!_isAlreadyExistsError(error)) rethrow;
        }
      }

      Future<void> addLayerIfNeeded(Layer layer) async {
        try {
          await _runMapWrite(
            map: map,
            session: session,
            label: 'addLayer:${layer.id}',
            call: () => style.addLayer(layer),
          );
        } catch (error) {
          if (!_isAlreadyExistsError(error)) rethrow;
        }
      }

      Future<void> addStyleImageIfNeeded(
        String id,
        _GeneratedStyleImage image,
      ) async {
        try {
          await _runMapWrite(
            map: map,
            session: session,
            label: 'addStyleImage:$id',
            call: () => style.addStyleImage(
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
            ),
          );
        } catch (error) {
          if (!_isAlreadyExistsError(error)) rethrow;
        }
      }

      await addSourceIfNeeded(_TrackingPageBodyState._routeSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._progressSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._altRouteSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._liveSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._startSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._endSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._hazardSourceId);
      await addSourceIfNeeded(_TrackingPageBodyState._hazardAreaSourceId);

      await addStyleImageIfNeeded(
        _TrackingPageBodyState._childMarkerSafeIconId,
        await _buildChildMarkerIcon(const Color(0xFF2563EB)),
      );
      await addStyleImageIfNeeded(
        _TrackingPageBodyState._childMarkerWarningIconId,
        await _buildChildMarkerIcon(const Color(0xFFF59E0B)),
      );
      await addStyleImageIfNeeded(
        _TrackingPageBodyState._childMarkerDangerIconId,
        await _buildChildMarkerIcon(const Color(0xFFEF4444)),
      );

      await addLayerIfNeeded(
        FillLayer(
          id: _TrackingPageBodyState._hazardAreaLayerId,
          sourceId: _TrackingPageBodyState._hazardAreaSourceId,
          fillColor: 0x33EF4444,
          fillOutlineColor: 0x55F87171,
        ),
      );
      await addLayerIfNeeded(
        LineLayer(
          id: _TrackingPageBodyState._altRouteLayerId,
          sourceId: _TrackingPageBodyState._altRouteSourceId,
          lineColor: 0xFFBFCCD9,
          lineWidth: 4,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        LineLayer(
          id: _TrackingPageBodyState._corridorLayerId,
          sourceId: _TrackingPageBodyState._routeSourceId,
          lineColor: 0x5534A853,
          lineWidth: 18,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        LineLayer(
          id: _TrackingPageBodyState._routeLayerId,
          sourceId: _TrackingPageBodyState._routeSourceId,
          lineColor: 0xFF1A73E8,
          lineWidth: 5,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        LineLayer(
          id: _TrackingPageBodyState._progressLayerId,
          sourceId: _TrackingPageBodyState._progressSourceId,
          lineColor: 0xFF10B981,
          lineWidth: 7,
          lineCap: LineCap.ROUND,
          lineJoin: LineJoin.ROUND,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _TrackingPageBodyState._hazardLayerId,
          sourceId: _TrackingPageBodyState._hazardSourceId,
          circleRadius: 6,
          circleColor: 0xFFFFFFFF,
          circleStrokeWidth: 3,
          circleStrokeColor: 0xFFDC2626,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _TrackingPageBodyState._startLayerId,
          sourceId: _TrackingPageBodyState._startSourceId,
          circleRadius: 7,
          circleColor: 0xFF2563EB,
          circleStrokeWidth: 4,
          circleStrokeColor: 0xFFFFFFFF,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _TrackingPageBodyState._endLayerId,
          sourceId: _TrackingPageBodyState._endSourceId,
          circleRadius: 7,
          circleColor: 0xFF10B981,
          circleStrokeWidth: 4,
          circleStrokeColor: 0xFFFFFFFF,
        ),
      );
      await addLayerIfNeeded(
        CircleLayer(
          id: _TrackingPageBodyState._liveAccuracyLayerId,
          sourceId: _TrackingPageBodyState._liveSourceId,
          circleRadius: 20,
          circleColor: 0x002563EB,
          circleStrokeWidth: 1.8,
          circleStrokeColor: 0x4D2563EB,
        ),
      );
      await addLayerIfNeeded(
        SymbolLayer(
          id: _TrackingPageBodyState._liveLayerId,
          sourceId: _TrackingPageBodyState._liveSourceId,
          iconImageExpression: [
            'get',
            _TrackingPageBodyState._liveMarkerIconProperty,
          ],
          iconAllowOverlap: true,
          iconIgnorePlacement: true,
          iconAnchor: IconAnchor.CENTER,
          iconSize: 1.0,
        ),
      );
    }

    final future = setup();
    _safeRouteStyleSetupFuture = future;
    _safeRouteStyleSetupSession = session;
    try {
      await future;
      if (_isMapSessionActive(map, session)) {
        _safeRouteStyleReady = true;
      }
    } finally {
      if (_safeRouteStyleSetupSession == session &&
          identical(_safeRouteStyleSetupFuture, future)) {
        _safeRouteStyleSetupFuture = null;
        _safeRouteStyleSetupSession = null;
      }
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
    final session = _mapSession;
    if (map == null || !_safeRouteStyleReady) {
      _log('updateGeoJsonSource skipped: map/style not ready for $sourceId');
      return;
    }

    final source = await _runMapQuery<Object?>(
      map: map,
      session: session,
      label: 'getSource:$sourceId',
      call: () => map.style.getSource(sourceId),
    );
    if (!_isMapSessionActive(map, session)) {
      return;
    }
    final features = featureCollection['features'];
    final featureCount = features is List ? features.length : -1;

    _log(
      'updateGeoJsonSource: sourceId=$sourceId, '
      'sourceType=${source.runtimeType}, '
      'featureCount=$featureCount, '
      'data=${jsonEncode(featureCollection)}',
    );

    if (source is GeoJsonSource) {
      await _runMapWrite(
        map: map,
        session: session,
        label: 'updateGeoJSON:$sourceId',
        call: () async => source.updateGeoJSON(jsonEncode(featureCollection)),
      );
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
      mode == RouteSelectionMode.selectingEnd
          ? _TrackingPageBodyState._endSourceId
          : _TrackingPageBodyState._startSourceId,
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
      fallbackStatusLabel: AppLocalizations.of(
        context,
      ).safeRouteTripStatusActive,
    );
    final iconId = switch (visuals.severity) {
      SafeRouteTrackingSeverity.safe =>
        _TrackingPageBodyState._childMarkerSafeIconId,
      SafeRouteTrackingSeverity.warning =>
        _TrackingPageBodyState._childMarkerWarningIconId,
      SafeRouteTrackingSeverity.danger =>
        _TrackingPageBodyState._childMarkerDangerIconId,
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
            'isCharging': live.isCharging,
            _TrackingPageBodyState._liveMarkerIconProperty: iconId,
            _TrackingPageBodyState._liveAccuracyProperty: live.accuracyMeters,
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
    final points = [...route.points]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
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

  bool _isSameCoordinate(double lat1, double lng1, double lat2, double lng2) {
    return (lat1 - lat2).abs() < 0.000001 && (lng1 - lng2).abs() < 0.000001;
  }

  double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
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

  Future<void> _fitToVisibleRoutesIfNeeded(SafeRouteTrackingState state) async {
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
    final session = _mapSession;
    if (map == null || _focusedOnce) return;
    final live = state.liveLocation;
    if (live == null) return;
    _focusedOnce = true;

    await _runMapWrite(
      map: map,
      session: session,
      label: 'setCamera:focusLiveLocationIfNeeded',
      call: () => map.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(live.longitude, live.latitude)),
          zoom: 15.5,
        ),
      ),
    );
  }

  Future<void> _maybeAutoFollowLiveLocation(
    SafeRouteTrackingState state,
  ) async {
    final map = _map;
    final session = _mapSession;
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

    final cameraState = await _runMapQuery<CameraState>(
      map: map,
      session: session,
      label: 'getCameraState:autoFollow',
      call: () => map.getCameraState(),
    );
    if (cameraState == null || !_isMapSessionActive(map, session)) {
      return;
    }
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

    await _runMapWrite(
      map: map,
      session: session,
      label: 'easeTo:autoFollow',
      call: () => map.easeTo(
        CameraOptions(
          center: Point(coordinates: Position(live.longitude, live.latitude)),
          zoom: math.max(cameraState.zoom, 15.3),
          bearing: cameraState.bearing,
          pitch: cameraState.pitch,
        ),
        MapAnimationOptions(duration: 900),
      ),
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
    if (!mounted || _disposed) {
      return;
    }
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
      _TrackingPageBodyState._routeSourceId,
      _routeCollection(activeOrSelectedRoute),
    );
    await _updateGeoJsonSource(
      _TrackingPageBodyState._progressSourceId,
      _routeProgressCollection(state),
    );

    await _updateGeoJsonSource(
      _TrackingPageBodyState._altRouteSourceId,
      _alternativeRouteCollection(state),
    );

    await _updateGeoJsonSource(
      _TrackingPageBodyState._hazardSourceId,
      _showHazards
          ? _hazardCollection(activeOrSelectedRoute)
          : const {'type': 'FeatureCollection', 'features': []},
    );
    await _updateGeoJsonSource(
      _TrackingPageBodyState._hazardAreaSourceId,
      _showHazards
          ? _hazardAreaCollection(activeOrSelectedRoute)
          : const {'type': 'FeatureCollection', 'features': []},
    );

    await _updateGeoJsonSource(
      _TrackingPageBodyState._startSourceId,
      _pointCollection(state.selectedStart ?? state.activeRoute?.startPoint),
    );

    await _updateGeoJsonSource(
      _TrackingPageBodyState._endSourceId,
      _pointCollection(state.selectedEnd ?? state.activeRoute?.endPoint),
    );

    await _updateGeoJsonSource(
      _TrackingPageBodyState._liveSourceId,
      _liveLocationCollection(state),
    );

    await _fitToVisibleRoutesIfNeeded(state);
    await _focusLiveLocationIfNeeded(state);
    await _maybeAutoFollowLiveLocation(state);
  }

  void _scheduleSync(SafeRouteTrackingState state) {
    _pendingMapSyncState = state;
    if (_mapSyncScheduled) {
      return;
    }
    _mapSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _mapSyncScheduled = false;
      if (!mounted || _disposed) return;
      final nextState = _pendingMapSyncState;
      _pendingMapSyncState = null;
      if (nextState == null) return;
      await _syncMap(nextState);
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final quota = SubscriptionQuotaGate.resolve(error);
      if (quota?.feature == SubscriptionQuotaFeature.safeRoute) {
        await SubscriptionQuotaGate.showVipUpgradeDialog(
          context,
          quota: quota!,
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
      vm.clearError();
    });
  }

  void _maybeShowCompletedTripConfirmation(SafeRouteTrackingViewModel vm) {
    final confirmationId = vm.state.completedTripConfirmationTripId;
    if (confirmationId == null || confirmationId == _lastCompletedTripConfirmationId) {
      return;
    }
    _lastCompletedTripConfirmationId = confirmationId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _showArrivedSuccessDialog(vm);
    });
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
