import 'package:flutter/cupertino.dart';
import 'package:kid_manager/features/map_engine/child_blue_dot_renderer.dart';
import 'package:kid_manager/features/map_engine/controllers/camera_controller.dart';
import 'package:kid_manager/features/map_engine/controllers/interaction_controller.dart';
import 'package:kid_manager/features/map_engine/history_renderer.dart';
import 'package:kid_manager/features/map_engine/network_gap_renderer.dart';
import 'package:kid_manager/features/map_engine/route_renderer.dart';
import 'package:kid_manager/features/map_engine/services/history_gap_detector.dart';
import 'package:kid_manager/features/map_engine/services/map_matching_service.dart';
import 'package:kid_manager/features/map_engine/services/segmented_map_matcher.dart';
import 'package:kid_manager/features/map_engine/start_end/start_end_marker_renderer.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapEngine {
  final MapboxMap map;

  final bool enableChildDot;
  final bool enableHistory;
  final bool enableRoute;
  final bool enableInteraction;
  final bool enableCameraFollow;
  bool showHistoryDots = false;

  late RouteRenderer route;
  late HistoryRenderer history;
  late NetworkGapRenderer networkGaps;
  late CameraController camera;

  List<List<double>> _matchedRoute = [];
  List<List<List<double>>> _straightSegs = [];

  bool followEnabled = true;
  bool _didInitialFit = false;

  int _lastMatchedTs = 0; // ✅ rất quan trọng
  int _lastFollowMs = 0;

  List<double>? _anchor; // [lng,lat] điểm neo cuối cùng (road hoặc straight)
  final void Function(LocationData point)? onHistoryPointSelected;
  ChildBlueDotRenderer? childDot;
  late StartEndMarkerRenderer startEndMarkers;
  final _segMatcher = SegmentedMapMatcher(MapMatchingService());
  final _gapDetector = HistoryGapDetector();
  InteractionController? interaction;
  List<LocationData> _gapMarkers = const [];

  MapEngine(
      this.map, {
        this.enableChildDot = false,
        this.enableHistory = true,
        this.enableRoute = true,
        this.enableInteraction = true,
        this.enableCameraFollow = true,
        this.onHistoryPointSelected
      }) {
    route = RouteRenderer(map);
    history = HistoryRenderer(map);
    networkGaps = NetworkGapRenderer(map);
    camera = CameraController(map);
    startEndMarkers = StartEndMarkerRenderer(map);

    if (enableChildDot) {
      childDot = ChildBlueDotRenderer(map);
    }
  }

  Future<void> init() async {
    if (enableRoute) await route.init();
    if (enableHistory) await history.init(visible: showHistoryDots); // ✅
    await networkGaps.init();
    await startEndMarkers.init();

    if (enableChildDot) await childDot!.init();
  }

  void handleMapTap(MapContentGestureContext gestureContext) {
    final currentInteraction = interaction;
    if (currentInteraction == null) return;

    final coord = gestureContext.point.coordinates;
    final lat = coord.lat.toDouble();
    final lng = coord.lng.toDouble();

    currentInteraction.handleTap(
      lat: lat,
      lng: lng,
      maxDistanceMeters: 35,
    );
  }

  Future<void> setHistoryDotsVisible(bool v) async {
    showHistoryDots = v;
    if (enableHistory) {
      await history.setVisible(v);
    }
  }

  Future<void> _renderNetworkGaps(List<LocationData> historyPoints) async {
    final gaps = _gapDetector.detect(historyPoints);
    _gapMarkers = gaps.map((gap) => gap.marker).toList(growable: false);
    await networkGaps.render(gaps);
  }

  List<LocationData> _interactivePoints(List<LocationData> basePoints) {
    if (_gapMarkers.isEmpty) return basePoints;
    return [...basePoints, ..._gapMarkers];
  }

  void resetRouteCache() {
    _matchedRoute = [];
    _straightSegs = [];
    _anchor = null;
    _lastMatchedTs = 0;
  }

  void setFollowEnabled(bool v) => followEnabled = v;
  void resetInitialFit() => _didInitialFit = false;

  Future<void> updateChildDot(LocationData loc) async {
    if (enableChildDot) {
      await childDot!.update(loc);
    }
  }

  bool _isSoftFail(
      List<LocationData> raw,
      List<LocationData> snapped, {
        double maxMeanErrM = 60,
      }) {
    final n = raw.length < snapped.length ? raw.length : snapped.length;
    if (n < 2) return true;
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += raw[i].distanceTo(snapped[i]) * 1000.0;
    }
    final mean = sum / n;
    debugPrint("🧭 snap mean error = ${mean.toStringAsFixed(1)}m");
    return mean > maxMeanErrM;
  }

  Future<void> loadHistory(List<LocationData> data, BuildContext context) async {
    if (!enableHistory && !enableRoute) return;

    if (data.isEmpty) {
      interaction = null;
      if (enableHistory) await history.render(const []);
      if (enableRoute) {
        await route.renderRoad([]);
        await route.renderStraightSegments([]);
      }
      await networkGaps.clear();
      await startEndMarkers.clear();
      return;
    }

    final sorted = [...data]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _renderNetworkGaps(sorted);

    if (sorted.length < 2) {
      if (enableHistory) await history.render(sorted);
      await startEndMarkers.renderSinglePoint(sorted.last);

      if (enableInteraction) {
        interaction = InteractionController(
          _interactivePoints(sorted),
          onPointSelected: onHistoryPointSelected,
        );
      }

      _lastMatchedTs = sorted.last.timestamp;
      _anchor = <double>[sorted.last.longitude, sorted.last.latitude];
      return;
    }

    final matched = await _segMatcher.matchByTransport(sorted);
    final pointsToShow = matched?.snappedPoints ?? sorted;

    final rawCoords = sorted.map((e) => <double>[e.longitude, e.latitude]).toList();

    if (enableRoute) {
      if (matched != null && matched.routeCoordinates.length >= 2) {
        _matchedRoute = matched.routeCoordinates;
        await route.renderRoad(_matchedRoute);

        _straightSegs = matched.straightSegments;
        await route.renderStraightSegments(_straightSegs);

        _anchor = _matchedRoute.last;
      } else {
        _matchedRoute = [];
        await route.renderRoad([]);

        _straightSegs = rawCoords.length >= 2 ? [rawCoords] : [];
        await route.renderStraightSegments(_straightSegs);

        _anchor = rawCoords.isNotEmpty ? rawCoords.last : null;
      }
    }

    if (enableHistory) {
      await history.render(pointsToShow);
    }

    await startEndMarkers.render(sorted);

    if (!_didInitialFit) {
      _didInitialFit = true;
      await camera.fitToRoute(pointsToShow);
    }

    if (enableInteraction) {
      interaction = InteractionController(
        _interactivePoints(sorted),
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
    await startEndMarkers.updateEndMarker(loc);
  }

  Future<void> updateMatchedRouteIncremental(
      List<LocationData> data,
      BuildContext context, {
        int windowPoints = 25,
      }) async {
    if (data.length < 2) return;

    final sorted = [...data]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    await _renderNetworkGaps(sorted);

    final latestTs = sorted.last.timestamp;
    if (latestTs <= _lastMatchedTs) {
      // vẫn update points để user thấy realtime
      if (enableHistory) await history.render(sorted);
      if (enableInteraction) {
        interaction = InteractionController(
          _interactivePoints(sorted),
          onPointSelected: onHistoryPointSelected,
        );
      }
      await startEndMarkers.updateEndMarker(sorted.last);

      return;
    }

    final bool hasWindow = sorted.length > windowPoints;
    final int windowStartIndex = hasWindow ? (sorted.length - windowPoints) : 0;
    final window = sorted.sublist(windowStartIndex);

    // helper gap segment (raw) giữa trước window và đầu window
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
    final bool softFail = matched != null && _isSoftFail(window, matched.snappedPoints);

    debugPrint(
      "🧭 match window=${window.length} total=${sorted.length} "
          "matched=${matched != null} softFail=$softFail routeCoords=${matched?.routeCoordinates.length ?? 0} "
          "lastMatchedTs=$_lastMatchedTs latestTs=$latestTs",
    );

    // =========================
    // FAIL (hard/soft)
    // =========================
    if (matched == null || matched.routeCoordinates.length < 2 || softFail) {
      debugPrint("❌ match fail -> draw straight ONLY new points");

      // ✅ lấy phần mới trong window (không lấy toàn sorted)
      final newPts = window.where((p) => p.timestamp > _lastMatchedTs).toList();

      // build seg bắt đầu từ anchor để nối tiếp
      final seg = <List<double>>[];

      final anchor = _anchor ??
          (_straightSegs.isNotEmpty && _straightSegs.last.isNotEmpty ? _straightSegs.last.last : null);

      if (anchor != null) seg.add(anchor);

      seg.addAll(newPts.map((p) => <double>[p.longitude, p.latitude]));

      // nếu có gap giữa window trước và window hiện tại (khi hasWindow)
      final gap = rawGapSegment();
      if (gap != null) {
        // gap thường ngắn; add trước để nối liền
        _straightSegs.add(gap);
      }

      final ok = seg.length >= 2 && !(seg.first[0] == seg.last[0] && seg.first[1] == seg.last[1]);
      if (ok) {
        _straightSegs.add(seg);
        _anchor = seg.last;
        debugPrint("🧩 add straight seg len=${seg.length} totalSegs=${_straightSegs.length}");
      } else {
        debugPrint("🧩 skip straight seg len=${seg.length}");
      }

      _lastMatchedTs = latestTs;

      if (enableRoute) {
        await route.renderRoad(_matchedRoute); // giữ road cũ
        await route.renderStraightSegments(_straightSegs);
      }
      if (enableHistory) await history.render(sorted);

      if (enableInteraction) {
        interaction = InteractionController(
          _interactivePoints(sorted),
          onPointSelected: onHistoryPointSelected,
        );
      }
      await startEndMarkers.updateEndMarker(sorted.last);
      return;
    }

    // =========================
    // SUCCESS
    // =========================
    final newCoords = matched.routeCoordinates;
    if (newCoords.length < 2) {
      _lastMatchedTs = latestTs;
      if (enableHistory) await history.render(sorted);
      await startEndMarkers.updateEndMarker(sorted.last);

      return;
    }

    // nếu road mới không nối với road cũ -> chỉ nối gap raw (ngắn)
    if (_matchedRoute.isNotEmpty) {
      final lastRoad = _matchedRoute.last;
      final firstRoad = newCoords.first;
      final same = (lastRoad[0] == firstRoad[0] && lastRoad[1] == firstRoad[1]);

      if (!same) {
        final gap = rawGapSegment();
        if (gap != null) _straightSegs.add(gap);
      }
    }

    // append road
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
      await route.renderRoad(_matchedRoute);
      await route.renderStraightSegments(_straightSegs);
    }
    if (enableHistory) await history.render(matched.snappedPoints);

    if (enableInteraction) {
      interaction = InteractionController(
        _interactivePoints(sorted),
        onPointSelected: onHistoryPointSelected,
      );
    }
    await startEndMarkers.updateEndMarker(sorted.last);
  }

  Future<void> updateChildRealtime(LocationData loc) async {
    // chỉ update dot (marker)
    await updateChildDot(loc);

    // follow nếu user bật
    if (enableCameraFollow && followEnabled) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastFollowMs > 800) {
        _lastFollowMs = now;
        await camera.follow(loc);
      }
    }
  }

  Future<void> renderHistoryFast(List<LocationData> data, BuildContext context) async {
    if (!enableHistory) return;
    if (data.isEmpty) return;

    await _renderNetworkGaps(data);
    await history.render(data);
    await startEndMarkers.updateEndMarker(data.last);

    if (enableInteraction) {
      interaction = InteractionController(
        _interactivePoints(data),
        onPointSelected: onHistoryPointSelected,
      );
    }
  }

  Future<void> resetForNewHistory() async {
    _matchedRoute = [];
    _straightSegs = [];
    _anchor = null;
    _lastMatchedTs = 0;
    _didInitialFit = false;
    interaction =null;
    interaction = null;
    _gapMarkers = const [];
    await networkGaps.clear();
    await startEndMarkers.clear();
  }
}
