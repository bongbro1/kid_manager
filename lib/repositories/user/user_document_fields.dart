import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';

Map<String, dynamic> buildFamilyMemberPublicFields({
  required String uid,
  required UserRole role,
  String? familyId,
  String? displayName,
  String? avatarUrl,
  DateTime? dob,
}) {
  return <String, dynamic>{
    'uid': uid,
    'role': roleToString(role),
    if (familyId != null && familyId.isNotEmpty) 'familyId': familyId,
    if (displayName != null) 'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    ...buildBirthdayStorageFields(dob),
  };
}
