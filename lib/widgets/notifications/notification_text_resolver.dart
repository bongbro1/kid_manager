import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/user/user_types.dart';

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
        case 'reminder':
          return l10n.memoryDayNotifyTitleReminder;
        default:
          return fallbackTitle.trim();
      }
    case NotificationType.importExcel:
      return l10n.scheduleImportNotifyTitle;
    case NotificationType.birthday:
      return _birthdayTitle(
        l10n: l10n,
        data: data,
        fallbackTitle: fallbackTitle,
      );
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
  final actorRole = tryParseUserRole(data['actorRole']);
  final childName = _childName(l10n, data);
  final actorDisplayName = _actorDisplayName(l10n, data);
  final title = _titleOrFallback(l10n, _read(data, 'scheduleTitle'));
  final date = _read(data, 'date');
  final startAt = _read(data, 'startAt');
  final endAt = _read(data, 'endAt');
  final time = startAt.isEmpty || endAt.isEmpty ? '' : '$startAt - $endAt';

  if (actorRole?.isAdultManager == true) {
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
          ? l10n.scheduleNotifyBodyChildCreated(
              actorDisplayName,
              title,
              date,
              time,
            )
          : fallbackBody;
    case 'updated':
      return l10n.scheduleNotifyBodyChildUpdated(actorDisplayName, title);
    case 'deleted':
      return l10n.scheduleNotifyBodyChildDeleted(actorDisplayName, title);
    case 'restored':
      return l10n.scheduleNotifyBodyChildRestored(actorDisplayName, title);
    case 'changed':
      return l10n.scheduleNotifyBodyChildChanged(actorDisplayName, title);
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
  final actorRole = tryParseUserRole(data['actorRole']);
  final title = _titleOrFallback(l10n, _read(data, 'memoryDayTitle'));
  final date = _read(data, 'date');
  final daysUntil = int.tryParse(_read(data, 'daysUntil')) ?? 0;
  final actorDisplayName = _actorDisplayName(l10n, data);

  if (action == 'reminder') {
    if (date.isEmpty) return fallbackBody;
    return daysUntil <= 1
        ? l10n.memoryDayNotifyBodyReminderTomorrow(title, date)
        : l10n.memoryDayNotifyBodyReminderInDays(title, daysUntil, date);
  }

  if (actorRole?.isAdultManager == true) {
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
      return l10n.memoryDayNotifyBodyChildCreated(actorDisplayName, title);
    case 'updated':
      return l10n.memoryDayNotifyBodyChildUpdated(actorDisplayName, title);
    case 'deleted':
      return l10n.memoryDayNotifyBodyChildDeleted(actorDisplayName, title);
    case 'changed':
      return l10n.memoryDayNotifyBodyChildChanged(actorDisplayName, title);
    default:
      return fallbackBody;
  }
}

String _scheduleImportBody({
  required AppLocalizations l10n,
  required Map<String, dynamic> data,
  required String fallbackBody,
}) {
  final actorRole = tryParseUserRole(data['actorRole']);
  final childName = _childName(l10n, data);
  final actorDisplayName = _actorDisplayName(l10n, data);
  final importCount = int.tryParse(_read(data, 'importCount')) ?? 0;

  if (actorRole?.isAdultManager == true) {
    return l10n.scheduleImportNotifyBodyParent(importCount, childName);
  }

  if (actorRole == UserRole.child || actorRole == UserRole.guardian) {
    return l10n.scheduleImportNotifyBodyChild(actorDisplayName, importCount);
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

String _actorDisplayName(AppLocalizations l10n, Map<String, dynamic> data) {
  final actorRole = tryParseUserRole(data['actorRole']);
  final actorDisplayName = _read(data, 'actorDisplayName');
  final legacyActorName = _read(data, 'actorChildName');

  if (actorDisplayName.isNotEmpty) return actorDisplayName;
  if (legacyActorName.isNotEmpty) return legacyActorName;
  if (actorRole?.isAdultManager == true) return l10n.notificationsActorParent;
  if (actorRole == UserRole.guardian) return l10n.notificationsActorParent;
  return l10n.notificationsActorChild;
}

bool _hasDateAndTime(String date, String time) =>
    date.trim().isNotEmpty && time.trim().isNotEmpty;

String _read(Map<String, dynamic> data, String key) =>
    (data[key] ?? '').toString().trim();
