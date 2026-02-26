import 'package:flutter/foundation.dart';
import 'package:kid_manager/features/map_engine/services/history_segmenter.dart';
import 'package:kid_manager/features/map_engine/services/map_matching_service.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class SegmentedMatchResult {
  final List<LocationData> snappedPoints;
  final List<List<double>> routeCoordinates;
  final List<HistorySegment> segments;

  SegmentedMatchResult({
    required this.snappedPoints,
    required this.routeCoordinates,
    required this.segments,
  });
}

class SegmentedMapMatcher {
  final MapMatchingService _matcher;
  SegmentedMapMatcher(this._matcher);

  /// Tiêu chí "match tốt"
  bool _isGood(MapMatchedResult? r, int n) {
    if (r == null) return false;
    if (r.routeCoordinates.length < 2) return false;
    if (n <= 0) return false;
    final ratio = r.nullTracepoints / n;
    return ratio <= 0.25; // chỉnh 0.2~0.3 tuỳ data
  }

  /// Thứ tự fallback profile theo mode (mode lấy từ DB con gửi lên)
  List<String> _fallbackOrder(TransportMode mode) {
    switch (mode) {
      case TransportMode.walking:
      case TransportMode.still:
        return const ['mapbox/walking', 'mapbox/cycling', 'mapbox/driving'];
      case TransportMode.bicycle:
        return const ['mapbox/cycling', 'mapbox/driving', 'mapbox/walking'];
      case TransportMode.vehicle:
      case TransportMode.unknown:
        return const ['mapbox/driving', 'mapbox/cycling', 'mapbox/walking'];
    }
  }

  /// Try theo thứ tự profiles; nếu không cái nào đạt chuẩn thì trả "best effort"
  /// (ít nullTracepoints nhất và có routeCoordinates)
  Future<MapMatchedResult?> _matchWithFallback(
      List<LocationData> pts,
      List<String> profiles,
      ) async {
    MapMatchedResult? best;
    double bestRatio = double.infinity;

    for (final p in profiles) {
      final r = await _matcher.matchTrace(pts, profile: p, tidy: false);

      if (r == null) {
        debugPrint(" profile=$p -> null");
        continue;
      }

      final ratio = r.nullTracepoints / pts.length;
      debugPrint(
        "profile=$p -> null=${r.nullTracepoints}/${pts.length} "
            "ratio=${ratio.toStringAsFixed(2)} route=${r.routeCoordinates.length}",
      );

      // lưu best effort
      if (r.routeCoordinates.length >= 2 && ratio < bestRatio) {
        best = r;
        bestRatio = ratio;
      }

      // đạt chuẩn -> return luôn
      if (_isGood(r, pts.length)) return r;
    }

    return best;
  }

  Future<SegmentedMatchResult?> matchByTransport(
      List<LocationData> history, {
        int gapMs = 2 * 60 * 1000,
        int minSegmentPointsToMatch = 6, // segment quá ngắn thì khỏi gọi API
      }) async {
    if (history.length < 2) return null;

    final segments = HistorySegmenter.splitByTransport(history, gapMs: gapMs);
    if (segments.isEmpty) return null;

    final mergedRoute = <List<double>>[];
    final mergedSnapped = <LocationData>[];

    for (final seg in segments) {
      if (seg.points.length < 2) continue;

      // segment quá ngắn -> skip match, vẫn giữ points để hiển thị
      if (seg.points.length < minSegmentPointsToMatch) {
        final segPtsWithMode =
        seg.points.map((p) => p.copyWith(transport: seg.mode)).toList();

        if (mergedSnapped.isEmpty) {
          mergedSnapped.addAll(segPtsWithMode);
        } else if (segPtsWithMode.isNotEmpty) {
          final last = mergedSnapped.last;
          final first = segPtsWithMode.first;
          final same = last.timestamp == first.timestamp;
          mergedSnapped.addAll(same ? segPtsWithMode.sublist(1) : segPtsWithMode);
        }
        continue;
      }

      debugPrint("MODE POINT: ${seg.mode} points=${seg.points.length}");

      final profiles = _fallbackOrder(seg.mode);
      final res = await _matchWithFallback(seg.points, profiles);

      if (res == null || res.routeCoordinates.length < 2) {
        debugPrint("❌ segment match failed (mode=${seg.mode}) -> stop");
        return null;
      }

      final segRoute = res.routeCoordinates;
      final segSnappedWithMode =
      res.snappedPoints.map((p) => p.copyWith(transport: seg.mode)).toList();

      // nối route (tránh trùng điểm)
      if (mergedRoute.isEmpty) {
        mergedRoute.addAll(segRoute);
      } else if (segRoute.isNotEmpty) {
        final last = mergedRoute.last;
        final first = segRoute.first;
        if (last[0] == first[0] && last[1] == first[1]) {
          mergedRoute.addAll(segRoute.sublist(1));
        } else {
          mergedRoute.addAll(segRoute);
        }
      }

      // nối snapped points (tránh trùng điểm đầu segment)
      if (mergedSnapped.isEmpty) {
        mergedSnapped.addAll(segSnappedWithMode);
      } else if (segSnappedWithMode.isNotEmpty) {
        final last = mergedSnapped.last;
        final first = segSnappedWithMode.first;
        final same = last.timestamp == first.timestamp;
        mergedSnapped.addAll(same ? segSnappedWithMode.sublist(1) : segSnappedWithMode);
      }
    }

    return SegmentedMatchResult(
      snappedPoints: mergedSnapped,
      routeCoordinates: mergedRoute,
      segments: segments,
    );
  }
}