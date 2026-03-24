import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/utils/date_utils.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.address,
    required this.allowTracking,
    required this.role,
    this.avatarUrl,
    this.coverUrl,
    this.parentUid,
    this.locale,
    this.managedChildIds = const <String>[],
  });

  final String id;
  final String name;
  final String phone;
  final String gender;
  final String dob;
  final String address;
  final bool allowTracking;
  final UserRole role;
  final String? parentUid;
  final String? avatarUrl;
  final String? coverUrl;
  final String? locale;
  final List<String> managedChildIds;

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;
  bool get isGuardian => role == UserRole.guardian;
  bool get isAdultManager => role.isAdultManager;
  String get roleKey => roleToString(role);

  Map<String, dynamic> toMap() {
    final parsedDob = parseFlexibleBirthDate(dob);
    final data = <String, dynamic>{
      'displayName': name,
      'phone': phone,
      'gender': gender,
      if (parsedDob != null)
        ...buildBirthdayStorageFields(parsedDob)
      else
        'dob': dob,
      'address': address,
      'allowTracking': allowTracking,
      'role': roleKey,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
      'parentUid': parentUid,
      'locale': locale,
      if (managedChildIds.isNotEmpty) 'managedChildIds': managedChildIds,
    };

    data.removeWhere((key, value) => value == null);
    return data;
  }

  UserProfile copyWith({
    String? id,
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
    return UserProfile(
      id: id ?? this.id,
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
      locale: locale ?? this.locale ?? 'vi',
      managedChildIds: managedChildIds ?? this.managedChildIds,
    );
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    final role = UserRole.fromValue(data['role']);
    final date =
        parseFlexibleBirthDate(data['dob']) ??
        parseFlexibleBirthDate(data['dobIso']);
    final dobStr = date != null
        ? formatDateDDMMYYYY(date)
        : (data['dobIso']?.toString().trim() ??
              data['dob']?.toString().trim() ??
              '');

    return UserProfile(
      id: id,
      name: (data['displayName'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      gender: (data['gender'] ?? '').toString(),
      dob: dobStr,
      address: (data['address'] ?? '').toString(),
      allowTracking: _readAllowTracking(data, role: role),
      role: role,
      avatarUrl: data['avatarUrl']?.toString(),
      coverUrl: data['coverUrl']?.toString(),
      parentUid: data['parentUid']?.toString(),
      locale: data['locale']?.toString() ?? 'vi',
      managedChildIds: _readManagedChildIds(data),
    );
  }

  static List<String> _readManagedChildIds(Map<String, dynamic> data) {
    final raw =
        data['managedChildIds'] ?? data['assignedChildIds'] ?? data['childIds'];
    if (raw is! Iterable) {
      return const <String>[];
    }

    final values = raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return values;
  }

  static bool _readAllowTracking(
    Map<String, dynamic> data, {
    required UserRole role,
  }) {
    final raw = data['allowTracking'];
    if (raw is bool) {
      return raw;
    }
    if (role == UserRole.child) {
      return true;
    }
    return false;
  }
}
