import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';

class UserProfilePatch {
  const UserProfilePatch({
    this.name,
    this.phone,
    this.gender,
    this.dob,
    this.address,
    this.allowTracking,
    this.role,
    this.avatarUrl,
    this.coverUrl,
    this.parentUid,
    this.locale,
    this.managedChildIds,
  });

  final String? name;
  final String? phone;
  final String? gender;
  final String? dob;
  final String? address;
  final bool? allowTracking;
  final UserRole? role;
  final String? avatarUrl;
  final String? coverUrl;
  final String? parentUid;
  final String? locale;
  final List<String>? managedChildIds;

  bool get isEmpty =>
      name == null &&
      phone == null &&
      gender == null &&
      dob == null &&
      address == null &&
      allowTracking == null &&
      role == null &&
      avatarUrl == null &&
      coverUrl == null &&
      parentUid == null &&
      locale == null &&
      managedChildIds == null;

  Map<String, dynamic> toMap() {
    final parsedDob = dob == null ? null : parseFlexibleBirthDate(dob);
    final data = <String, dynamic>{
      if (name != null) 'displayName': name,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      if (parsedDob != null)
        ...buildBirthdayStorageFields(parsedDob)
      else if (dob != null)
        'dob': dob,
      if (address != null) 'address': address,
      if (allowTracking != null) 'allowTracking': allowTracking,
      if (role != null) 'role': roleToString(role!),
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (parentUid != null) 'parentUid': parentUid,
      if (locale != null) 'locale': locale,
      if (managedChildIds != null) 'managedChildIds': managedChildIds,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  UserProfilePatch copyWith({
    String? name,
    String? phone,
    String? gender,
    String? dob,
    String? address,
    bool? allowTracking,
    UserRole? role,
    String? avatarUrl,
    String? coverUrl,
    String? parentUid,
    String? locale,
    List<String>? managedChildIds,
  }) {
    return UserProfilePatch(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      allowTracking: allowTracking ?? this.allowTracking,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      parentUid: parentUid ?? this.parentUid,
      locale: locale ?? this.locale,
      managedChildIds: managedChildIds ?? this.managedChildIds,
    );
  }
}
