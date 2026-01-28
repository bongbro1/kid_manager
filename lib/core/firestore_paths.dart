class FirestorePaths {
  static const users = 'users';
  static const children = 'children';

  static String child(String id) => '$children/$id';
}
