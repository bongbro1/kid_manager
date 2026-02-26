import 'package:flutter_activity_recognition/models/activity.dart';
import 'package:flutter_activity_recognition/models/activity_confidence.dart';
import 'package:flutter_activity_recognition/models/activity_type.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';
class TransportModeDetector {
  TransportMode _mode = TransportMode.unknown;
  TransportMode? _candidate;
  int _candidateSinceMs = 0;

  TransportMode get mode => _mode;

  TransportMode update(LocationData loc, Activity? act) {
    final candidate = _candidateFromActivityOrSpeed(loc, act);

    // candidate null => không đủ tin cậy => giữ mode
    if (candidate == null || candidate == _mode) {
      _candidate = null;
      _candidateSinceMs = 0;
      return _mode;
    }

    // bắt đầu candidate mới
    if (_candidate != candidate) {
      _candidate = candidate;
      _candidateSinceMs = loc.timestamp;
      return _mode;
    }

    // giữ đủ lâu thì switch (10s)
    if (loc.timestamp - _candidateSinceMs >= 10 * 1000) {
      _mode = candidate;
      _candidate = null;
      _candidateSinceMs = 0;
    }

    return _mode;
  }

  TransportMode? _candidateFromActivityOrSpeed(LocationData loc, Activity? act) {
    final s = loc.speedKmh;

    // 1) Activity ưu tiên nếu >= MEDIUM
    if (act != null && act.confidence != ActivityConfidence.LOW) {
      switch (act.type) {
        case ActivityType.IN_VEHICLE:
          return TransportMode.vehicle;

        case ActivityType.ON_BICYCLE:
        // nếu speed quá cao bất thường cho bicycle => nghi vehicle
          if (s > 45) return TransportMode.vehicle;
          return TransportMode.bicycle;

        case ActivityType.WALKING:
        case ActivityType.RUNNING:
        // nếu speed cao quá -> không hợp walking
          if (s > 18) return TransportMode.vehicle;
          return TransportMode.walking;

        case ActivityType.STILL:
        // STILL chỉ tin nếu speed thật sự thấp
          if (s < 2.0) return TransportMode.still;
          break;

        case ActivityType.UNKNOWN:
          break;
      }
    }
  // trước khi check accuracy
    if (s < 1.0) return TransportMode.still;
    // 2) fallback speed (chỉ khi GPS đủ sạch)
    if (loc.accuracy > 30) return null;

    if (s < 1.0) return TransportMode.still;
    if (s < 8.0) return TransportMode.walking;
    if (s < 22.0) return TransportMode.bicycle;
    return TransportMode.vehicle;
  }
}