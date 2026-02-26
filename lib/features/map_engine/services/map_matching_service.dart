import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:kid_manager/features/map_engine/services/segmented_map_matcher.dart';
import 'package:kid_manager/features/map_engine/trace_preprocessor.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapMatchedResult {
  final List<LocationData> snappedPoints;        // cùng số lượng input
  final List<List<double>> routeCoordinates;     // LineString coords: [lon, lat]
  final int nullTracepoints;
  const MapMatchedResult({
    required this.snappedPoints,
    required this.routeCoordinates,
    required this.nullTracepoints,
  });
}

class MapMatchingService {
  late SegmentedMapMatcher _segmentedMapMatcher;
  /// profile: 'mapbox/driving' | 'mapbox/walking' | 'mapbox/cycling' | 'mapbox/driving-traffic'
    Future<MapMatchedResult?> matchTrace(
        List<LocationData> rawHistory, {
          String profile = 'mapbox/driving',
          bool tidy = true,
        }) async {

      if (rawHistory.length < 2) return null;
      int totalNull = 0;

      // 1) Downsample thông minh (giảm điểm, giảm request, giảm sai)
      final thinned = TracePreprocessor.thin(
        rawHistory,
        intervalMs: 2000,   // 2s (hoặc 3000)
        minDistanceM: 5,    // giữ dày hơn
        minTurnDeg: 10,     // nhạy cua hơn
        maxAccuracyM: 40,
      );
      // 2) đảm bảo đúng thứ tự thời gian
      final history = [...thinned]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
     print('raw=${rawHistory.length} -> thin=${thinned.length}');
      // API limit: tối đa 100 điểm / request => split nếu dài
      final segments = _splitBy100(history);

      final allRoute = <List<double>>[];
      final allSnapped = <LocationData>[];

      for (var si = 0; si < segments.length; si++) {
        final seg = segments[si];
        print("PROFILE CHILDREN : ${profile}");
        final segResult = await _matchSegment(seg, profile: profile, tidy: tidy);
        if (segResult == null || segResult.routeCoordinates.length < 2) {
          debugPrint(" matchTrace: segment failed, stop (no fallback straight)");
          return null;
        }
        totalNull += segResult.nullTracepoints;
        final routeCoords = segResult.routeCoordinates;
        final snappedPts = segResult.snappedPoints;
        // nối route, tránh trùng điểm nối
        if (allRoute.isEmpty) {
          allRoute.addAll(routeCoords);
        } else {
          if (routeCoords.isNotEmpty &&
              allRoute.last[0] == routeCoords.first[0] &&
              allRoute.last[1] == routeCoords.first[1]) {
            allRoute.addAll(routeCoords.sublist(1));
          } else {
            allRoute.addAll(routeCoords);
          }
        }

        // nối snapped points, tránh trùng do overlap 1 điểm giữa segments
        if (allSnapped.isEmpty) {
          allSnapped.addAll(snappedPts);
        } else {
          allSnapped.addAll(snappedPts.sublist(1));
        }
      }

      return MapMatchedResult(
        snappedPoints: allSnapped,
        routeCoordinates: allRoute,
        nullTracepoints: totalNull,
      );
    }



  List<int> _strictlyIncreasingSeconds(List<LocationData> history) {
    final out = <int>[];
    var prev = -1;
    for (final p in history) {
      var s = p.timestamp ~/ 1000;
      if (s <= prev) s = prev + 1;
      out.add(s);
      prev = s;
    }
    return out;
  }

  Future<MapMatchedResult?> _matchSegment(
      List<LocationData> history, {
        required String profile,
        required bool tidy,
      }) async {
    if (history.length < 2) return null;

    final coords = history.map((e) => '${e.longitude},${e.latitude}').join(';');

    // radiuses: 0..50m, default 5. Bạn đang accuracy=5 => ok
    final radiuses = history
        .map((e) => (e.accuracy.isFinite ? e.accuracy : 20.0)
        .clamp(5.0, 20.0)
        .toStringAsFixed(1))
        .join(';');

    // timestamps: seconds
    final timestamps = _strictlyIncreasingSeconds(history).join(';');
    final token = await MapboxOptions.getAccessToken(); // có sẵn trong SDK :contentReference[oaicite:9]{index=9}

    final uri = Uri.https(
      'api.mapbox.com',
      '/matching/v5/$profile/$coords.json',
      {
        'access_token': token,
        'geometries': 'geojson',
        'overview': 'full',
        'steps': 'false',
        'tidy': tidy ? 'true' : 'false',
        'radiuses': radiuses,
        'timestamps': timestamps,
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      debugPrint(" Matching HTTP ${res.statusCode}: ${res.body}");
      return null;
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    if (json['code']?.toString() != 'Ok') {
      debugPrint(" Matching code=${json['code']} msg=${json['message'] ?? ''} body=${res.body}");
      return null;
    }

    final matchings = (json['matchings'] as List?) ?? const [];
    final tracepoints = (json['tracepoints'] as List?) ?? const [];
    debugPrint("walking ok, matchings=${matchings.length}, tracepoints=${tracepoints.length}");
    if (matchings.isEmpty) return null;

    // route geometry: có thể nhiều sub-matches, mình nối lại cho bạn
    final routeCoords = <List<double>>[];
    for (final m in matchings) {
      final mm = m as Map<String, dynamic>;
      final geom = mm['geometry'] as Map<String, dynamic>;
      final coordsList = (geom['coordinates'] as List)
          .map((c) => (c as List).cast<num>())
          .map((c) => <double>[c[0].toDouble(), c[1].toDouble()])
          .toList();

      if (coordsList.isEmpty) continue;

      if (routeCoords.isNotEmpty &&
          routeCoords.last[0] == coordsList.first[0] &&
          routeCoords.last[1] == coordsList.first[1]) {
        routeCoords.addAll(coordsList.sublist(1));
      } else {
        routeCoords.addAll(coordsList);
      }
    }

    // snapped points: tracepoints[i].location = [lon,lat], có thể null nếu outlier :contentReference[oaicite:10]{index=10}
    final snapped = <LocationData>[];
    int nullTp = 0;

    for (var i = 0; i < history.length; i++) {
      final tp = (i < tracepoints.length) ? tracepoints[i] : null;
      debugPrint(" match ok: points=${history.length}, nullTracepoints=$nullTp");
      if (tp == null) {
        nullTp++;
        snapped.add(history[i]);
        continue;
      }

      final tpMap = tp as Map<String, dynamic>?;
      final locArr = tpMap?['location'] as List?;
      if (locArr == null || locArr.length < 2) {
        nullTp++;
        snapped.add(history[i]);
        continue;
      }

      snapped.add(
        history[i].copyWith(
          longitude: (locArr[0] as num).toDouble(),
          latitude: (locArr[1] as num).toDouble(),
        ),
      );
    }
    debugPrint("DONE profile=$profile pts=${history.length} null=$nullTp routeCoords=${routeCoords.length}");

    return MapMatchedResult(
      snappedPoints: snapped,
      routeCoordinates: routeCoords,
      nullTracepoints: nullTp
    );
  }

  /// split max 100 coords/request và overlap 1 điểm để nối mượt
  List<List<LocationData>> _splitBy100(List<LocationData> history) {
    const maxPts = 100;
    if (history.length <= maxPts) return [history];

    final out = <List<LocationData>>[];
    var i = 0;
    while (i < history.length) {
      final end = min(i + maxPts, history.length);
      out.add(history.sublist(i, end));
      if (end == history.length) break;
      i = end - 1; // overlap 1 điểm
    }
    return out;
  }
}