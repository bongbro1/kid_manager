
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/models/location/location_data.dart';

abstract class LocationRepository {
  // child write
  Future<void> updateMyCurrent(TrackingPayload payload);
  Future<void> appendMyHistory(TrackingPayload payload);
  Future<void> updateMyLocation(TrackingPayload payload);

  // parent read via functions
  Stream<LocationData> watchChildLocation(String childId);
  Future<List<LocationData>> getLocationHistoryByDay(String childId, DateTime day);
}
