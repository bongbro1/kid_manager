import 'package:latlong2/latlong.dart' as osm;
import 'package:kid_manager/services/location/mapbox_gateway_service.dart';

class MapboxRouteResult {
  const MapboxRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final List<osm.LatLng> points;
  final double distanceKm;
  final double durationMinutes;
}

class MapboxRouteService {
  static final MapboxGatewayService _gateway = MapboxGatewayService();

  static Future<MapboxRouteResult?> snapSegment(List<osm.LatLng> input) async {
    if (input.length < 3) {
      return null;
    }

    final result = await _gateway.matchTrace(
      points: input
          .map(
            (point) => MapboxTracePointInput(
              latitude: point.latitude,
              longitude: point.longitude,
              accuracy: 30,
            ),
          )
          .toList(growable: false),
      profile: 'mapbox/driving',
      tidy: true,
    );

    if (result == null || result.routeCoordinates.length < 2) {
      return null;
    }

    return MapboxRouteResult(
      points: result.routeCoordinates
          .map((coordinate) => osm.LatLng(coordinate[1], coordinate[0]))
          .toList(growable: false),
      distanceKm: result.distanceMeters / 1000,
      durationMinutes: result.durationSeconds / 60,
    );
  }
}
