
import 'package:kid_manager/models/location/location_data.dart';

enum MotionState {
  moving,
  idle,
  stationary,
}

class TrackingState {
  final MotionState motion;
  final LocationData? lastSent;
  final DateTime? lastMoveAt;
  final DateTime? lastSentAt;

  const TrackingState({
    required this.motion,
    this.lastSent,
    this.lastMoveAt,
    this.lastSentAt,
  });

  TrackingState copyWith({
    MotionState? motion,
    LocationData? lastSent,
    DateTime? lastMoveAt,
    DateTime? lastSentAt,
  }) {
    return TrackingState(
      motion: motion ?? this.motion,
      lastSent: lastSent ?? this.lastSent,
      lastMoveAt: lastMoveAt ?? this.lastMoveAt,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }
}
