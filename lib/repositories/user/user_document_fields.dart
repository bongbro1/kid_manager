import 'package:kid_manager/models/user/user_types.dart';

Map<String, dynamic> _buildFamilyMemberBirthdayPublicFields(
  DateTime? birthDate,
) {
  if (birthDate == null) {
    return const <String, dynamic>{};
  }

  final normalized = DateTime(birthDate.year, birthDate.month, birthDate.day);
  return <String, dynamic>{
    'birthMonth': normalized.month,
    'birthDay': normalized.day,
    'birthYear': normalized.year,
  };
}

Map<String, dynamic> buildFamilyMemberPublicFields({
  required String uid,
  required UserRole role,
  String? familyId,
  String? displayName,
  String? avatarUrl,
  DateTime? dob,
  bool? isActive,
  Object? lastActiveAt,
}) {
  return <String, dynamic>{
    'uid': uid,
    'role': roleToString(role),
    if (familyId != null && familyId.isNotEmpty) 'familyId': familyId,
    if (displayName != null) 'displayName': displayName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (isActive != null) 'isActive': isActive,
    if (lastActiveAt != null) 'lastActiveAt': lastActiveAt,
    ..._buildFamilyMemberBirthdayPublicFields(dob),
  };
}
