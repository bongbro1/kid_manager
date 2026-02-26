import 'dart:math';

import 'package:kid_manager/models/location/location_data.dart';

class TracePreprocessor {
  /// intervalMs: mục tiêu ~1 điểm / 5 giây
  /// minDistanceM: nếu đi xa hơn X mét thì giữ (dù chưa đủ 5s)
  /// minTurnDeg: nếu có cua gắt hơn X độ thì giữ để không mất hình đường
  /// maxAccuracyM: bỏ điểm GPS quá sai (giảm map matching sai)
  /// maxSpeedMps: bỏ spike nhảy điểm (GPS jump)
  static List<LocationData> thin(
      List<LocationData> input, {
        int intervalMs = 5000,
        double minDistanceM = 10,
        double minTurnDeg = 25,
        double maxAccuracyM = 50,
        double maxSpeedMps = 60, // 60 m/s ~ 216 km/h (lọc jump cực mạnh)
      }) {
    if (input.length <= 2) return input;

    // sort theo thời gian
    final pts = [...input]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // lọc accuracy quá lớn (GPS quá sai)
    final filtered = pts.where((p) {
      final okAcc = p.accuracy > 0 && p.accuracy <= maxAccuracyM;
      return okAcc;
    }).toList();

    // nếu lọc xong còn quá ít, fallback dùng dữ liệu gốc
    final base = filtered.length >= 2 ? filtered : pts;

    if (base.length <= 2) return base;

    final out = <LocationData>[];
    out.add(base.first);

    for (int i = 1; i < base.length - 1; i++) {
      final prevKept = out.last;
      final cur = base[i];
      final next = base[i + 1];

      final dtMs = cur.timestamp - prevKept.timestamp;
      if (dtMs <= 0) continue;

      final distM = prevKept.distanceTo(cur) * 1000.0; // distanceTo trả km
      final speedMps = distM / (dtMs / 1000.0);

      // bỏ spike nhảy điểm
      if (speedMps > maxSpeedMps) continue;

      final keepByTime = dtMs >= intervalMs;
      final keepByDistance = distM >= minDistanceM;

      // giữ cua: tính góc đổi hướng
      final b1 = _bearing(prevKept, cur);
      final b2 = _bearing(cur, next);
      final turnDeg = _angleDiff(b1, b2);
      final keepByTurn = turnDeg >= minTurnDeg;

      if (keepByTime || keepByDistance || keepByTurn) {
        out.add(cur);
      }
    }

    out.add(base.last);

    // đảm bảo >= 2 điểm
    if (out.length < 2) return [base.first, base.last];
    return out;
  }

  static double _bearing(LocationData a, LocationData b) {
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x); // radians

    final deg = (_rad2deg(brng) + 360.0) % 360.0;
    return deg;
  }

  static double _angleDiff(double a, double b) {
    var diff = (a - b).abs() % 360.0;
    if (diff > 180.0) diff = 360.0 - diff;
    return diff; // 0..180
  }

  static double _deg2rad(double d) => d * pi / 180.0;
  static double _rad2deg(double r) => r * 180.0 / pi;
}