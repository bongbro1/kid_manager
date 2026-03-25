import 'package:kid_manager/utils/date_utils.dart';

class UserProfilePatch {
  const UserProfilePatch({
    this.name,
    this.phone,
    this.gender,
    this.dob,
    this.address,
    this.allowTracking,
    this.avatarUrl,
    this.coverUrl,
    this.locale,
  });

  final String? name;
  final String? phone;
  final String? gender;
  final String? dob;
  final String? address;
  final bool? allowTracking;
  final String? avatarUrl;
  final String? coverUrl;
  final String? locale;

  bool get isEmpty =>
      name == null &&
      phone == null &&
      gender == null &&
      dob == null &&
      address == null &&
      allowTracking == null &&
      avatarUrl == null &&
      coverUrl == null &&
      locale == null;

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
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (locale != null) 'locale': locale,
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
    String? avatarUrl,
    String? coverUrl,
    String? locale,
  }) {
    return UserProfilePatch(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      address: address ?? this.address,
      allowTracking: allowTracking ?? this.allowTracking,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      locale: locale ?? this.locale,
    );
  }
}
