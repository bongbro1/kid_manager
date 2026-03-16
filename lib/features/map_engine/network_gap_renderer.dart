import 'dart:convert';

import 'package:kid_manager/features/map_engine/services/history_gap_detector.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class NetworkGapRenderer {
  final MapboxMap map;

  NetworkGapRenderer(this.map);

  Future<void> init() async {
    final style = map.style;

    await style.addSource(
      GeoJsonSource(
        id: 'network-gap-line-source',
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );
    await style.addLayer(
      LineLayer(
        id: 'network-gap-line-layer',
        sourceId: 'network-gap-line-source',
        lineWidth: 4,
        lineColor: 0xFFF57C00,
        lineOpacity: 0.88,
      ),
    );

    await style.addSource(
      GeoJsonSource(
        id: 'network-gap-marker-source',
        data: '{"type":"FeatureCollection","features":[]}',
      ),
    );
    await style.addLayer(
      CircleLayer(
        id: 'network-gap-marker-layer',
        sourceId: 'network-gap-marker-source',
        circleRadius: 7,
        circleColor: 0xFFF57C00,
        circleStrokeColor: 0xFFFFFFFF,
        circleStrokeWidth: 2,
      ),
    );
  }

  Future<void> render(List<HistoryGap> gaps) async {
    final lineSource =
        await map.style.getSource('network-gap-line-source') as GeoJsonSource;
    final markerSource =
        await map.style.getSource('network-gap-marker-source') as GeoJsonSource;

    if (gaps.isEmpty) {
      await lineSource.updateGeoJSON('{"type":"FeatureCollection","features":[]}');
      await markerSource.updateGeoJSON('{"type":"FeatureCollection","features":[]}');
      return;
    }

    await lineSource.updateGeoJSON(
      jsonEncode({
        'type': 'FeatureCollection',
        'features': gaps
            .map(
              (gap) => {
                'type': 'Feature',
                'properties': {
                  'kind': 'network_gap',
                  'gapDurationMs': gap.marker.gapDurationMs,
                },
                'geometry': {
                  'type': 'LineString',
                  'coordinates': [
                    [gap.start.longitude, gap.start.latitude],
                    [gap.end.longitude, gap.end.latitude],
                  ],
                },
              },
            )
            .toList(),
      }),
    );

    await markerSource.updateGeoJSON(
      jsonEncode({
        'type': 'FeatureCollection',
        'features': gaps
            .map(
              (gap) => {
                'type': 'Feature',
                'properties': {
                  'kind': 'network_gap_marker',
                  'timestamp': gap.marker.timestamp,
                  'gapDurationMs': gap.marker.gapDurationMs,
                },
                'geometry': {
                  'type': 'Point',
                  'coordinates': [gap.marker.longitude, gap.marker.latitude],
                },
              },
            )
            .toList(),
      }),
    );
  }

  Future<void> clear() => render(const []);
}
