import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';

String resolveNotificationTitle({
  required AppLocalizations l10n,
  required NotificationType type,
  required Map<String, dynamic> data,
  String fallbackTitle = '',
}) {
  switch (type) {
    case NotificationType.schedule:
      final action = _read(data, 'action').toLowerCase();
      final childName = _childName(l10n, data);
      switch (action) {
        case 'created':
          return l10n.notificationScheduleCreatedTitle(childName);
        case 'updated':
          return l10n.notificationScheduleUpdatedTitle(childName);
        case 'deleted':
          return l10n.notificationScheduleDeletedTitle(childName);
        case 'restored':
          return l10n.notificationScheduleRestoredTitle(childName);
        default:
          return fallbackTitle.trim();
      }
    case NotificationType.memoryDay:
      final action = _read(data, 'action').toLowerCase();
      switch (action) {
        case 'created':
          return l10n.memoryDayNotifyTitleCreated;
        case 'updated':
          return l10n.memoryDayNotifyTitleUpdated;
        case 'deleted':
          return l10n.memoryDayNotifyTitleDeleted;
        case 'changed':
          return l10n.memoryDayNotifyTitleChanged;
        default:
          return fallbackTitle.trim();
      }
    case NotificationType.importExcel:
      return l10n.scheduleImportNotifyTitle;
    case NotificationType.birthday:
      return _birthdayTitle(l10n: l10n, data: data, fallbackTitle: fallbackTitle);
    default:
      return fallbackTitle.trim();
  }
}

String resolveNotificationBody({
  required AppLocalizations l10n,
  required NotificationType type,
  required Map<String, dynamic> data,
  String fallbackBody = '',
}) {
  switch (type) {
    case NotificationType.schedule:
      return _scheduleBody(l10n: l10n, data: data, fallbackBody: fallbackBody);
    case NotificationType.memoryDay:
      return _memoryDayBody(l10n: l10n, data: data, fallbackBody: fallbackBody);
    case NotificationType.importExcel:
      return _scheduleImportBody(
        l10n: l10n,
        data: data,
        fallbackBody: fallbackBody,
      );
    case NotificationType.birthday:
      return _birthdayBody(l10n: l10n, data: data, fallbackBody: fallbackBody);
    default:
      return fallbackBody;
  }
}

String _birthdayTitle({
  required AppLocalizations l10n,
  required Map<String, dynamic> data,
  required String fallbackTitle,
}) {
  final isCountdown = _read(data, 'birthdayPhase').toLowerCase() == 'countdown';
  if (!isCountdown) return fallbackTitle.trim();

  final isSelf = _read(data, 'isSelf').toLowerCase() == 'true';
  return isSelf ? l10n.birthdayCountdownSelfTitle : l10n.birthdayCountdownTitle;
}

String _birthdayBody({
  required AppLocalizations l10n,
  required Map<String, dynamic> data,
  required String fallbackBody,
}) {
  final isCountdown = _read(data, 'birthdayPhase').toLowerCase() == 'countdown';
  if (!isCountdown) return fallbackBody;

  final isSelf = _read(data, 'isSelf').toLowerCase() == 'true';
  final name = _read(data, 'birthdayName').isEmpty
      ? l10n.birthdayMemberFallback
      : _read(data, 'birthdayName');
  final daysUntil = int.tryParse(_read(data, 'daysUntil')) ?? 0;

  if (isSelf) {
    return daysUntil == 1
        ? l10n.birthdayCountdownSelfBodyTomorrow
        : l10n.birthdayCountdownSelfBody(daysUntil);
  }

  return daysUntil == 1
      ? l10n.birthdayCountdownOtherBodyTomorrow(name)
      : l10n.birthdayCountdownOtherBody(name, daysUntil);
}

