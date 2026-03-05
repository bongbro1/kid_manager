import 'package:kid_manager/models/app_user.dart';

class ChildItem {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;

  ChildItem({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
  });

  factory ChildItem.fromMap(Map<String, dynamic> data, String uid) {
    return ChildItem(
      id: uid,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      isOnline: data['isOnline'] ?? false,
    );
  }

  factory ChildItem.fromUser(AppUser user) {
    return ChildItem(
      id: user.uid,
      name: user.displayName ?? '',
      avatarUrl: user.avatarUrl ?? '',
      isOnline: false,
    );
  }
}
