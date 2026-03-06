import 'dart:math';

/// returns polygon ring: [[lng,lat], ...]
List<List<double>> circlePolygon({
  required double lat,
  required double lng,
  required double radiusM,
  int points = 64,
}) {
  const earthRadius = 6371000.0;
  final radLat = lat * pi / 180.0;
  final radLng = lng * pi / 180.0;
  final angDist = radiusM / earthRadius;

  final out = <List<double>>[];
  for (int i = 0; i <= points; i++) {
    final brng = 2 * pi * (i / points);
    final lat2 = asin(
      sin(radLat) * cos(angDist) + cos(radLat) * sin(angDist) * cos(brng),
    );
    final lng2 = radLng +
        atan2(
          sin(brng) * sin(angDist) * cos(radLat),
          cos(angDist) - sin(radLat) * sin(lat2),
        );
    out.add([lng2 * 180.0 / pi, lat2 * 180.0 / pi]);
  }
  return out;
}

/// meters/pixel at given zoom + latitude (WebMercator)
double metersPerPixelFromZoomLat({required double zoom, required double lat}) {
  final mpp = 156543.03392 * cos(lat * pi / 180.0) / pow(2.0, zoom);
  return max(0.01, mpp);
}