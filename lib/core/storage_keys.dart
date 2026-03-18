class StorageKeys {
  static const uid = 'uid';
  static const role = 'role';
  static const email = 'email';
  static const parentId = 'parentId';
  static const displayName = 'displayName';
  static const isLoggedIn = 'is_logged_in';
  static const locale = 'locale';
  static const login_preference = 'login_preference';

  static const themeColor = 'theme_color';
  static const isDarkMode = 'is_dark_mode';
  static const language = 'language';

  static String appRemovedNotified(String childId, String packageName) {
    return "removed_notified_${childId}_$packageName";
  }
}
