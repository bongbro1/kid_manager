import 'package:flutter/foundation.dart';

class SosFocus {
  final double lat;
  final double lng;
  final String? childUid;
  final String familyId;
  final String sosId;

  SosFocus({
    required this.lat,
    required this.lng,
    required this.familyId,
    required this.sosId,
    this.childUid,
  });
}

final ValueNotifier<SosFocus?> sosFocusNotifier = ValueNotifier<SosFocus?>(
  null,
);
