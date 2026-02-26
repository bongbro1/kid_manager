import 'package:kid_manager/core/location/history_snap_engine.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:latlong2/latlong.dart' as osm;

class TrackingEngine {
  final HistorySnapEngine snapEngine;

  TrackingEngine(this.snapEngine);

  Future<List<osm.LatLng>> processHistory(
      List<LocationData> raw) async {

    final result = await snapEngine.snapHistory(raw);
    return result.snappedPoints;
  }
}