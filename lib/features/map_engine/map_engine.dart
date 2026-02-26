import 'package:flutter/cupertino.dart';
import 'package:kid_manager/features/map_engine/child_blue_dot_renderer.dart';
import 'package:kid_manager/features/map_engine/controllers/camera_controller.dart';
import 'package:kid_manager/features/map_engine/controllers/interaction_controller.dart';
import 'package:kid_manager/features/map_engine/history_renderer.dart';
import 'package:kid_manager/features/map_engine/route_renderer.dart';
import 'package:kid_manager/features/map_engine/services/map_matching_service.dart';
import 'package:kid_manager/features/map_engine/services/segmented_map_matcher.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapEngine {
  final MapboxMap map;

  final bool enableChildDot;
  final bool enableHistory;
  final bool enableRoute;
  final bool enableInteraction;
  final bool enableCameraFollow;

  late RouteRenderer route;
  late HistoryRenderer history;
  late CameraController camera;


  List<List<double>> _matchedRoute = [];
  int _lastMatchedTs = 0;
  // chỉ tạo khi enableChildDot = true
  ChildBlueDotRenderer? childDot;

  final _segMatcher = SegmentedMapMatcher(MapMatchingService());
  InteractionController? interaction;

  MapEngine(
      this.map, {
        this.enableChildDot = false,
        this.enableHistory = true,
        this.enableRoute = true,
        this.enableInteraction = true,
        this.enableCameraFollow = true,
      }) {
    route = RouteRenderer(map);
    history = HistoryRenderer(map);
    camera = CameraController(map);

    if (enableChildDot) {
      childDot = ChildBlueDotRenderer(map);
    }
  }

  Future<void> init() async {
    if (enableRoute) await route.init();
    if (enableHistory) await history.init();
    if (enableChildDot) await childDot!.init();
  }
  void resetRouteCache() {
    _matchedRoute = [];
    _lastMatchedTs = 0;
  }
  Future<void> loadHistory(List<LocationData> data, BuildContext context) async {
    if (!enableHistory && !enableRoute) return;

    final matched = await _segMatcher.matchByTransport(data);
    final pointsToShow = matched?.snappedPoints ?? data;

    if (enableRoute && matched != null && matched.routeCoordinates.length >= 2) {
      await route.renderGeometry(matched.routeCoordinates);
    } else if (enableRoute) {
      // nếu match fail thì đừng vẽ route nối thẳng
      debugPrint("❌ No routeCoordinates -> not drawing route");
      await route.renderGeometry([]); // hoặc giữ route cũ tuỳ bạn
    }

    if (enableHistory) {
      await history.render(pointsToShow);
    }

    await camera.fitToRoute(pointsToShow);

    if (enableInteraction) {
      interaction = InteractionController(map, pointsToShow, context);
      await interaction!.attach();
    }
  }

  Future<void> updateMatchedRouteIncremental(
      List<LocationData> data,
      BuildContext context, {
        int windowPoints = 25, // match 25 điểm cuối
      }) async {
    if (data.length < 2) return;

    final sorted = [...data]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // chỉ match khi có điểm mới hơn lần trước
    final latestTs = sorted.last.timestamp;
    if (latestTs <= _lastMatchedTs) {
      // vẫn update points để user thấy realtime
      await history.render(sorted);
      return;
    }

    final window = sorted.length > windowPoints
        ? sorted.sublist(sorted.length - windowPoints)
        : sorted;

    final matched = await _segMatcher.matchByTransport(window);

    if (matched == null || matched.routeCoordinates.length < 2) {
      debugPrint("❌ incremental match failed -> keep old route, update points only");
      await history.render(sorted);
      return; // ❌ KHÔNG nối thẳng
    }

    _lastMatchedTs = latestTs;

    // nếu chưa có route -> set luôn
    if (_matchedRoute.isEmpty) {
      _matchedRoute = matched.routeCoordinates;
    } else {
      // nối route mới vào route cũ
      final newCoords = matched.routeCoordinates;
      if (newCoords.isNotEmpty) {
        final last = _matchedRoute.last;
        final first = newCoords.first;
        if (last[0] == first[0] && last[1] == first[1]) {
          _matchedRoute.addAll(newCoords.sublist(1));
        } else {
          _matchedRoute.addAll(newCoords);
        }
      }
    }

    await route.renderGeometry(_matchedRoute);
    await history.render(matched.snappedPoints);

    interaction ??= InteractionController(map, matched.snappedPoints, context);
    await interaction!.attach();
  }

  Future<void> renderHistoryFast(List<LocationData> data, BuildContext context) async {
    if (data.isEmpty) return;

    //  chỉ vẽ points thôi (không vẽ route raw)
    await history.render(data);

    interaction ??= InteractionController(map, data, context);
    await interaction!.attach();
  }
  Future<void> updateChildRealtime(LocationData loc) async {
    debugPrint("VAO DEN DAY ${enableChildDot}");
    if (enableChildDot) {
      await childDot!.update(loc);
    }
    if (enableCameraFollow) {
      await camera.follow(loc);
    }
  }
}