import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:kid_manager/l10n/app_localizations.dart';

AppLocalizations runtimeL10n([String? lang]) {
  final normalized =
      (lang ?? PlatformDispatcher.instance.locale.languageCode).toLowerCase();
  return lookupAppLocalizations(
    Locale(normalized.startsWith('en') ? 'en' : 'vi'),
  );
}
