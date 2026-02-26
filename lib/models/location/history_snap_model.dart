import 'package:latlong2/latlong.dart' as osm;

class SnapHistoryResult {
  final List<osm.LatLng> snappedPoints;
  final double totalDistanceKm;
  final bool usedFallback;

  SnapHistoryResult({
    required this.snappedPoints,
    required this.totalDistanceKm,
    required this.usedFallback,
  });
}