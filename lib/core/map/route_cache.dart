import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';

class RouteCache {
  static Future<void> save(
      String key,
      List<LatLng> points,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = jsonEncode(
      points.map((p) => [p.latitude, p.longitude]).toList(),
    );

    await prefs.setString(key, encoded);
  }
  static Future<void> clearChildCache(String childId) async {
    final prefs = await SharedPreferences.getInstance();

    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(childId)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<List<LatLng>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    if (raw == null) return null;

    final decoded = jsonDecode(raw) as List;

    return decoded
        .map((e) => LatLng(e[0], e[1]))
        .toList();
  }
}
