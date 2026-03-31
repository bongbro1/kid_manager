import 'package:flutter/cupertino.dart';
import 'package:kid_manager/features/map_engine/child_blue_dot_renderer.dart';
import 'package:kid_manager/features/map_engine/controllers/camera_controller.dart';
import 'package:kid_manager/features/map_engine/controllers/interaction_controller.dart';
import 'package:kid_manager/features/map_engine/history_renderer.dart';
import 'package:kid_manager/features/map_engine/map_lifecycle_errors.dart';
import 'package:kid_manager/features/map_engine/network_gap_renderer.dart';
import 'package:kid_manager/features/map_engine/route_renderer.dart';
import 'package:kid_manager/features/map_engine/services/history_gap_detector.dart';
import 'package:kid_manager/features/map_engine/services/map_matching_service.dart';
import 'package:kid_manager/features/map_engine/services/segmented_map_matcher.dart';
import 'package:kid_manager/features/map_engine/start_end/start_end_marker_renderer.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapEngine {
  MapEngine(
    this.map, {
    this.enableChildDot = false,
    this.enableHistory = true,
    this.enableRoute = true,
    this.enableInteraction = true,
    this.enableCameraFollow = true,
    this.childAvatarUrl,
    this.onHistoryPointSelected,
  }) {
    route = RouteRenderer(map);
    history = HistoryRenderer(map);
    networkGaps = NetworkGapRenderer(map);
    camera = CameraController(map);
    startEndMarkers = StartEndMarkerRenderer(map);

    if (enableChildDot) {
      childDot = ChildBlueDotRenderer(map, avatarUrl: childAvatarUrl);
    }
  }

  final MapboxMap map;
  final bool enableChildDot;
  final bool enableHistory;
  final bool enableRoute;
  final bool enableInteraction;
  final bool enableCameraFollow;
  final String? childAvatarUrl;
  final void Function(LocationData point)? onHistoryPointSelected;

  bool showHistoryDots = false;

  late RouteRenderer route;
  late HistoryRenderer history;
  late NetworkGapRenderer networkGaps;
  late CameraController camera;
  late StartEndMarkerRenderer startEndMarkers;
  ChildBlueDotRenderer? childDot;
  InteractionController? interaction;

  List<List<double>> _matchedRoute = [];
  List<List<List<double>>> _straightSegs = [];
  List<double>? _anchor;
  List<LocationData> _gapMarkers = const [];

  bool followEnabled = true;
  bool _didInitialFit = false;
  int _lastMatchedTs = 0;
  int _lastFollowMs = 0;

  final _segMatcher = SegmentedMapMatcher(MapMatchingService());
  final _gapDetector = HistoryGapDetector();

  int _generation = 0;
  bool _disposed = false;

  bool get isDisposed => _disposed;

  bool _isActive(int generation) => !_disposed && generation == _generation;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    interaction = null;
    childDot?.dispose();
    history.dispose();
    route.dispose();
    startEndMarkers.dispose();
    _gapMarkers = const [];
  }

  Future<bool> _runStep({
    required int generation,
    required Future<void> Function() action,
  }) async {
    if (!_isActive(generation)) return false;
    try {
      await action();
      return _isActive(generation);
    } catch (error) {
      if (isMapLifecycleError(error) || !_isActive(generation)) {
        return false;
      }
      rethrow;
    }
  }

  void handleMapTap(MapContentGestureContext gestureContext) {
    if (_disposed) return;
    final currentInteraction = interaction;
    if (currentInteraction == null) return;

    final coord = gestureContext.point.coordinates;
    currentInteraction.handleTap(
      lat: coord.lat.toDouble(),
      lng: coord.lng.toDouble(),
      maxDistanceMeters: 35,
    );
  }

  Future<void> init() async {
    if (_disposed) return;
    final generation = _generation;

    if (enableRoute &&
        !await _runStep(generation: generation, action: () => route.init())) {
      return;
    }
    if (enableHistory &&
        !await _runStep(
          generation: generation,
          action: () => history.init(visible: showHistoryDots),
        )) {
      return;
    }
    if (!await _runStep(
      generation: generation,
      action: () => networkGaps.init(),
    )) {
      return;
    }
    if (!await _runStep(
      generation: generation,
      action: () => startEndMarkers.init(),
    )) {
      return;
    }

    if (enableChildDot) {
      await _runStep(generation: generation, action: () => childDot!.init());
    }
  }

  Future<void> setHistoryDotsVisible(bool visible) async {
    if (_disposed) return;
    showHistoryDots = visible;
    if (!enableHistory) return;
    final generation = _generation;
    await _runStep(
      generation: generation,
      action: () => history.setVisible(visible),
    );
  }

  Future<void> _renderNetworkGaps(List<LocationData> historyPoints) async {
    if (_disposed) return;
    final generation = _generation;
    final gaps = _gapDetector.detect(historyPoints);
    _gapMarkers = gaps.map((gap) => gap.marker).toList(growable: false);
    await _runStep(
      generation: generation,
      action: () => networkGaps.render(gaps),
    );
  }

  List<LocationData> _interactivePoints(List<LocationData> basePoints) {
    if (_gapMarkers.isEmpty) return basePoints;
    return [...basePoints, ..._gapMarkers];
  }

  List<LocationData> _bindRenderedPointsToHistory(
    List<LocationData> rawPoints, {
    List<LocationData>? renderedPoints,
  }) {
    final displayPoints = renderedPoints;
    if (displayPoints == null || displayPoints.isEmpty) {
      return _interactivePoints(rawPoints);
    }

    final count = rawPoints.length < displayPoints.length
        ? rawPoints.length
        : displayPoints.length;
    if (count <= 0) {
      return _interactivePoints(rawPoints);
    }

    final bound = <LocationData>[
      for (var index = 0; index < count; index++)
        rawPoints[index].copyWith(
          latitude: displayPoints[index].latitude,
          longitude: displayPoints[index].longitude,
        ),
    ];

    if (rawPoints.length > count) {
      bound.addAll(rawPoints.skip(count));
    }

    return _interactivePoints(bound);
  }

  void resetRouteCache() {
    _matchedRoute = [];
    _straightSegs = [];
    _anchor = null;
    _lastMatchedTs = 0;
  }

  void setFollowEnabled(bool value) => followEnabled = value;

  void resetInitialFit() => _didInitialFit = false;

  Future<void> updateChildDot(LocationData loc) async {
    if (_disposed || !enableChildDot) return;
    final generation = _generation;
    await _runStep(generation: generation, action: () => childDot!.update(loc));
  }

  bool _isSoftFail(
    List<LocationData> raw,
    List<LocationData> snapped, {
    double maxMeanErrM = 60,
  }) {
    final count = raw.length < snapped.length ? raw.length : snapped.length;
    if (count < 2) return true;
    double sum = 0;
    for (int index = 0; index < count; index++) {
      sum += raw[index].distanceTo(snapped[index]) * 1000.0;
    }
    final mean = sum / count;
    debugPrint('snap mean error = ${mean.toStringAsFixed(1)}m');
    return mean > maxMeanErrM;
  }

  Future<void> loadHistory(
    List<LocationData> data,
    BuildContext context,
  ) async {
    if (_disposed || (!enableHistory && !enableRoute)) return;
    final generation = _generation;

    if (data.isEmpty) {
      interaction = null;
      if (enableHistory &&
          !await _runStep(
            generation: generation,
            action: () => history.render(const []),
          )) {
        return;
      }
      if (enableRoute) {
        if (!await _runStep(
          generation: generation,
          action: () => route.renderRoad(const []),
        )) {
          return;
        }
        if (!await _runStep(
          generation: generation,
          action: () => route.renderStraightSegments(const []),
        )) {
          return;
        }
      }
      if (!await _runStep(
        generation: generation,
        action: () => networkGaps.clear(),
      )) {
        return;
      }
      await _runStep(
        generation: generation,
        action: () => startEndMarkers.clear(),
      );
      return;
    }

    final sorted = [...data]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _renderNetworkGaps(sorted);
    if (!_isActive(generation)) return;

    if (sorted.length < 2) {
      if (enableHistory) await history.render(sorted);
      await startEndMarkers.renderSinglePoint(sorted.last);
      if (!_didInitialFit) {
        _didInitialFit = true;
        await camera.focusOnPoint(sorted.last);
      }

      if (enableInteraction) {
        interaction = InteractionController(
          _bindRenderedPointsToHistory(sorted, renderedPoints: sorted),
          onPointSelected: onHistoryPointSelected,
        );
      }

      _lastMatchedTs = sorted.last.timestamp;
      _anchor = <double>[sorted.last.longitude, sorted.last.latitude];
      return;
    }

    final matched = await _segMatcher.matchByTransport(sorted);
    if (!_isActive(generation)) return;
    final pointsToShow = matched?.snappedPoints ?? sorted;
    final rawCoords = sorted
        .map((item) => <double>[item.longitude, item.latitude])
        .toList();

    if (enableRoute) {
      if (matched != null && matched.routeCoordinates.length >= 2) {
        _matchedRoute = matched.routeCoordinates;
        if (!await _runStep(
          generation: generation,
          action: () => route.renderRoad(_matchedRoute),
        )) {
          return;
        }

        _straightSegs = matched.straightSegments;
        if (!await _runStep(
          generation: generation,
          action: () => route.renderStraightSegments(_straightSegs),
        )) {
          return;
        }
        _anchor = _matchedRoute.last;
      } else {
        _matchedRoute = [];
        if (!await _runStep(
          generation: generation,
          action: () => route.renderRoad(const []),
        )) {
          return;
        }

        _straightSegs = rawCoords.length >= 2 ? [rawCoords] : [];
        if (!await _runStep(
          generation: generation,
          action: () => route.renderStraightSegments(_straightSegs),
        )) {
          return;
        }
        _anchor = rawCoords.isNotEmpty ? rawCoords.last : null;
      }
    }

    if (enableHistory &&
        !await _runStep(
          generation: generation,
          action: () => history.render(pointsToShow),
        )) {
      return;
    }

    if (!await _runStep(
      generation: generation,
      action: () => startEndMarkers.render(sorted),
    )) {
      return;
    }

    if (!_didInitialFit) {
      _didInitialFit = true;
      if (!await _runStep(
        generation: generation,
        action: () => camera.fitToRoute(pointsToShow),
      )) {
        return;
      }
    }

    if (enableInteraction) {
      interaction = InteractionController(
        _bindRenderedPointsToHistory(sorted, renderedPoints: pointsToShow),
        onPointSelected: onHistoryPointSelected,
      );
    }

    _lastMatchedTs = sorted.last.timestamp;
    if (_matchedRoute.isNotEmpty) {
      _anchor = _matchedRoute.last;
    } else if (_straightSegs.isNotEmpty && _straightSegs.last.isNotEmpty) {
      _anchor = _straightSegs.last.last;
    }
  }

  Future<void> updateEndMarkerRealtime(LocationData loc) async {
    if (_disposed) return;
    final generation = _generation;
    await _runStep(
      generation: generation,
      action: () => startEndMarkers.updateEndMarker(loc),
    );
  }

  Future<void> updateMatchedRouteIncremental(
    List<LocationData> data,
    BuildContext context, {
    int windowPoints = 25,
  }) async {
    if (_disposed || data.length < 2) return;
    final generation = _generation;

    final sorted = [...data]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _renderNetworkGaps(sorted);
    if (!_isActive(generation)) return;

    final latestTs = sorted.last.timestamp;
    if (latestTs <= _lastMatchedTs) {
      if (enableHistory &&
          !await _runStep(
            generation: generation,
            action: () => history.render(sorted),
          )) {
        return;
      }
      if (enableInteraction) {
        interaction = InteractionController(
          _bindRenderedPointsToHistory(sorted, renderedPoints: sorted),
          onPointSelected: onHistoryPointSelected,
        );
      }
      await _runStep(
        generation: generation,
        action: () => startEndMarkers.updateEndMarker(sorted.last),
      );
      return;
    }

    final hasWindow = sorted.length > windowPoints;
    final windowStartIndex = hasWindow ? (sorted.length - windowPoints) : 0;
    final window = sorted.sublist(windowStartIndex);

    List<List<double>>? rawGapSegment() {
      if (!hasWindow || windowStartIndex == 0) return null;
      final prev = sorted[windowStartIndex - 1];
      final first = sorted[windowStartIndex];
      return [
        <double>[prev.longitude, prev.latitude],
        <double>[first.longitude, first.latitude],
      ];
    }

    final matched = await _segMatcher.matchByTransport(window);
    if (!_isActive(generation)) return;
    final softFail =
        matched != null && _isSoftFail(window, matched.snappedPoints);

    debugPrint(
      'match window=${window.length} total=${sorted.length} '
      'matched=${matched != null} softFail=$softFail '
      'routeCoords=${matched?.routeCoordinates.length ?? 0} '
      'lastMatchedTs=$_lastMatchedTs latestTs=$latestTs',
    );

    if (matched == null || matched.routeCoordinates.length < 2 || softFail) {
      final newPts = window
          .where((point) => point.timestamp > _lastMatchedTs)
          .toList();
      final seg = <List<double>>[];

      final anchor =
          _anchor ??
          (_straightSegs.isNotEmpty && _straightSegs.last.isNotEmpty
              ? _straightSegs.last.last
              : null);
      if (anchor != null) seg.add(anchor);
      seg.addAll(
        newPts.map((point) => <double>[point.longitude, point.latitude]),
      );

      final gap = rawGapSegment();
      if (gap != null) {
        _straightSegs.add(gap);
      }

      final canAppend =
          seg.length >= 2 &&
          !(seg.first[0] == seg.last[0] && seg.first[1] == seg.last[1]);
      if (canAppend) {
        _straightSegs.add(seg);
        _anchor = seg.last;
      }

      _lastMatchedTs = latestTs;

      if (enableRoute) {
        if (!await _runStep(
          generation: generation,
          action: () => route.renderRoad(_matchedRoute),
        )) {
          return;
        }
        if (!await _runStep(
          generation: generation,
          action: () => route.renderStraightSegments(_straightSegs),
        )) {
          return;
        }
      }
      if (enableHistory &&
          !await _runStep(
            generation: generation,
            action: () => history.render(sorted),
          )) {
        return;
      }

      if (enableInteraction) {
        interaction = InteractionController(
          _bindRenderedPointsToHistory(sorted, renderedPoints: sorted),
          onPointSelected: onHistoryPointSelected,
        );
      }
      await _runStep(
        generation: generation,
        action: () => startEndMarkers.updateEndMarker(sorted.last),
      );
      return;
    }

    final newCoords = matched.routeCoordinates;
    if (newCoords.length < 2) {
      _lastMatchedTs = latestTs;
      if (enableHistory &&
          !await _runStep(
            generation: generation,
            action: () => history.render(sorted),
          )) {
        return;
      }
      await _runStep(
        generation: generation,
        action: () => startEndMarkers.updateEndMarker(sorted.last),
      );
      return;
    }

    if (_matchedRoute.isNotEmpty) {
      final lastRoad = _matchedRoute.last;
      final firstRoad = newCoords.first;
      final same = (lastRoad[0] == firstRoad[0] && lastRoad[1] == firstRoad[1]);
      if (!same) {
        final gap = rawGapSegment();
        if (gap != null) _straightSegs.add(gap);
      }
    }

    if (_matchedRoute.isEmpty) {
      _matchedRoute = [...newCoords];
    } else {
      final last = _matchedRoute.last;
      final first = newCoords.first;
      if (last[0] == first[0] && last[1] == first[1]) {
        _matchedRoute.addAll(newCoords.sublist(1));
      } else {
        _matchedRoute.addAll(newCoords);
      }
    }

    _anchor = _matchedRoute.isNotEmpty ? _matchedRoute.last : _anchor;
    _lastMatchedTs = latestTs;

    if (enableRoute) {
      if (!await _runStep(
        generation: generation,
        action: () => route.renderRoad(_matchedRoute),
      )) {
        return;
      }
      if (!await _runStep(
        generation: generation,
        action: () => route.renderStraightSegments(_straightSegs),
      )) {
        return;
      }
    }
    if (enableHistory &&
        !await _runStep(
          generation: generation,
          action: () => history.render(matched.snappedPoints),
        )) {
      return;
    }

    if (enableInteraction) {
      final renderedHistory = matched.snappedPoints;
      final rawForRendered = sorted.length >= renderedHistory.length
          ? sorted.sublist(sorted.length - renderedHistory.length)
          : sorted;
      interaction = InteractionController(
        _bindRenderedPointsToHistory(
          rawForRendered,
          renderedPoints: renderedHistory,
        ),
        onPointSelected: onHistoryPointSelected,
      );
    }
    await _runStep(
      generation: generation,
      action: () => startEndMarkers.updateEndMarker(sorted.last),
    );
  }

  Future<void> updateChildRealtime(LocationData loc) async {
    if (_disposed) return;
    final generation = _generation;
    await updateChildDot(loc);
    if (!_isActive(generation)) return;

    if (enableCameraFollow && followEnabled) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastFollowMs > 800) {
        _lastFollowMs = now;
        await _runStep(
          generation: generation,
          action: () => camera.follow(loc),
        );
      }
    }
  }

  Future<void> renderHistoryFast(
    List<LocationData> data,
    BuildContext context,
  ) async {
    if (_disposed || !enableHistory || data.isEmpty) return;
    final generation = _generation;

    await _renderNetworkGaps(data);
    if (!_isActive(generation)) return;

    if (!await _runStep(
      generation: generation,
      action: () => history.render(data),
    )) {
      return;
    }
    if (!await _runStep(
      generation: generation,
      action: () => startEndMarkers.updateEndMarker(data.last),
    )) {
      return;
    }

    if (enableInteraction) {
      interaction = InteractionController(
        _bindRenderedPointsToHistory(data, renderedPoints: data),
        onPointSelected: onHistoryPointSelected,
      );
    }
  }

  Future<void> resetForNewHistory() async {
    if (_disposed) return;
    final generation = _generation;
    _matchedRoute = [];
    _straightSegs = [];
    _anchor = null;
    _lastMatchedTs = 0;
    _didInitialFit = false;
    interaction = null;
    _gapMarkers = const [];

    if (!await _runStep(
      generation: generation,
      action: () => networkGaps.clear(),
    )) {
      return;
    }
    await _runStep(
      generation: generation,
      action: () => startEndMarkers.clear(),
    );
  }
}
