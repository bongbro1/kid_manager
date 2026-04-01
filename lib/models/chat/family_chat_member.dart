import 'package:kid_manager/models/user/user_types.dart';

class FamilyChatMember {
  final String uid;
  final UserRole role;
  final String displayName;
  final String avatarUrl;

  const FamilyChatMember({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.avatarUrl,
  });

  String get roleKey => roleToString(role);
}
