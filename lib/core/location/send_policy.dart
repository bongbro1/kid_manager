import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class SendPolicy {
  bool shouldSend({
    required MotionState motion,
    required double distanceKm,
    required Duration sinceLast,
    required bool isNight,
    required double accuracyM,
    required TransportMode transport,
    double? turnDeg,
  }) {
    // ✅ ưu tiên cua: nếu rẽ > 25° và accuracy tốt -> gửi ngay
    if (turnDeg != null && turnDeg >= 25 && accuracyM <= 30) {
      return true;
    }
    // 0) Accuracy quá tệ: hạn chế gửi để khỏi “nhảy”
    if (accuracyM >= 80) {
      // chỉ keep-alive thưa
      return sinceLast >= const Duration(minutes: 2);
    }
    if (accuracyM >= 50) {
      return sinceLast >= const Duration(minutes: 1);
    }

    // 1) Ban đêm: gửi thưa hơn
    if (isNight) {
      // vẫn cho keep-alive
      if (sinceLast >= const Duration(minutes: 5)) return true;
      return distanceKm >= 0.1; // 100m
    }

    // 2) chỉnh ngưỡng theo transport
    // walking: chậm, distance nhỏ -> đừng gửi quá dày
    // vehicle: đi nhanh -> gửi dày hơn
    Duration movingMinInterval;
    double movingMinDistanceKm;

    switch (transport) {
      case TransportMode.walking:
        movingMinInterval = const Duration(seconds: 10);
        movingMinDistanceKm = 0.012; // ~12m
        break;
      case TransportMode.bicycle:
        movingMinInterval = const Duration(seconds: 7);
        movingMinDistanceKm = 0.015; // ~15m
        break;
      case TransportMode.vehicle:
        movingMinInterval = const Duration(seconds: 5);
        movingMinDistanceKm = 0.020; // ~20m
        break;
      case TransportMode.still:
      case TransportMode.unknown:
        movingMinInterval = const Duration(seconds: 10);
        movingMinDistanceKm = 0.015;
        break;
    }

    switch (motion) {
      case MotionState.moving:
        if (distanceKm >= movingMinDistanceKm) return true;
        if (sinceLast >= movingMinInterval) return true;
        return false;

      case MotionState.idle:
      // idle: gửi thưa hơn, nhưng vẫn keep-alive để parent biết online
        if (distanceKm >= 0.02) return true; // 20m
        return sinceLast >= const Duration(minutes: 1);

      case MotionState.stationary:
      // stationary: keep-alive 2-5 phút
        return sinceLast >= const Duration(minutes: 3);
    }
  }
}