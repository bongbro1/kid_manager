
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/models/location/location_data.dart';

class TrackingResult {
  final LocationData filteredLocation;
  final bool shouldSend;
  final MotionState motion;

  TrackingResult({
    required this.filteredLocation,
    required this.shouldSend,
    required this.motion,
  });
}
