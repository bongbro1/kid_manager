import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:polyline_codec/polyline_codec.dart';

class MapboxRouteResult {
  final List<osm.LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  MapboxRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class MapboxRouteService {
  static final String _token =
      dotenv.env['ACCESS_TOKEN'] ?? '';


  static Future<MapboxRouteResult?> snapSegment(
      List<osm.LatLng> input,
      ) async {
    debugPrint("Vao day roai");

    if (input.length < 3) {
      debugPrint("❌ Not enough points");
      return null;
    }

    final coordinates = input
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final radiuses =
    List.filled(input.length, 30).join(';');

    final url = Uri.parse(
      'https://api.mapbox.com/matching/v5/mapbox/driving/'
          '$coordinates'
          '?geometries=polyline6'
          '&overview=full'
          '&radiuses=$radiuses'
          '&steps=false'
          '&annotations=distance,duration'
          '&tidy=true'
          '&access_token=$_token',
    );

    final response = await http.get(url);
    debugPrint("STATUS: ${response.statusCode}");
    debugPrint("BODY: ${response.body}");

    if (response.statusCode != 200) {
      debugPrint("❌ MATCHING ERROR");
      return null;
    }

    final data = json.decode(response.body);
    debugPrint("GEOMETRY: ${data['matchings'][0]['geometry']}");

    if (data['matchings'] == null ||
        data['matchings'].isEmpty) {
      debugPrint("❌ No matchings");
      return null;
    }

    final matching = data['matchings'][0];

    final geometry = matching['geometry'];
    final decoded =
    PolylineCodec.decode(geometry, precision: 6);
    debugPrint("DECODED LENGTH: ${decoded.length}");
    debugPrint("FIRST POINT: ${decoded.first}");
    final points =decoded
        .map((p) => osm.LatLng(
      p[0].toDouble(),
      p[1].toDouble(),
    ))
        .toList();

    final distanceMeters =
        (matching['distance'] as num?)?.toDouble() ?? 0;

    final durationSeconds =
        (matching['duration'] as num?)?.toDouble() ?? 0;

    return MapboxRouteResult(
      points: points,
      distanceKm: distanceMeters / 1000,
      durationMinutes: durationSeconds / 60,
    );
  }


}
