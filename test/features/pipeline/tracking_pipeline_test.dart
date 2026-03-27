import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/features/pipeline/tracking_pipeline.dart';
import 'package:kid_manager/helpers/location/effective_speed_estimator.dart';
import 'package:kid_manager/models/location/location_data.dart';

void main() {
  group('TrackingPipeline indoor drift control', () {
    late TrackingPipeline pipeline;
    late DateTime baseTime;
    late LocationData anchor;

    setUp(() {
      pipeline = TrackingPipeline(
        motionDetector: MotionDetector(),
        sendPolicy: SendPolicy(),
      );
      baseTime = DateTime(2026, 3, 25, 14, 0, 0);
      anchor = _point(
        latitude: 21.0305,
        longitude: 105.7822,
        accuracy: 8,
        speed: 1.1,
        time: baseTime,
      );
      pipeline.acknowledgeHistorySent(
        anchor,
        MotionState.moving,
        sentAt: baseTime,
      );
    });

    test('does not treat stationary indoor jitter as movement', () {
      final jitter = _point(
        latitude: anchor.latitude + _metersToLatitude(18),
        longitude: anchor.longitude,
        accuracy: 18,
        speed: 0.15,
        time: baseTime.add(const Duration(seconds: 5)),
      );

      final result = pipeline.process(
        jitter,
        null,
        previousReference: anchor,
        now: baseTime.add(const Duration(seconds: 5)),
      );

      expect(result.motion, isNot(MotionState.moving));
      expect(result.shouldSend, isFalse);
      expect(
        result.filteredLocation.distanceTo(anchor) * 1000,
        lessThan(1),
      );
    });

    test('still sends genuine walking movement with good accuracy', () {
      final walking = _point(
        latitude: anchor.latitude + _metersToLatitude(22),
        longitude: anchor.longitude,
        accuracy: 6,
        speed: 1.3,
        time: baseTime.add(const Duration(seconds: 12)),
      );

      final result = pipeline.process(
        walking,
        null,
        previousReference: anchor,
        now: baseTime.add(const Duration(seconds: 12)),
      );

      expect(result.motion, MotionState.moving);
      expect(result.shouldSend, isTrue);
      expect(
        result.filteredLocation.distanceTo(anchor) * 1000,
        greaterThan(15),
      );
    });
  });

  group('EffectiveSpeedEstimator indoor jitter guard', () {
    test('returns zero speed inside combined accuracy envelope', () {
      final from = _point(
        latitude: 21.0305,
        longitude: 105.7822,
        accuracy: 18,
        speed: 0,
        time: DateTime(2026, 3, 25, 14, 0, 0),
      );
      final to = _point(
        latitude: from.latitude + _metersToLatitude(18),
        longitude: from.longitude,
        accuracy: 18,
        speed: 0,
        time: DateTime(2026, 3, 25, 14, 0, 5),
      );

      expect(
        EffectiveSpeedEstimator.resolvePointSpeedMps(
          to,
          previous: from,
        ),
        0,
      );
    });
  });
}

LocationData _point({
  required double latitude,
  required double longitude,
  required double accuracy,
  required double speed,
  required DateTime time,
}) {
  return LocationData(
    latitude: latitude,
    longitude: longitude,
    accuracy: accuracy,
    speed: speed,
    timestamp: time.millisecondsSinceEpoch,
    heading: 0,
  );
}

double _metersToLatitude(double meters) {
  return meters / 111320.0;
}
