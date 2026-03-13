import 'dart:ui';

import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/repositories/user_repository.dart';

class AppLocalizationsLoader {
  AppLocalizationsLoader._();

  static Future<AppLocalizations> loadForUser({
    required UserRepository userRepository,
    required String? uid,
    String fallbackLang = 'vi',
  }) async {
    final fallback = fallbackLang.toLowerCase() == 'en' ? 'en' : 'vi';

    if (uid != null && uid.isNotEmpty) {
      try {
        final user = await userRepository.getUserById(uid);
        final lang = (user?.locale ?? fallback).toLowerCase();
        final locale = Locale(lang == 'en' ? 'en' : 'vi');
        return AppLocalizations.delegate.load(locale);
      } catch (_) {}
    }

    return AppLocalizations.delegate.load(Locale(fallback));
  }
}
