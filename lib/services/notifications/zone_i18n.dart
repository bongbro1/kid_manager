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

String trackingTitleFromKey(AppLocalizations l10n, String key) {
  final normalized = _normalizeTrackingKey(key);
  switch (normalized) {
    case 'tracking.location_service_off.parent':
      return l10n.tracking_location_service_off_parent_title;
    case 'tracking.location_permission_denied.parent':
      return l10n.tracking_location_permission_denied_parent_title;
    case 'tracking.background_disabled.parent':
      return l10n.tracking_background_disabled_parent_title;
    case 'tracking.location_stale.parent':
      return l10n.tracking_location_stale_parent_title;
    case 'tracking.ok.parent':
      return l10n.tracking_ok_parent_title;

    case 'tracking.location_service_off.child':
      return l10n.tracking_location_service_off_child_title;
    case 'tracking.location_permission_denied.child':
      return l10n.tracking_location_permission_denied_child_title;
    case 'tracking.background_disabled.child':
      return l10n.tracking_background_disabled_child_title;
    case 'tracking.location_stale.child':
      return l10n.tracking_location_stale_child_title;
    case 'tracking.ok.child':
      return l10n.tracking_ok_child_title;

    default:
      return l10n.tracking_default_title;
  }
}

String trackingParentBodyFromKey(
  AppLocalizations l10n,
  String key, {
  required String childName,
}) {
  final normalized = _normalizeTrackingKey(key);
  switch (normalized) {
    case 'tracking.location_service_off.parent':
      return l10n.tracking_location_service_off_parent_body(childName);
    case 'tracking.location_permission_denied.parent':
      return l10n.tracking_location_permission_denied_parent_body(childName);
    case 'tracking.background_disabled.parent':
      return l10n.tracking_background_disabled_parent_body(childName);
    case 'tracking.location_stale.parent':
      return l10n.tracking_location_stale_parent_body(childName);
    case 'tracking.ok.parent':
      return l10n.tracking_ok_parent_body(childName);
    default:
      return l10n.notificationsTrackingDefaultBody;
  }
}

String _normalizeTrackingKey(String rawKey) {
  final key = rawKey.trim().toLowerCase();
  if (key.endsWith('.title') || key.endsWith('.body')) {
    final cut = key.lastIndexOf('.');
    if (cut > 0) {
      return key.substring(0, cut);
    }
  }
  return key;
}
