enum UserRole {
  parent('parent'),
  child('child'),
  guardian('guardian');

  const UserRole(this.wireValue);

  final String wireValue;

  bool get isAdultManager =>
      this == UserRole.parent || this == UserRole.guardian;

  static UserRole fromValue(
    Object? value, {
    UserRole fallback = UserRole.child,
  }) {
    if (value is UserRole) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();
    for (final role in UserRole.values) {
      if (role.wireValue == normalized) {
        return role;
      }
    }
    return fallback;
  }
}

UserRole roleFromString(String? value, {UserRole fallback = UserRole.child}) {
  return UserRole.fromValue(value, fallback: fallback);
}

UserRole? tryParseUserRole(Object? value) {
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  for (final role in UserRole.values) {
    if (role.wireValue == normalized) {
      return role;
    }
  }
  return null;
}

String roleToString(UserRole role) => role.wireValue;

extension UserRoleText on UserRole {
  String get text {
    switch (this) {
      case UserRole.parent:
        return 'Phụ huynh';
      case UserRole.child:
        return 'Con';
      case UserRole.guardian:
        return 'Người giám hộ';
    }
  }
}

enum UserPhotoType { avatar, cover }
