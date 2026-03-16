import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/helpers/zone/zone_circle.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/widgets/map/map_ornaments.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mbx;

class ZoneDetailWidget extends StatelessWidget {
  final NotificationDetailModel detail;
  final VoidCallback? onViewMap;
  final VoidCallback? onPhone;

  const ZoneDetailWidget({
    super.key,
    required this.detail,
    this.onViewMap,
    this.onPhone,
  });

  Map<String, dynamic> get _data => detail.data;

  String get _zoneName => (_data['zoneName'] ?? detail.content ?? '').toString();

  String get _zoneType => (_data['zoneType'] ?? '').toString().toLowerCase();
  String get _action => (_data['action'] ?? '').toString().toLowerCase();
  String get _eventKey =>
      (_data['eventKey'] ?? detail.title ?? '').toString().toLowerCase();

  double? get _lat => _readDouble(_data['lat'] ?? _data['latitude']);
  double? get _lng => _readDouble(_data['lng'] ?? _data['longitude']);
  double? get _radiusM => _readDouble(_data['radiusM'] ?? _data['radius']);

  String get _locationLabel {
    final raw = (_data['placeName'] ??
            _data['address'] ??
            _data['locationName'] ??
            _zoneName)
        .toString()
        .trim();
    return raw.isEmpty ? _zoneName : raw;
  }

  String _childName(AppLocalizations l10n) =>
      (_data['childName'] ??
              _data['displayName'] ??
              _data['name'] ??
              _data['fullName'] ??
              l10n.notificationsDefaultChildName)
          .toString();

  bool get _isDanger =>
      _zoneType.isNotEmpty ? _zoneType == 'danger' : _eventKey.contains('.danger.');

  bool get _isEnter =>
      _action.isNotEmpty ? _action == 'enter' : _eventKey.contains('zone.enter.');

  String _descriptionText(AppLocalizations l10n) {
    final childName = _childName(l10n);
    if (_isDanger && _isEnter) {
      return l10n.notificationsZoneDangerEnterDescription(
        childName,
        _zoneName,
        _clock(detail.createdAt),
      );
    }
    if (!_isDanger && !_isEnter) {
      return l10n.notificationsZoneSafeExitDescription(
        childName,
        _zoneName,
        _clock(detail.createdAt),
      );
    }
    if (_isDanger && !_isEnter) {
      return l10n.notificationsZoneDangerExitDescription(
        childName,
        _zoneName,
        _clock(detail.createdAt),
      );
    }
    return l10n.notificationsZoneUpdatedDescription(childName, _zoneName);
  }

