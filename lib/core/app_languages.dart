class AppLanguages {
  static const languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
  ];

  static Map<String, String> getLanguage(String code) {
    return languages.firstWhere(
      (e) => e['code'] == code,
      orElse: () => languages.first,
    );
  }

  static String getName(String code) {
    final lang = languages.firstWhere(
      (e) => e['code'] == code,
      orElse: () => languages.first,
    );
    return lang['name']!;
  }
}
