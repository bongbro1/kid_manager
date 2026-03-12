import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/memory_day.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/utils/app_localizations_loader.dart';

import '../../models/notifications/app_notification.dart';
import '../../models/schedule.dart';
import '../../repositories/user_repository.dart';

class ScheduleNotificationService {
  final UserRepository _userRepo;

  ScheduleNotificationService(this._userRepo);

  Future<void> notifyCreated({
    required String actorUid,
    required String scheduleOwnerUid,
    required Schedule schedule,
  }) async {
    await _send(
      action: 'created',
      actorUid: actorUid,
      scheduleOwnerUid: scheduleOwnerUid,
      schedule: schedule,
    );
  }

  Future<void> notifyUpdated({
    required String actorUid,
    required String scheduleOwnerUid,
    required Schedule schedule,
  }) async {
    await _send(
      action: 'updated',
      actorUid: actorUid,
      scheduleOwnerUid: scheduleOwnerUid,
      schedule: schedule,
    );
  }

  Future<void> notifyDeleted({
    required String actorUid,
    required String scheduleOwnerUid,
    required Schedule schedule,
  }) async {
    await _send(
      action: 'deleted',
      actorUid: actorUid,
      scheduleOwnerUid: scheduleOwnerUid,
      schedule: schedule,
    );
  }

  Future<void> notifyRestored({
    required String actorUid,
    required String scheduleOwnerUid,
    required Schedule schedule,
  }) async {
    await _send(
      action: 'restored',
      actorUid: actorUid,
      scheduleOwnerUid: scheduleOwnerUid,
      schedule: schedule,
    );
  }

