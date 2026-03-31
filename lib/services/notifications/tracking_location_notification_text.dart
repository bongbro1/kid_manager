import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/notifications/tracking_notification_style.dart';
import 'package:kid_manager/services/notifications/zone_i18n.dart';

const Set<String> _locationStatusKeys = {
  'location_service_off',
  'location_permission_denied',
  'background_disabled',
  'location_stale',
  'ok',
};

bool isTrackingLocationStatusNotification({
  required String type,
  required String title,
  required Map<String, dynamic> data,
}) {
  if (type.trim().toLowerCase() != 'tracking') {
    return false;
  }

  final eventCategory = (data['eventCategory'] ?? '').toString().trim().toLowerCase();
  if (eventCategory == 'location_status') {
    return true;
  }

  final status = trackingStatusFromNotificationPayload(title: title, data: data);
  return _locationStatusKeys.contains(status);
}

String resolveTrackingLocationActorName(
  AppLocalizations l10n,
  Map<String, dynamic> data,
) {
  final actorName = (data['actorName'] ?? '').toString().trim();
  if (actorName.isNotEmpty) {
    return actorName;
  }

  final childName = (data['childName'] ??
          data['displayName'] ??
          data['name'] ??
          data['fullName'] ??
          '')
      .toString()
      .trim();
  return childName.isNotEmpty ? childName : l10n.notificationsDefaultChildName;
}

String resolveTrackingLocationStatusTitle(
  AppLocalizations l10n, {
  required String title,
  required Map<String, dynamic> data,
}) {
  final trimmedTitle = title.trim();
  final eventCategory = (data['eventCategory'] ?? '').toString().trim().toLowerCase();
  if (eventCategory == 'location_status' &&
      trimmedTitle.isNotEmpty &&
      !trimmedTitle.startsWith('tracking.')) {
    return trimmedTitle;
  }

  if (trimmedTitle.startsWith('tracking.')) {
    return trackingTitleFromKey(l10n, trimmedTitle);
  }

  final eventKey = (data['eventKey'] ?? '').toString().trim();
  if (eventKey.startsWith('tracking.')) {
    return trackingTitleFromKey(l10n, eventKey);
  }

  return trimmedTitle.isNotEmpty ? trimmedTitle : l10n.tracking_default_title;
}

String resolveTrackingLocationStatusBody(
  AppLocalizations l10n, {
  required String title,
  required String fallbackBody,
  required Map<String, dynamic> data,
}) {
  final actorName = resolveTrackingLocationActorName(l10n, data);
  final eventCategory = (data['eventCategory'] ?? '').toString().trim().toLowerCase();
  final body = fallbackBody.trim();
  if (eventCategory == 'location_status' &&
      body.isNotEmpty &&
      !body.startsWith('tracking.')) {
    return body;
  }

  final eventKey = ((data['eventKey'] ?? '').toString().trim().isNotEmpty
          ? data['eventKey']
          : title)
      .toString()
      .trim();

  if (eventKey.startsWith('tracking.')) {
    return trackingParentBodyFromKey(
      l10n,
      eventKey,
      childName: actorName,
    );
  }

  if (body.isNotEmpty && !body.startsWith('tracking.')) {
    return body;
  }

  return l10n.notificationsTrackingDefaultBody;
}
