import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';

Map<String, dynamic> buildFamilyMemberPublicFields({
  required String uid,
  required UserRole role,
  String? familyId,
  String? displayName,
  String? email,
  String? avatarUrl,
  String? timezone,
  DateTime? dob,
  String? parentUid,
  bool? isActive,
  bool? allowTracking,
  List<String>? managedChildIds,
  Object? lastActiveAt,
}) {
  final normalizedManagedChildIds = managedChildIds
      ?.map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet()
      .toList(growable: false);

  return <String, dynamic>{
    'uid': uid,
    'role': roleToString(role),
    if (familyId != null && familyId.isNotEmpty) 'familyId': familyId,
    if (displayName != null) 'displayName': displayName,
    if (email != null && email.isNotEmpty) 'email': email,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
    if (parentUid != null && parentUid.isNotEmpty) 'parentUid': parentUid,
    if (isActive != null) 'isActive': isActive,
    if (allowTracking != null) 'allowTracking': allowTracking,
    if (lastActiveAt != null) 'lastActiveAt': lastActiveAt,
    if (normalizedManagedChildIds != null && normalizedManagedChildIds.isNotEmpty)
      'managedChildIds': normalizedManagedChildIds,
    ...buildBirthdayStorageFields(dob),
  };
}
