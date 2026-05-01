class AppLanguages {
  static const languages = [
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
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
