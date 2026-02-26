import 'package:latlong2/latlong.dart';

class GpsOptimizer {
  static const double _minDistanceMeters = 15;

  static List<LatLng> reduce(List<LatLng> input) {
    if (input.length < 2) return input;

    final result = <LatLng>[input.first];
    final distance = Distance();

    for (int i = 1; i < input.length; i++) {
      final lastKept = result.last;
      final current = input[i];

      final d = distance.as(
        LengthUnit.Meter,
        lastKept,
        current,
      );

      if (d >= _minDistanceMeters) {
        result.add(current);
      }
    }

    return result;
  }
}
