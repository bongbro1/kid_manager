import 'dart:collection';
import 'package:latlong2/latlong.dart';

class LiveRouteController {
  static const double _minDistanceMeters = 8;
  static const int _maxPoints = 400;

  final ListQueue<LatLng> _points = ListQueue();
  final Distance _distance = const Distance();

  List<LatLng> get points => _points.toList();

  void addPoint(LatLng newPoint) {
    if (_points.isEmpty) {
      _points.add(newPoint);
      return;
    }

    final last = _points.last;

    final d = _distance.as(
      LengthUnit.Meter,
      last,
      newPoint,
    );

    if (d < _minDistanceMeters) return;

    // exponential smoothing (Google-like)
    final smooth = LatLng(
      last.latitude * 0.75 + newPoint.latitude * 0.25,
      last.longitude * 0.75 + newPoint.longitude * 0.25,
    );

    _points.add(smooth);

    if (_points.length > _maxPoints) {
      _points.removeFirst();
    }
  }

  void setInitial(List<LatLng> initial) {
    _points.clear();
    _points.addAll(initial);
  }

  void clear() {
    _points.clear();
  }
}