  String _clock(DateTime dt) => DateFormat('HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDescription(l10n),
        const SizedBox(height: 16),
        _buildMapPreview(),
        const SizedBox(height: 16),
        _buildPrimaryButton(l10n),
        const SizedBox(height: 10),
        _buildSecondaryButton(l10n),
      ],
    );
  }

  Widget _buildDescription(AppLocalizations l10n) {
    return Text(
      _descriptionText(l10n),
      style: const TextStyle(
        fontSize: 15,
        height: 1.6,
        color: Color(0xFF475569),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMapPreview() {
    final lat = _lat;
    final lng = _lng;
    if (lat == null || lng == null) {
      return _ZoneMapFallback(
        label: _locationLabel,
        isDanger: _isDanger,
      );
    }

    return _ZoneMapPreview(
      lat: lat,
      lng: lng,
      radiusM: _radiusM,
      label: _locationLabel,
      isDanger: _isDanger,
    );
  }

  Widget _buildPrimaryButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onViewMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(l10n.notificationsZoneViewOnMainMapButton),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPhone,
          icon: const Icon(Icons.phone_in_talk_outlined, size: 18),
          label: Text(l10n.notificationsContactNowButton),
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: const Color(0xFF334155),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoneMapPreview extends StatefulWidget {
  final double lat;
  final double lng;
  final double? radiusM;
  final String label;
  final bool isDanger;

  const _ZoneMapPreview({
    required this.lat,
    required this.lng,
    required this.radiusM,
    required this.label,
    required this.isDanger,
  });

  @override
  State<_ZoneMapPreview> createState() => _ZoneMapPreviewState();
}

class _ZoneMapPreviewState extends State<_ZoneMapPreview> {
  static const String _styleUri = 'mapbox://styles/mapbox/streets-v12';
  static const String _pointSourceId = 'zone-detail-point-source';
  static const String _pointHaloLayerId = 'zone-detail-point-halo-layer';
  static const String _pointLayerId = 'zone-detail-point-layer';
  static const String _areaSourceId = 'zone-detail-area-source';
  static const String _areaFillLayerId = 'zone-detail-area-fill-layer';
  static const String _areaLineLayerId = 'zone-detail-area-line-layer';

  mbx.MapboxMap? _map;

  @override
  void didUpdateWidget(covariant _ZoneMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat ||
        oldWidget.lng != widget.lng ||
        oldWidget.radiusM != widget.radiusM ||
        oldWidget.isDanger != widget.isDanger) {
      final map = _map;
      if (map != null) {
        _syncMap(map);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: const Color(0xFFF1F5F9),
        child: Column(
          children: [
            SizedBox(
              height: 188,
              child: IgnorePointer(
                child: mbx.MapWidget(
                  key: ValueKey(
                    'zone-preview-${widget.lat}-${widget.lng}-${widget.radiusM}-${widget.isDanger}',
                  ),
                  styleUri: _styleUri,
                  cameraOptions: mbx.CameraOptions(
                    center: mbx.Point(
                      coordinates: mbx.Position(widget.lng, widget.lat),
                    ),
                    zoom: 15.5,
                  ),
                  mapOptions: mbx.MapOptions(
                    pixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                  onMapCreated: (map) {
                    _map = map;
                  },
                  onStyleLoadedListener: (_) async {
                    final map = _map;
                    if (map == null) return;
                    await hideMapOrnaments(map);
                    await _syncMap(map);
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: widget.isDanger
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((widget.radiusM ?? 0) > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Bán kính ${(widget.radiusM ?? 0).toStringAsFixed(0)}m',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _syncMap(mbx.MapboxMap map) async {
    await _ensureSources(map);
    await _ensureLayers(map);
    await _updateSources(map);
    await _fitCamera(map);
  }

  Future<void> _ensureSources(mbx.MapboxMap map) async {
    if (!await map.style.styleSourceExists(_pointSourceId)) {
      await map.style.addSource(
        mbx.GeoJsonSource(
          id: _pointSourceId,
          data: jsonEncode(_emptyFeatureCollection()),
        ),
      );
    }

    if (!await map.style.styleSourceExists(_areaSourceId)) {
      await map.style.addSource(
        mbx.GeoJsonSource(
          id: _areaSourceId,
          data: jsonEncode(_emptyFeatureCollection()),
        ),
      );
    }
  }

  Future<void> _ensureLayers(mbx.MapboxMap map) async {
    if (!await map.style.styleLayerExists(_areaFillLayerId)) {
      await map.style.addLayer(
        mbx.FillLayer(
          id: _areaFillLayerId,
          sourceId: _areaSourceId,
          fillColor: _fillColor,
          fillOpacity: 0.3,
        ),
      );
    }

    if (!await map.style.styleLayerExists(_areaLineLayerId)) {
      await map.style.addLayer(
        mbx.LineLayer(
          id: _areaLineLayerId,
          sourceId: _areaSourceId,
          lineColor: _lineColor,
          lineWidth: 2.2,
        ),
      );
    }

    if (!await map.style.styleLayerExists(_pointHaloLayerId)) {
      await map.style.addLayer(
        mbx.CircleLayer(
          id: _pointHaloLayerId,
          sourceId: _pointSourceId,
          circleColor: _haloColor,
          circleRadius: 14.0,
          circleOpacity: 0.45,
        ),
      );
    }

    if (!await map.style.styleLayerExists(_pointLayerId)) {
      await map.style.addLayer(
        mbx.CircleLayer(
          id: _pointLayerId,
          sourceId: _pointSourceId,
          circleColor: _lineColor,
          circleRadius: 6.0,
          circleStrokeColor: 0xFFFFFFFF,
          circleStrokeWidth: 2.0,
        ),
      );
    }
  }

  Future<void> _updateSources(mbx.MapboxMap map) async {
    final pointSource = await map.style.getSource(_pointSourceId);
    if (pointSource is mbx.GeoJsonSource) {
      await pointSource.updateGeoJSON(
        jsonEncode({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [widget.lng, widget.lat],
              },
              'properties': <String, dynamic>{},
            },
          ],
        }),
      );
    }

    final areaSource = await map.style.getSource(_areaSourceId);
    if (areaSource is mbx.GeoJsonSource) {
      if ((widget.radiusM ?? 0) > 0) {
        final ring = circlePolygon(
          lat: widget.lat,
          lng: widget.lng,
          radiusM: widget.radiusM!,
          points: 64,
        );
        await areaSource.updateGeoJSON(
          jsonEncode({
            'type': 'FeatureCollection',
            'features': [
              {
                'type': 'Feature',
                'geometry': {
                  'type': 'Polygon',
                  'coordinates': [ring],
                },
                'properties': <String, dynamic>{},
              },
            ],
          }),
        );
      } else {
        await areaSource.updateGeoJSON(jsonEncode(_emptyFeatureCollection()));
      }
    }
  }

  Future<void> _fitCamera(mbx.MapboxMap map) async {
    final radius = widget.radiusM ?? 0;
    if (radius <= 0) {
      await map.setCamera(
        mbx.CameraOptions(
          center: mbx.Point(coordinates: mbx.Position(widget.lng, widget.lat)),
          zoom: 15.8,
        ),
      );
      return;
    }

    final ring = circlePolygon(
      lat: widget.lat,
      lng: widget.lng,
      radiusM: radius,
      points: 64,
    );

    double minLng = ring.first[0];
    double maxLng = ring.first[0];
    double minLat = ring.first[1];
    double maxLat = ring.first[1];

    for (final point in ring) {
      if (point[0] < minLng) minLng = point[0];
      if (point[0] > maxLng) maxLng = point[0];
      if (point[1] < minLat) minLat = point[1];
      if (point[1] > maxLat) maxLat = point[1];
    }

    try {
      final camera = await map.cameraForCoordinateBounds(
        mbx.CoordinateBounds(
          southwest: mbx.Point(coordinates: mbx.Position(minLng, minLat)),
          northeast: mbx.Point(coordinates: mbx.Position(maxLng, maxLat)),
          infiniteBounds: false,
        ),
        mbx.MbxEdgeInsets(top: 48, left: 28, bottom: 48, right: 28),
        null,
        null,
        null,
        null,
      );
      await map.setCamera(camera);
    } catch (_) {
      await map.setCamera(
        mbx.CameraOptions(
          center: mbx.Point(coordinates: mbx.Position(widget.lng, widget.lat)),
          zoom: 15.2,
        ),
      );
    }
  }

  int get _fillColor => widget.isDanger ? 0x33EF4444 : 0x332563EB;
  int get _lineColor => widget.isDanger ? 0xFFDC2626 : 0xFF2563EB;
  int get _haloColor => widget.isDanger ? 0x55FCA5A5 : 0x5593C5FD;

  Map<String, dynamic> _emptyFeatureCollection() => const {
        'type': 'FeatureCollection',
        'features': [],
      };
}

class _ZoneMapFallback extends StatelessWidget {
  final String label;
  final bool isDanger;

  const _ZoneMapFallback({
    required this.label,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        color: const Color(0xFFF1F5F9),
        child: Column(
          children: [
            Container(
              height: 188,
              width: double.infinity,
              color: const Color(0xFFE2E8F0),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.map_outlined,
                    size: 32,
                    color: isDanger
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Không có tọa độ để hiển thị bản đồ',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: isDanger
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}
