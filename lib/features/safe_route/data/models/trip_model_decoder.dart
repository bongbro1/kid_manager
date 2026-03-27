import 'package:flutter/foundation.dart';
import 'package:kid_manager/features/safe_route/data/models/trip_model.dart';

TripModel? tryParseTripModel(
  Map<String, dynamic>? map, {
  String? source,
}) {
  if (map == null) {
    return null;
  }

  try {
    return TripModel.fromMap(map);
  } catch (error, stackTrace) {
    debugPrint(
      '[SafeRoute] skip invalid trip payload'
      '${source == null ? '' : ' ($source)'}: $error\n$stackTrace',
    );
    return null;
  }
}
