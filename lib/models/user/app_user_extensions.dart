import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

extension AppUserDisplay on AppUser {
  String get displayLabel {
    if (displayName?.isNotEmpty == true) return displayName!;
    if (email?.isNotEmpty == true) return email!;
    return runtimeL10n().notificationTrackingUnknownValue;
  }

  String get displayEmail {
    if (email?.isNotEmpty == true) return email!;
    return runtimeL10n().notificationTrackingUnknownValue;
  }

  String get initials {
    final name = displayLabel.trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}
