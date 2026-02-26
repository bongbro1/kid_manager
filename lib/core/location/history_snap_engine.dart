import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/location/history_snap_model.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/services/location/mapbox_route_service.dart';

class HistorySnapEngine {
  static const int _chunkSize = 50;
  static const double _minDistanceMeters = 5;

  final _distance = const osm.Distance();

  Future<SnapHistoryResult> snapHistory(
      List<LocationData> history,
      ) async {

    if (history.length < 2) {
      return SnapHistoryResult(
        snappedPoints: [],
        totalDistanceKm: 0,
        usedFallback: true,
      );
    }

    // 1️⃣ Lọc nhiễu
    final filtered = _filterNoise(history);

    // 2️⃣ Chia chunk
    final chunks = _chunk(filtered, _chunkSize);

    final List<osm.LatLng> finalRoute = [];
    double totalDistance = 0;
    bool usedFallback = false;

    for (final chunk in chunks) {

      final rawPoints = chunk
          .map((e) => osm.LatLng(e.latitude, e.longitude))
          .toList();

      final result =
      await MapboxRouteService.snapSegment(rawPoints);

      if (result == null ||
          result.points.length < 2) {

        // fallback dùng raw
        usedFallback = true;
        finalRoute.addAll(rawPoints);
        continue;
      }


      finalRoute.addAll(result.points);
      totalDistance += result.distanceKm;
    }
    debugPrint("HISTORY LENGTH: ${history.length}");
    return SnapHistoryResult(
      snappedPoints: finalRoute,
      totalDistanceKm: totalDistance,
      usedFallback: usedFallback,
    );
  }

  List<LocationData> _filterNoise(
      List<LocationData> input) {

    final List<LocationData> output = [];

    for (final point in input) {
      if (output.isEmpty) {
        output.add(point);
        continue;
      }

      final d = output.last.distanceTo(point) * 1000;

      if (d >= _minDistanceMeters) {
        output.add(point);
      }
    }

    return output;
  }

  List<List<LocationData>> _chunk(
      List<LocationData> list,
      int size,
      ) {
    final List<List<LocationData>> chunks = [];

    for (int i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(
          i,
          min(i + size, list.length),
        ),
      );
    }

    return chunks;
  }
}