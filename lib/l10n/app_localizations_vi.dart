// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get zone_default => 'Thông báo hehehe';

  @override
  String get zone_enter_danger_parent => '⚠️ Bé vào vùng nguy hiểm';

  @override
  String get zone_exit_danger_parent => '✅ Bé rời vùng nguy hiểm';

  @override
  String get zone_enter_safe_parent => '✅ Bé vào vùng an toàn';

  @override
  String get zone_exit_safe_parent => 'ℹ️ Bé rời vùng an toàn';

  @override
  String get zone_enter_danger_child => '⚠️ Bạn đang vào vùng nguy hiểm';

  @override
  String get zone_exit_danger_child => '✅ Bạn đã ra khỏi vùng nguy hiểm';

  @override
  String get zone_enter_safe_child => '✅ Bạn đang vào vùng an toàn';

  @override
  String get zone_exit_safe_child => 'ℹ️ Bạn đã ra khỏi vùng an toàn';

  @override
  String get tracking_location_service_off_parent_title => 'Con đã tắt định vị';

  @override
  String get tracking_location_permission_denied_parent_title =>
      'Con đã tắt quyền vị trí';

  @override
  String get tracking_background_disabled_parent_title =>
      'Định vị nền đã bị tắt';

  @override
  String get tracking_location_stale_parent_title =>
      'Không nhận được vị trí mới';

  @override
  String get tracking_ok_parent_title => 'Định vị đã hoạt động lại';

  @override
  String get tracking_location_service_off_child_title => 'Định vị đang tắt';

  @override
  String get tracking_location_permission_denied_child_title =>
      'Quyền vị trí đang tắt';

  @override
  String get tracking_background_disabled_child_title => 'Định vị nền đang tắt';

  @override
  String get tracking_location_stale_child_title => 'Vị trí chưa được cập nhật';

  @override
  String get tracking_ok_child_title => 'Định vị đã hoạt động lại';

  @override
  String get tracking_default_title => 'Thông báo định vị';
}
