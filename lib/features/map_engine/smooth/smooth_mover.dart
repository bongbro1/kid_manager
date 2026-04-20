import 'package:kid_manager/models/location/location_data.dart';

double _lerp(double a, double b, double t) => a + (b - a) * t;

double _lerpAngle(double a, double b, double t) {
  var diff = (b - a) % 360;
  if (diff > 180) diff -= 360;
  return (a + diff * t) % 360;
}

class SmoothMover {
  LocationData? _from;
  LocationData? _to;
  DateTime _start = DateTime.fromMillisecondsSinceEpoch(0);
  final int durationMs;

  SmoothMover({this.durationMs = 650});

  void push(LocationData next) {
    if (_to == null) {
      _from = next;
      _to = next;
      _start = DateTime.now();
      return;
    }
    _from = current(); // bắt đầu từ trạng thái đang nội suy
    _to = next;
    _start = DateTime.now();
  }

  LocationData current() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return to ?? from!;

    final t = DateTime.now().difference(_start).inMilliseconds / durationMs;
    final tt = t.clamp(0.0, 1.0);

    return to.copyWith(
      latitude: _lerp(from.latitude, to.latitude, tt),
      longitude: _lerp(from.longitude, to.longitude, tt),
      heading: _lerpAngle(from.heading, to.heading, tt),
      speed: _lerp(from.speed, to.speed, tt),
      accuracy: _lerp(from.accuracy, to.accuracy, tt),
      timestamp: to.timestamp,
      transport: to.transport,
    );
  }

  bool get isAnimating {
    final to = _to;
    if (to == null) return false;
    return DateTime.now().difference(_start).inMilliseconds < durationMs;
  }
}
