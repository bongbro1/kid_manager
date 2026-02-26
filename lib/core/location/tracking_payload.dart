
import 'package:kid_manager/models/location/location_data.dart';

class TrackingPayload {
  final String deviceId;
  final LocationData location;
  final String motion;
  final String transport;
  TrackingPayload({
    required this.deviceId,
    required this.location,
    required this.motion,
    required this.transport,
  });

  Map<String, dynamic> toJson() {
    return {
      "deviceId": deviceId,
      ...location.toJson(),
      "motion": motion,
      "transport": transport,
    };
  }
}
