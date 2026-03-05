
import 'package:kid_manager/l10n/app_localizations.dart';

String zoneTitleFromKey(AppLocalizations l10n, String key) {
  switch (key) {
    case 'zone.enter.danger.parent':
      return l10n.zone_enter_danger_parent;
    case 'zone.exit.danger.parent':
      return l10n.zone_exit_danger_parent;
    case 'zone.enter.safe.parent':
      return l10n.zone_enter_safe_parent;
    case 'zone.exit.safe.parent':
      return l10n.zone_exit_safe_parent;

    case 'zone.enter.danger.child':
      return l10n.zone_enter_danger_child;
    case 'zone.exit.danger.child':
      return l10n.zone_exit_danger_child;
    case 'zone.enter.safe.child':
      return l10n.zone_enter_safe_child;
    case 'zone.exit.safe.child':
      return l10n.zone_exit_safe_child;

    default:
      return l10n.zone_default;
  }
}