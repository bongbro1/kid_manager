import 'package:flutter/foundation.dart';

class MapFocusRequest {
  final String? childUid;
  final double? lat;
  final double? lng;
  final String? zoneId;
  final String? zoneName;
  final bool openSheet;

  const MapFocusRequest({
    this.childUid,
    this.lat,
    this.lng,
    this.zoneId,
    this.zoneName,
    this.openSheet = false,
  });

  bool get hasPosition => lat != null && lng != null;
}

final ValueNotifier<MapFocusRequest?> mapFocusNotifier =
    ValueNotifier<MapFocusRequest?>(null);
