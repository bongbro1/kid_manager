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


  static Future<List<osm.LatLng>?> snapSegment(
      List<osm.LatLng> input,
      ) async {

    if (input.length < 2) return null;

    final coordinates = input
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      'https://api.mapbox.com/matching/v5/mapbox/driving/'
          '$coordinates'
          '?geometries=polyline6'
          '&overview=full'
          '&access_token=$_token',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);

    if (data['matchings'] == null ||
        data['matchings'].isEmpty) return null;

    final geometry =
    data['matchings'][0]['geometry'];

    final decoded =
    PolylineCodec.decode(geometry, precision: 6);

    return decoded
        .map((p) => osm.LatLng(
      p[0].toDouble(),
      p[1].toDouble(),
    ))
        .toList();
  }


}
