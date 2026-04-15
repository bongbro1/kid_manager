import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/user/user_types.dart';

@immutable
class TrackingWarmupSnapshot {
  const TrackingWarmupSnapshot({
    required this.uid,
    required this.role,
    required this.familyId,
    required this.parentUid,
    required this.allowTracking,
    required this.displayName,
    required this.timeZone,
    required this.locationMemberIds,
  });

  final String uid;
  final UserRole role;
  final String familyId;
  final String parentUid;
  final bool allowTracking;
  final String displayName;
  final String timeZone;
  final List<String> locationMemberIds;

  bool get isParent => role == UserRole.parent;
  bool get isGuardian => role == UserRole.guardian;
  bool get isChild => role == UserRole.child;
  bool get isLocationViewer => isParent || isGuardian;

  String get familyScopeKey => '${role.name}|$uid|$familyId|$parentUid';

  String get locationSyncKey {
    final ids = <String>[...locationMemberIds]..sort();
    return '${role.name}|$uid|${ids.join(",")}';
  }

  String get selfTrackingKey =>
      '${role.name}|$uid|$allowTracking|$familyId|$parentUid|$displayName|$timeZone';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrackingWarmupSnapshot &&
        other.uid == uid &&
        other.role == role &&
        other.familyId == familyId &&
        other.parentUid == parentUid &&
        other.allowTracking == allowTracking &&
        other.displayName == displayName &&
        other.timeZone == timeZone &&
        listEquals(other.locationMemberIds, locationMemberIds);
  }

  @override
  int get hashCode => Object.hash(
    uid,
    role,
    familyId,
    parentUid,
    allowTracking,
    displayName,
    timeZone,
    Object.hashAll(locationMemberIds),
  );
}
