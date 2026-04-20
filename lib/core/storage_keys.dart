class StorageKeys {
  static const uid = 'uid';
  static const role = 'role';
  static const email = 'email';
  static const parentId = 'parentId';
  static const managedChildIds = 'managedChildIds';
  static const displayName = 'displayName';
  static const isLoggedIn = 'is_logged_in';
  static const locale = 'locale';
  static const login_preference = 'login_preference';
  static const pendingOtp = 'pendingOtp';

  static const themeColor = 'theme_color';
  static const isDarkMode = 'is_dark_mode';
  static const language = 'language';
  static const permissionOnboardingSeenV1 = 'permission_onboarding_seen_v1';
  static const childSupervisionSetupSeenV1 = 'child_supervision_setup_seen_v1';
  static const flashSeenV1 = 'flash_seen_v1';

  static String appRemovedNotified(String childId, String packageName) {
    return "removed_notified_${childId}_$packageName";
  }
}
