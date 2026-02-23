
import 'package:kid_manager/models/location/location_data.dart';

class TrackingEvent {
  final String deviceId;
  final LocationData rawLocation;
  final DateTime receivedAt;

  TrackingEvent({
    required this.deviceId,
    required this.rawLocation,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();
}
