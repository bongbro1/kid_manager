import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../models/location/location_data.dart';

class InteractionController {
  final MapboxMap map;
  final List<LocationData> history;
  final BuildContext context;

  InteractionController(this.map, this.history, this.context);

  Future<void> attach() async {
    map.onMapTapListener = _onMapTap;
  }

  Future<bool> _onMapTap(MapContentGestureContext ctx) async {

    final features = await map.queryRenderedFeatures(
      RenderedQueryGeometry.fromScreenCoordinate(ctx.touchPosition),
      RenderedQueryOptions(
        layerIds: ["history-layer"],
        filter: null,
      ),
    );

    if (features.isEmpty) return true;

    final feature =
    features.first?.queriedFeature.feature as Map<String, dynamic>?;

    final props =
    feature?["properties"] as Map<String, dynamic>?;

    final timestamp = (props?["timestamp"] as num?)?.toInt();
    if (timestamp == null) return true;

    final index =
    history.indexWhere((e) => e.timestamp == timestamp);

    if (index == -1) return true;

    final remaining = history.sublist(index);

    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          "Thời điểm: ${DateTime.fromMillisecondsSinceEpoch(timestamp)}\n"
              "Sau đó đi thêm: ${remaining.length} điểm",
        ),
      ),
    );

    return true;
  }

}