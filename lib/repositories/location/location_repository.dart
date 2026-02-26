
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/models/location/location_data.dart';

abstract class LocationRepository {
  Future<void> updateMyLocation(TrackingPayload payload);

  Stream<LocationData> watchChildLocation(String childId);

  Future<List<LocationData>> getLocationHistory(String childId);


  Future<void> updateMyCurrent(TrackingPayload payload);
  Future<void> appendMyHistory(TrackingPayload payload);
}
