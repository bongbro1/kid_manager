// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get zone_default => 'Zone notification';

  @override
  String get zone_enter_danger_parent => '⚠️ Child entered a danger zone';

  @override
  String get zone_exit_danger_parent => '✅ Child left a danger zone';

  @override
  String get zone_enter_safe_parent => '✅ Child entered a safe zone';

  @override
  String get zone_exit_safe_parent => 'ℹ️ Child left a safe zone';

  @override
  String get zone_enter_danger_child => '⚠️ You entered a danger zone';

  @override
  String get zone_exit_danger_child => '✅ You left a danger zone';

  @override
  String get zone_enter_safe_child => '✅ You entered a safe zone';

  @override
  String get zone_exit_safe_child => 'ℹ️ You left a safe zone';
}
