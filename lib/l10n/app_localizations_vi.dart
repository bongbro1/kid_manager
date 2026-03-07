// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get zone_default => 'Thông báo vùng';

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
}
