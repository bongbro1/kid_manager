import 'package:kid_manager/models/location/location_data.dart';

class Kalman2D {
  double _lat;
  double _lng;

  double _variance = 1;
  final double _processNoise = 0.00001;
  final double _measurementNoise = 0.001;

  Kalman2D(this._lat, this._lng);

  LocationData filter(LocationData input) {
    _variance += _processNoise;

    final k = _variance / (_variance + _measurementNoise);

    _lat += k * (input.latitude - _lat);
    _lng += k * (input.longitude - _lng);

    _variance *= (1 - k);

    return LocationData(
      latitude: _lat,
      longitude: _lng,
      accuracy: input.accuracy,
      timestamp: input.timestamp,
    );
  }
}