String _scheduleBody({
  required AppLocalizations l10n,
  required Map<String, dynamic> data,
  required String fallbackBody,
}) {
  final action = _read(data, 'action').toLowerCase();
  final actorRole = _read(data, 'actorRole').toLowerCase();
  final childName = _childName(l10n, data);
  final title = _titleOrFallback(l10n, _read(data, 'scheduleTitle'));
  final date = _read(data, 'date');
  final startAt = _read(data, 'startAt');
  final endAt = _read(data, 'endAt');
  final time = startAt.isEmpty || endAt.isEmpty ? '' : '$startAt - $endAt';

  if (actorRole == 'parent') {
    switch (action) {
      case 'created':
        return _hasDateAndTime(date, time)
            ? l10n.scheduleNotifyBodyParentCreated(title, childName, date, time)
            : fallbackBody;
      case 'updated':
        return l10n.scheduleNotifyBodyParentUpdated(title, childName);
      case 'deleted':
        return l10n.scheduleNotifyBodyParentDeleted(title, childName);
      case 'restored':
        return l10n.scheduleNotifyBodyParentRestored(title, childName);
      case 'changed':
        return l10n.scheduleNotifyBodyParentChanged(title, childName);
      default:
        return fallbackBody;
    }
  }

  switch (action) {
    case 'created':
      return _hasDateAndTime(date, time)
          ? l10n.scheduleNotifyBodyChildCreated(childName, title, date, time)
          : fallbackBody;
    case 'updated':
      return l10n.scheduleNotifyBodyChildUpdated(childName, title);
    case 'deleted':
      return l10n.scheduleNotifyBodyChildDeleted(childName, title);
    case 'restored':
      return l10n.scheduleNotifyBodyChildRestored(childName, title);
    case 'changed':
      return l10n.scheduleNotifyBodyChildChanged(childName, title);
    default:
      return fallbackBody;
  }
}

String _memoryDayBody({
  required AppLocalizations l10n,
  required Map<String, dynamic> data,
  required String fallbackBody,
}) {
  final action = _read(data, 'action').toLowerCase();
  final actorRole = _read(data, 'actorRole').toLowerCase();
  final title = _titleOrFallback(l10n, _read(data, 'memoryDayTitle'));
  final actorChildName = _read(data, 'childName').trim().isEmpty
      ? l10n.notificationsActorChild
      : _read(data, 'childName');

  if (actorRole == 'parent') {
    switch (action) {
      case 'created':
        return l10n.memoryDayNotifyBodyParentCreated(title);
      case 'updated':
        return l10n.memoryDayNotifyBodyParentUpdated(title);
      case 'deleted':
        return l10n.memoryDayNotifyBodyParentDeleted(title);
      case 'changed':
        return l10n.memoryDayNotifyBodyParentChanged(title);
      default:
        return fallbackBody;
    }
  }

  switch (action) {
    case 'created':
      return l10n.memoryDayNotifyBodyChildCreated(actorChildName, title);
    case 'updated':
      return l10n.memoryDayNotifyBodyChildUpdated(actorChildName, title);
    case 'deleted':
      return l10n.memoryDayNotifyBodyChildDeleted(actorChildName, title);
    case 'changed':
      return l10n.memoryDayNotifyBodyChildChanged(actorChildName, title);
    default:
      return fallbackBody;
  }
}

String _scheduleImportBody({
  required AppLocalizations l10n,
  required Map<String, dynamic> data,
  required String fallbackBody,
}) {
  final actorRole = _read(data, 'actorRole').toLowerCase();
  final childName = _childName(l10n, data);
  final actorChildName = _read(data, 'actorChildName').trim().isEmpty
      ? l10n.notificationsActorChild
      : _read(data, 'actorChildName');
  final importCount = int.tryParse(_read(data, 'importCount')) ?? 0;

  if (actorRole == 'parent') {
    return l10n.scheduleImportNotifyBodyParent(importCount, childName);
  }

  if (actorRole == 'child') {
    return l10n.scheduleImportNotifyBodyChild(actorChildName, importCount);
  }

  return fallbackBody;
}

String _childName(AppLocalizations l10n, Map<String, dynamic> data) {
  final childName = _read(data, 'childName');
  return childName.isEmpty ? l10n.notificationsDefaultChildName : childName;
}

String _titleOrFallback(AppLocalizations l10n, String title) {
  return title.trim().isEmpty ? l10n.notificationsNoTitle : title.trim();
}

bool _hasDateAndTime(String date, String time) =>
    date.trim().isNotEmpty && time.trim().isNotEmpty;

String _read(Map<String, dynamic> data, String key) =>
    (data[key] ?? '').toString().trim();