  Future<void> _send({
    required String action,
    required String actorUid,
    required String scheduleOwnerUid,
    required Schedule schedule,
  }) async {
    final actorIsParent = actorUid == scheduleOwnerUid;
    final receiverId = actorIsParent ? schedule.childId : scheduleOwnerUid;

    if (receiverId.isEmpty) {
      debugPrint('[SCHEDULE_NOTIFY] skip: empty receiver');
      return;
    }

    if (receiverId == actorUid) {
      debugPrint('[SCHEDULE_NOTIFY] skip self notification');
      return;
    }

    final l10n = await _loadL10nForUser(receiverId);
    final child = await _userRepo.getUserById(schedule.childId);
    final childName = _resolveChildName(child?.displayName, l10n);

    debugPrint(
      '[SCHEDULE_NOTIFY] sender=$actorUid receiver=$receiverId child=$childName schedule=${schedule.id}',
    );

    final title = _buildTitle(action, l10n);
    final body = _buildBody(
      action: action,
      actorIsParent: actorIsParent,
      childName: childName,
      schedule: schedule,
      l10n: l10n,
    );

    final data = {
      'entity': 'schedule',
      'action': action,
      'scheduleId': schedule.id,
      'childId': schedule.childId,
      'childName': childName,
      'ownerParentUid': scheduleOwnerUid,
      'actorUid': actorUid,
      'actorRole': actorIsParent ? 'parent' : 'child',
      'scheduleTitle': schedule.title,
      'date': DateFormat('dd/MM/yyyy').format(schedule.date),
      'startAt': _hhmm(schedule.startAt),
      'endAt': _hhmm(schedule.endAt),
      'dateIso': schedule.date.toIso8601String(),
      'startAtIso': schedule.startAt.toIso8601String(),
      'endAtIso': schedule.endAt.toIso8601String(),
    };

    await NotificationService.sendUserToUser(
      senderId: actorUid,
      receiverId: receiverId,
      type: NotificationType.schedule.value,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> notifyMemoryDayCreated({
    required String actorUid,
    required String ownerParentUid,
    required MemoryDay memoryDay,
  }) async {
    await _sendMemoryDay(
      action: 'created',
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
      memoryDay: memoryDay,
    );
  }

  Future<void> notifyMemoryDayUpdated({
    required String actorUid,
    required String ownerParentUid,
    required MemoryDay memoryDay,
  }) async {
    await _sendMemoryDay(
      action: 'updated',
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
      memoryDay: memoryDay,
    );
  }

  Future<void> notifyMemoryDayDeleted({
    required String actorUid,
    required String ownerParentUid,
    required MemoryDay memoryDay,
  }) async {
    await _sendMemoryDay(
      action: 'deleted',
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
      memoryDay: memoryDay,
    );
  }

  Future<void> notifyScheduleImported({
    required String actorUid,
    required String ownerParentUid,
    required String childId,
    required int importCount,
    String? childName,
  }) async {
    final actorIsParent = actorUid == ownerParentUid;
    final receiverId = actorIsParent ? childId : ownerParentUid;

    if (receiverId.isEmpty) {
      debugPrint('[SCHEDULE_IMPORT_NOTIFY] skip: empty receiver');
      return;
    }

    if (receiverId == actorUid) {
      debugPrint('[SCHEDULE_IMPORT_NOTIFY] skip self notification');
      return;
    }

    final l10n = await _loadL10nForUser(receiverId);
    final actorChildName = await _resolveActorChildName(
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
      l10n: l10n,
    );

    String resolvedChildName = (childName ?? '').trim();
    if (resolvedChildName.isEmpty) {
      final child = await _userRepo.getUserById(childId);
      resolvedChildName = _resolveChildName(child?.displayName, l10n);
    }

    final title = l10n.scheduleImportNotifyTitle;
    final body = actorIsParent
        ? l10n.scheduleImportNotifyBodyParent(importCount, resolvedChildName)
        : l10n.scheduleImportNotifyBodyChild(actorChildName, importCount);

    final data = {
      'entity': 'schedule_import',
      'action': 'imported',
      'actorUid': actorUid,
      'actorRole': actorIsParent ? 'parent' : 'child',
      'ownerParentUid': ownerParentUid,
      'childId': childId,
      'childName': resolvedChildName,
      'actorChildName': actorIsParent ? '' : actorChildName,
      'importCount': importCount.toString(),
    };

    await NotificationService.sendUserToUser(
      senderId: actorUid,
      receiverId: receiverId,
      type: NotificationType.importExcel.value,
      title: title,
      body: body,
      data: data,
    );
  }

  Future<void> _sendMemoryDay({
    required String action,
    required String actorUid,
    required String ownerParentUid,
    required MemoryDay memoryDay,
  }) async {
    final actorIsParent = actorUid == ownerParentUid;

    if (actorIsParent) {
      final children = await _userRepo.getChildrenByParentUid(ownerParentUid);

      for (final child in children) {
        final receiverId = child.id;
        if (receiverId.isEmpty || receiverId == actorUid) continue;

        final l10n = await _loadL10nForUser(receiverId);
        final title = _buildMemoryDayTitle(action, l10n);
        final body = _buildMemoryDayBody(
          action: action,
          actorIsParent: true,
          actorChildName: l10n.notificationsActorParent,
          memoryDay: memoryDay,
          l10n: l10n,
        );

        final data = {
          'entity': 'memory_day',
          'action': action,
          'actorUid': actorUid,
          'actorRole': 'parent',
          'ownerParentUid': ownerParentUid,
          'memoryDayId': memoryDay.id,
          'memoryDayTitle': memoryDay.title,
          'date': DateFormat('dd/MM/yyyy').format(memoryDay.date),
          'dateIso': memoryDay.date.toIso8601String(),
          'repeatYearly': memoryDay.repeatYearly.toString(),
          'note': (memoryDay.note ?? '').trim(),
          'childId': child.id,
          'childName': _resolveChildName(child.name, l10n),
        };

        try {
          await NotificationService.sendUserToUser(
            senderId: actorUid,
            receiverId: receiverId,
            type: NotificationType.memoryDay.value,
            title: title,
            body: body,
            data: data,
          );
        } catch (e) {
          debugPrint(
            '[MEMORY_DAY_NOTIFY] failed send to child=$receiverId action=$action error=$e',
          );
        }
      }
      return;
    }

    // Child thao tác -> parent nhận
    final receiverId = ownerParentUid;

    if (receiverId.isEmpty) {
      debugPrint('[MEMORY_DAY_NOTIFY] skip: empty receiver');
      return;
    }

    if (receiverId == actorUid) {
      debugPrint('[MEMORY_DAY_NOTIFY] skip self notification');
      return;
    }

    final l10n = await _loadL10nForUser(receiverId);
    final actorChildName = await _resolveActorChildName(
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
      l10n: l10n,
    );

    final title = _buildMemoryDayTitle(action, l10n);
    final body = _buildMemoryDayBody(
      action: action,
      actorIsParent: false,
      actorChildName: actorChildName,
      memoryDay: memoryDay,
      l10n: l10n,
    );

    final data = {
      'entity': 'memory_day',
      'action': action,
      'actorUid': actorUid,
      'actorRole': 'child',
      'ownerParentUid': ownerParentUid,
      'memoryDayId': memoryDay.id,
      'memoryDayTitle': memoryDay.title,
      'date': DateFormat('dd/MM/yyyy').format(memoryDay.date),
      'dateIso': memoryDay.date.toIso8601String(),
      'repeatYearly': memoryDay.repeatYearly.toString(),
      'note': (memoryDay.note ?? '').trim(),
      'childName': actorChildName,
    };

    await NotificationService.sendUserToUser(
      senderId: actorUid,
      receiverId: receiverId,
      type: NotificationType.memoryDay.value,
      title: title,
      body: body,
      data: data,
    );
  }

  String _buildMemoryDayTitle(String action, AppLocalizations l10n) {
    switch (action) {
      case 'created':
        return l10n.memoryDayNotifyTitleCreated;
      case 'updated':
        return l10n.memoryDayNotifyTitleUpdated;
      case 'deleted':
        return l10n.memoryDayNotifyTitleDeleted;
      default:
        return l10n.memoryDayNotifyTitleChanged;
    }
  }

  String _buildMemoryDayBody({
    required String action,
    required bool actorIsParent,
    required String actorChildName,
    required MemoryDay memoryDay,
    required AppLocalizations l10n,
  }) {
    final title = memoryDay.title.trim().isEmpty
        ? l10n.notificationsNoTitle
        : memoryDay.title.trim();

    if (actorIsParent) {
      switch (action) {
        case 'created':
          return l10n.memoryDayNotifyBodyParentCreated(title);
        case 'updated':
          return l10n.memoryDayNotifyBodyParentUpdated(title);
        case 'deleted':
          return l10n.memoryDayNotifyBodyParentDeleted(title);
        default:
          return l10n.memoryDayNotifyBodyParentChanged(title);
      }
    }

    switch (action) {
      case 'created':
        return l10n.memoryDayNotifyBodyChildCreated(actorChildName, title);
      case 'updated':
        return l10n.memoryDayNotifyBodyChildUpdated(actorChildName, title);
      case 'deleted':
        return l10n.memoryDayNotifyBodyChildDeleted(actorChildName, title);
      default:
        return l10n.memoryDayNotifyBodyChildChanged(actorChildName, title);
    }
  }

  String _buildTitle(String action, AppLocalizations l10n) {
    switch (action) {
      case 'created':
        return l10n.scheduleNotifyTitleCreated;
      case 'updated':
        return l10n.scheduleNotifyTitleUpdated;
      case 'deleted':
        return l10n.scheduleNotifyTitleDeleted;
      case 'restored':
        return l10n.scheduleNotifyTitleRestored;
      default:
        return l10n.scheduleNotifyTitleChanged;
    }
  }

  String _buildBody({
    required String action,
    required bool actorIsParent,
    required String childName,
    required Schedule schedule,
    required AppLocalizations l10n,
  }) {
    final title = schedule.title.trim().isEmpty
        ? l10n.notificationsNoTitle
        : schedule.title.trim();
    final date = DateFormat('dd/MM/yyyy').format(schedule.date);
    final time = '${_hhmm(schedule.startAt)} - ${_hhmm(schedule.endAt)}';

    if (actorIsParent) {
      switch (action) {
        case 'created':
          return l10n.scheduleNotifyBodyParentCreated(title, childName, date, time);
        case 'updated':
          return l10n.scheduleNotifyBodyParentUpdated(title, childName);
        case 'deleted':
          return l10n.scheduleNotifyBodyParentDeleted(title, childName);
        case 'restored':
          return l10n.scheduleNotifyBodyParentRestored(title, childName);
        default:
          return l10n.scheduleNotifyBodyParentChanged(title, childName);
      }
    }

    switch (action) {
      case 'created':
        return l10n.scheduleNotifyBodyChildCreated(childName, title, date, time);
      case 'updated':
        return l10n.scheduleNotifyBodyChildUpdated(childName, title);
      case 'deleted':
        return l10n.scheduleNotifyBodyChildDeleted(childName, title);
      case 'restored':
        return l10n.scheduleNotifyBodyChildRestored(childName, title);
      default:
        return l10n.scheduleNotifyBodyChildChanged(childName, title);
    }
  }

  String _resolveChildName(String? name, AppLocalizations l10n) {
    final n = (name ?? '').trim();
    return n.isEmpty ? l10n.notificationsDefaultChildName : n;
  }

  Future<String> _resolveActorChildName({
    required String actorUid,
    required String ownerParentUid,
    required AppLocalizations l10n,
  }) async {
    if (actorUid == ownerParentUid) return l10n.notificationsActorParent;

    final child = await _userRepo.getUserById(actorUid);
    return _resolveChildName(child?.displayName, l10n);
  }

  Future<AppLocalizations> _loadL10nForUser(String uid) {
    return AppLocalizationsLoader.loadForUser(
      userRepository: _userRepo,
      uid: uid,
    );
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
