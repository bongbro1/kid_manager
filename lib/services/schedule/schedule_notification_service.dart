import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
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
          return 'Ba/Mẹ đã thêm lịch "$title" cho $childName vào $date, $time.';
        case 'updated':
          return 'Ba/Mẹ đã chỉnh sửa lịch "$title" của $childName.';
        case 'deleted':
          return 'Ba/Mẹ đã xóa lịch "$title" của $childName.';
        case 'restored':
          return 'Ba/Mẹ đã khôi phục một phiên bản cũ của lịch "$title" của $childName.';
        default:
          return 'Ba/Mẹ đã thay đổi lịch "$title" của $childName.';
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
          return '$childName đã khôi phục một phiên bản cũ của lịch "$title".';
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