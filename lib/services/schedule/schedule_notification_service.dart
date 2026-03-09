import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/models/memory_day.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';

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

    final child = await _userRepo.getUserById(schedule.childId);
    final childName = _resolveChildName(child?.displayName, schedule.childId);

    debugPrint(
      '[SCHEDULE_NOTIFY] sender=$actorUid receiver=$receiverId child=$childName schedule=${schedule.id}',
    );

    final title = _buildTitle(action);
    final body = _buildBody(
      action: action,
      actorIsParent: actorIsParent,
      childName: childName,
      schedule: schedule,
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

    String resolvedChildName = (childName ?? '').trim();
    if (resolvedChildName.isEmpty) {
      final child = await _userRepo.getUserById(childId);
      resolvedChildName = _resolveChildName(child?.displayName, childId);
    }

    final title = 'Lịch trình mới được thêm';
    final body = actorIsParent
        ? 'Cha vừa thêm $importCount lịch cho $resolvedChildName.'
        : 'Con vừa thêm $importCount lịch.';

    final data = {
      'entity': 'schedule_import',
      'action': 'imported',
      'actorUid': actorUid,
      'actorRole': actorIsParent ? 'parent' : 'child',
      'ownerParentUid': ownerParentUid,
      'childId': childId,
      'childName': resolvedChildName,
      'importCount': importCount.toString(),
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

  Future<void> _sendMemoryDay({
    required String action,
    required String actorUid,
    required String ownerParentUid,
    required MemoryDay memoryDay,
  }) async {
    final actorIsParent = actorUid == ownerParentUid;

    final title = _buildMemoryDayTitle(action);
    final body = _buildMemoryDayBody(
      action: action,
      actorIsParent: actorIsParent,
      memoryDay: memoryDay,
    );

    final data = {
      'entity': 'memory_day',
      'action': action,
      'actorUid': actorUid,
      'actorRole': actorIsParent ? 'parent' : 'child',
      'ownerParentUid': ownerParentUid,
      'memoryDayId': memoryDay.id,
      'memoryDayTitle': memoryDay.title,
      'date': DateFormat('dd/MM/yyyy').format(memoryDay.date),
      'dateIso': memoryDay.date.toIso8601String(),
      'repeatYearly': memoryDay.repeatYearly.toString(),
      'note': (memoryDay.note ?? '').trim(),
    };

    if (actorIsParent) {
      // Parent thao tác -> gửi cho tất cả child của parent
      final children = await _userRepo.getChildrenByParentUid(ownerParentUid);

      for (final child in children) {
      final receiverId = child.id;
      if (receiverId.isEmpty || receiverId == actorUid) continue;

      try {
        await NotificationService.sendUserToUser(
          senderId: actorUid,
          receiverId: receiverId,
          type: NotificationType.memoryDay.value,
          title: title,
          body: body,
          data: {
            ...data,
            'childId': child.id,
            'childName': _resolveChildName(child.name, child.id),
          },
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

    await NotificationService.sendUserToUser(
      senderId: actorUid,
      receiverId: receiverId,
      type: NotificationType.memoryDay.value,
      title: title,
      body: body,
      data: data,
    );
  }

  String _buildMemoryDayTitle(String action) {
    switch (action) {
      case 'created':
        return 'Ngày đáng nhớ mới';
      case 'updated':
        return 'Ngày đáng nhớ đã thay đổi';
      case 'deleted':
        return 'Ngày đáng nhớ đã bị xóa';
      default:
        return 'Ngày đáng nhớ có thay đổi';
    }
  }

  String _buildMemoryDayBody({
    required String action,
    required bool actorIsParent,
    required MemoryDay memoryDay,
  }) {
    final title = memoryDay.title.trim().isEmpty
        ? 'Không có tiêu đề'
        : memoryDay.title.trim();

    if (actorIsParent) {
      switch (action) {
        case 'created':
          return 'Cha đã thêm ngày đáng nhớ "$title".';
        case 'updated':
          return 'Cha đã chỉnh sửa ngày đáng nhớ "$title".';
        case 'deleted':
          return 'Cha đã xóa ngày đáng nhớ "$title".';
        default:
          return 'Cha đã thay đổi ngày đáng nhớ "$title".';
      }
    } else {
      switch (action) {
        case 'created':
          return 'Con đã thêm ngày đáng nhớ "$title".';
        case 'updated':
          return 'Con đã chỉnh sửa ngày đáng nhớ "$title".';
        case 'deleted':
          return 'Con đã xóa ngày đáng nhớ "$title".';
        default:
          return 'Con đã thay đổi ngày đáng nhớ "$title".';
      }
    }
  }

  String _buildTitle(String action) {
    switch (action) {
      case 'created':
        return 'Lịch trình mới';
      case 'updated':
        return 'Lịch trình đã thay đổi';
      case 'deleted':
        return 'Lịch trình đã bị xóa';
      case 'restored':
        return 'Lịch trình đã được khôi phục';
      default:
        return 'Lịch trình có thay đổi';
    }
  }

  String _buildBody({
    required String action,
    required bool actorIsParent,
    required String childName,
    required Schedule schedule,
  }) {
    final title = schedule.title.trim().isEmpty
        ? 'Không có tiêu đề'
        : schedule.title.trim();
    final date = DateFormat('dd/MM/yyyy').format(schedule.date);
    final time = '${_hhmm(schedule.startAt)} - ${_hhmm(schedule.endAt)}';

    if (actorIsParent) {
      switch (action) {
        case 'created':
          return 'Cha đã thêm lịch "$title" cho $childName vào $date, $time.';
        case 'updated':
          return 'Cha đã chỉnh sửa lịch "$title" của $childName.';
        case 'deleted':
          return 'Cha đã xóa lịch "$title" của $childName.';
        case 'restored':
          return 'Cha đã khôi phục một phiên bản cũ của lịch "$title" của $childName.';
        default:
          return 'Cha đã thay đổi lịch "$title" của $childName.';
      }
    } else {
      switch (action) {
        case 'created':
          return '$childName đã thêm lịch "$title" vào $date, $time.';
        case 'updated':
          return '$childName đã chỉnh sửa lịch "$title".';
        case 'deleted':
          return '$childName đã xóa lịch "$title".';
        case 'restored':
          return '$childName đã khôi phục lịch sử sửa của lịch "$title".';
        default:
          return '$childName đã thay đổi lịch "$title".';
      }
    }
  }

  String _resolveChildName(String? name, String fallbackUid) {
    final n = (name ?? '').trim();
    return n.isEmpty ? 'Bé' : n;
  }

  String _hhmm(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}