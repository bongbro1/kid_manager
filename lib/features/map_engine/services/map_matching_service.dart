import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:kid_manager/features/map_engine/trace_preprocessor.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/services/location/mapbox_gateway_service.dart';

class MapMatchedResult {
  const MapMatchedResult({
    required this.snappedPoints,
    required this.routeCoordinates,
    required this.nullTracepoints,
  });

  final List<LocationData> snappedPoints;
  final List<List<double>> routeCoordinates;
  final int nullTracepoints;
}

class MapMatchingService {
  MapMatchingService({MapboxGatewayService? gateway})
    : _gateway = gateway ?? MapboxGatewayService();

  final MapboxGatewayService _gateway;

  Future<MapMatchedResult?> matchTrace(
    List<LocationData> rawHistory, {
    String profile = 'mapbox/driving',
    bool tidy = true,
  }) async {
    if (rawHistory.length < 2) return null;
    var totalNull = 0;

    final thinned = TracePreprocessor.thin(
      rawHistory,
      intervalMs: 2000,
      minDistanceM: 5,
      minTurnDeg: 10,
      maxAccuracyM: 40,
    );
    final history = [...thinned]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    debugPrint('raw=${rawHistory.length} -> thin=${thinned.length}');

    final segments = _splitBy100(history);
    final allRoute = <List<double>>[];
    final allSnapped = <LocationData>[];

    for (final segment in segments) {
      final segmentResult = await _matchSegment(
        segment,
        profile: profile,
        tidy: tidy,
      );
      if (segmentResult == null || segmentResult.routeCoordinates.length < 2) {
        debugPrint('matchTrace: segment failed, stop');
        return null;
      }

      totalNull += segmentResult.nullTracepoints;

      if (allRoute.isEmpty) {
        allRoute.addAll(segmentResult.routeCoordinates);
      } else if (segmentResult.routeCoordinates.isNotEmpty &&
          allRoute.last[0] == segmentResult.routeCoordinates.first[0] &&
          allRoute.last[1] == segmentResult.routeCoordinates.first[1]) {
        allRoute.addAll(segmentResult.routeCoordinates.sublist(1));
      } else {
        allRoute.addAll(segmentResult.routeCoordinates);
      }

      if (allSnapped.isEmpty) {
        allSnapped.addAll(segmentResult.snappedPoints);
      } else {
        allSnapped.addAll(segmentResult.snappedPoints.sublist(1));
      }
    }

    return MapMatchedResult(
      snappedPoints: allSnapped,
      routeCoordinates: allRoute,
      nullTracepoints: totalNull,
    );
  }

  Future<MapMatchedResult?> _matchSegment(
    List<LocationData> history, {
    required String profile,
    required bool tidy,
  }) async {
    if (history.length < 2) return null;

    final result = await _gateway.matchTrace(
      points: history
          .map(
            (point) => MapboxTracePointInput(
              latitude: point.latitude,
              longitude: point.longitude,
              accuracy: point.accuracy,
              timestamp: point.timestamp,
            ),
          )
          .toList(growable: false),
      profile: profile,
      tidy: tidy,
    );

    if (result == null || result.routeCoordinates.length < 2) {
      return null;
    }

    final snapped = <LocationData>[];
    for (var index = 0; index < history.length; index++) {
      final backendPoint = index < result.snappedPoints.length
          ? result.snappedPoints[index]
          : null;
      if (backendPoint == null) {
        snapped.add(history[index]);
        continue;
      }

      snapped.add(
        history[index].copyWith(
          latitude: backendPoint.latitude,
          longitude: backendPoint.longitude,
        ),
      );
    }

    return MapMatchedResult(
      snappedPoints: snapped,
      routeCoordinates: result.routeCoordinates,
      nullTracepoints: result.nullTracepoints,
    );
  }

  List<List<LocationData>> _splitBy100(List<LocationData> history) {
    const maxPoints = 100;
    if (history.length <= maxPoints) return [history];

    final chunks = <List<LocationData>>[];
    var index = 0;
    while (index < history.length) {
      final end = min(index + maxPoints, history.length);
      chunks.add(history.sublist(index, end));
      if (end == history.length) break;
      index = end - 1;
    }
    return chunks;
  }
}
