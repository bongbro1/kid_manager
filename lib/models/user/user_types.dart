enum UserRole { parent, child, guardian }

UserRole roleFromString(String v) {
  switch (v) {
    case 'child':
      return UserRole.child;
    case 'guardian':
      return UserRole.guardian;
    default:
      return UserRole.parent;
  }
}

String roleToString(UserRole r) {
  switch (r) {
    case UserRole.child:
      return 'child';
    case UserRole.guardian:
      return 'guardian';
    case UserRole.parent:
      return 'parent';
  }
}

extension UserRoleText on UserRole {
  String get text {
    switch (this) {
      case UserRole.parent:
        return "Phụ huynh";
      case UserRole.child:
        return "Con";
      case UserRole.guardian:
        return "Người giám hộ";
    }
  }
}

enum UserPhotoType { avatar, cover }