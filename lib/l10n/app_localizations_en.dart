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

  @override
  String get tracking_location_service_off_parent_title =>
      'Child turned off location';

  @override
  String get tracking_location_permission_denied_parent_title =>
      'Child turned off location permission';

  @override
  String get tracking_background_disabled_parent_title =>
      'Background location was turned off';

  @override
  String get tracking_location_stale_parent_title =>
      'No recent location update';

  @override
  String get tracking_ok_parent_title => 'Location is active again';

  @override
  String get tracking_location_service_off_child_title =>
      'Location is turned off';

  @override
  String get tracking_location_permission_denied_child_title =>
      'Location permission is off';

  @override
  String get tracking_background_disabled_child_title =>
      'Background location is off';

  @override
  String get tracking_location_stale_child_title => 'Location is not updating';

  @override
  String get tracking_ok_child_title => 'Location is working again';

  @override
  String get tracking_default_title => 'Tracking notification';
}
