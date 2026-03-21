import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/memory_day.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/utils/app_localizations_loader.dart';

class _ResolvedActorContext {
  const _ResolvedActorContext({
    required this.uid,
    required this.role,
    required this.displayName,
  });

  final String uid;
  final String role;
  final String displayName;

  bool get isParent => role == 'parent';
  bool get isGuardian => role == 'guardian';
  bool get isChild => role == 'child';
}

class _NotificationAudience {
  const _NotificationAudience({
    required this.children,
    required this.guardians,
  });

  final List<ChildItem> children;
  final List<AppUser> guardians;

  ChildItem? findChildById(String childId) {
    for (final child in children) {
      if (child.id == childId) return child;
    }
    return null;
  }
}

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
    // Phase 4: Fan out schedule notifications by explicit actor role instead
    // of assuming "owner uid = parent, everything else = child".
    final actor = await _resolveActorContext(
      actorUid: actorUid,
      ownerParentUid: scheduleOwnerUid,
    );
    final audience = await _loadAudience(scheduleOwnerUid);
    final targetChild = audience.findChildById(schedule.childId);
    final receiverIds = _resolveScheduleReceiverIds(
      actor: actor,
      ownerParentUid: scheduleOwnerUid,
      targetChildId: schedule.childId,
      guardians: audience.guardians,
    );

    for (final receiverId in receiverIds) {
      if (receiverId.isEmpty || receiverId == actorUid) continue;

      final l10n = await _loadL10nForUser(receiverId);
      final childName = _resolveChildName(targetChild?.name, l10n);
      final receiverRole = _resolveReceiverRole(
        receiverId: receiverId,
        ownerParentUid: scheduleOwnerUid,
        guardians: audience.guardians,
        childId: schedule.childId,
      );

      final title = _buildTitle(action, l10n);
      final body = _buildBody(
        action: action,
        actorRole: actor.role,
        actorDisplayName: _actorDisplayNameForMessage(actor, l10n),
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
        'actorRole': actor.role,
        'actorDisplayName': actor.displayName,
        'actorChildName': actor.isParent ? '' : actor.displayName,
        'receiverId': receiverId,
        'receiverRole': receiverRole,
        'scheduleTitle': schedule.title,
        'date': DateFormat('dd/MM/yyyy').format(schedule.date),
        'startAt': _hhmm(schedule.startAt),
        'endAt': _hhmm(schedule.endAt),
        'dateIso': schedule.date.toIso8601String(),
        'startAtIso': schedule.startAt.toIso8601String(),
        'endAtIso': schedule.endAt.toIso8601String(),
      };

      debugPrint(
        '[SCHEDULE_NOTIFY] sender=$actorUid actorRole=${actor.role} receiver=$receiverId receiverRole=$receiverRole child=$childName schedule=${schedule.id}',
      );

      await NotificationService.sendUserToUser(
        senderId: actorUid,
        receiverId: receiverId,
        type: NotificationType.schedule.value,
        title: title,
        body: body,
        data: data,
      );
    }
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
    final actor = await _resolveActorContext(
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
    );
    final audience = await _loadAudience(ownerParentUid);
    final receiverIds = _resolveScheduleReceiverIds(
      actor: actor,
      ownerParentUid: ownerParentUid,
      targetChildId: childId,
      guardians: audience.guardians,
    );

    for (final receiverId in receiverIds) {
      if (receiverId.isEmpty || receiverId == actorUid) continue;

      final l10n = await _loadL10nForUser(receiverId);
      final receiverRole = _resolveReceiverRole(
        receiverId: receiverId,
        ownerParentUid: ownerParentUid,
        guardians: audience.guardians,
        childId: childId,
      );
      final targetChild = audience.findChildById(childId);
      final resolvedChildName = (childName ?? '').trim().isNotEmpty
          ? childName!.trim()
          : _resolveChildName(targetChild?.name, l10n);

      final title = l10n.scheduleImportNotifyTitle;
      final body = actor.isParent
          ? l10n.scheduleImportNotifyBodyParent(importCount, resolvedChildName)
          : l10n.scheduleImportNotifyBodyChild(
              _actorDisplayNameForMessage(actor, l10n),
              importCount,
            );

      final data = {
        'entity': 'schedule_import',
        'action': 'imported',
        'actorUid': actorUid,
        'actorRole': actor.role,
        'actorDisplayName': actor.displayName,
        'actorChildName': actor.isParent ? '' : actor.displayName,
        'ownerParentUid': ownerParentUid,
        'childId': childId,
        'childName': resolvedChildName,
        'receiverId': receiverId,
        'receiverRole': receiverRole,
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
  }

  Future<void> _sendMemoryDay({
    required String action,
    required String actorUid,
    required String ownerParentUid,
    required MemoryDay memoryDay,
  }) async {
    // Phase 4: Memory Day now notifies cross-adult peers too, so guardian and
    // parent stay in sync on family-level schedule changes.
    final actor = await _resolveActorContext(
      actorUid: actorUid,
      ownerParentUid: ownerParentUid,
    );
    final audience = await _loadAudience(ownerParentUid);
    final receiverIds = _resolveMemoryDayReceiverIds(
      actor: actor,
      ownerParentUid: ownerParentUid,
      audience: audience,
    );

    for (final receiverId in receiverIds) {
      if (receiverId.isEmpty || receiverId == actorUid) continue;

      final l10n = await _loadL10nForUser(receiverId);
      final receiverRole = _resolveReceiverRole(
        receiverId: receiverId,
        ownerParentUid: ownerParentUid,
        guardians: audience.guardians,
      );
      final receiverChild = audience.findChildById(receiverId);
      final title = _buildMemoryDayTitle(action, l10n);
      final body = _buildMemoryDayBody(
        action: action,
        actorRole: actor.role,
        actorDisplayName: _actorDisplayNameForMessage(actor, l10n),
        memoryDay: memoryDay,
        l10n: l10n,
      );

      final data = {
        'entity': 'memory_day',
        'action': action,
        'actorUid': actorUid,
        'actorRole': actor.role,
        'actorDisplayName': actor.displayName,
        'actorChildName': actor.isParent ? '' : actor.displayName,
        'ownerParentUid': ownerParentUid,
        'memoryDayId': memoryDay.id,
        'memoryDayTitle': memoryDay.title,
        'date': DateFormat('dd/MM/yyyy').format(memoryDay.date),
        'dateIso': memoryDay.date.toIso8601String(),
        'repeatYearly': memoryDay.repeatYearly.toString(),
        'note': (memoryDay.note ?? '').trim(),
        'receiverId': receiverId,
        'receiverRole': receiverRole,
        'childId': receiverChild?.id ?? '',
        'childName': receiverChild == null
            ? ''
            : _resolveChildName(receiverChild.name, l10n),
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
          '[MEMORY_DAY_NOTIFY] failed send to receiver=$receiverId action=$action error=$e',
        );
      }
    }
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
    required String actorRole,
    required String actorDisplayName,
    required MemoryDay memoryDay,
    required AppLocalizations l10n,
  }) {
    final title = memoryDay.title.trim().isEmpty
        ? l10n.notificationsNoTitle
        : memoryDay.title.trim();

    if (actorRole == 'parent') {
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
        return l10n.memoryDayNotifyBodyChildCreated(actorDisplayName, title);
      case 'updated':
        return l10n.memoryDayNotifyBodyChildUpdated(actorDisplayName, title);
      case 'deleted':
        return l10n.memoryDayNotifyBodyChildDeleted(actorDisplayName, title);
      default:
        return l10n.memoryDayNotifyBodyChildChanged(actorDisplayName, title);
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
    required String actorRole,
    required String actorDisplayName,
    required String childName,
    required Schedule schedule,
    required AppLocalizations l10n,
  }) {
    final title = schedule.title.trim().isEmpty
        ? l10n.notificationsNoTitle
        : schedule.title.trim();
    final date = DateFormat('dd/MM/yyyy').format(schedule.date);
    final time = '${_hhmm(schedule.startAt)} - ${_hhmm(schedule.endAt)}';

    if (actorRole == 'parent') {
      switch (action) {
        case 'created':
          return l10n.scheduleNotifyBodyParentCreated(
            title,
            childName,
            date,
            time,
          );
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
        return l10n.scheduleNotifyBodyChildCreated(
          actorDisplayName,
          title,
          date,
          time,
        );
      case 'updated':
        return l10n.scheduleNotifyBodyChildUpdated(actorDisplayName, title);
      case 'deleted':
        return l10n.scheduleNotifyBodyChildDeleted(actorDisplayName, title);
      case 'restored':
        return l10n.scheduleNotifyBodyChildRestored(actorDisplayName, title);
      default:
        return l10n.scheduleNotifyBodyChildChanged(actorDisplayName, title);
    }
  }

  String _resolveChildName(String? name, AppLocalizations l10n) {
    final n = (name ?? '').trim();
    return n.isEmpty ? l10n.notificationsDefaultChildName : n;
  }

  Future<_ResolvedActorContext> _resolveActorContext({
    required String actorUid,
    required String ownerParentUid,
  }) async {
    final actorUser = await _userRepo.getUserById(actorUid);
    final role = switch (actorUser?.role) {
      UserRole.parent => 'parent',
      UserRole.guardian => 'guardian',
      UserRole.child => 'child',
      null => actorUid == ownerParentUid ? 'parent' : 'child',
    };

    final displayName = _resolveActorDisplayName(actorUser);
    return _ResolvedActorContext(
      uid: actorUid,
      role: role,
      displayName: displayName,
    );
  }

  Future<_NotificationAudience> _loadAudience(String ownerParentUid) async {
    final children = await _userRepo.getChildrenByParentUid(ownerParentUid);
    final guardians = await _userRepo.getGuardiansByParentUid(ownerParentUid);
    return _NotificationAudience(children: children, guardians: guardians);
  }

  List<String> _resolveScheduleReceiverIds({
    required _ResolvedActorContext actor,
    required String ownerParentUid,
    required String targetChildId,
    required List<AppUser> guardians,
  }) {
    final receiverIds = <String>{};

    switch (actor.role) {
      case 'parent':
        receiverIds.add(targetChildId);
        receiverIds.addAll(guardians.map((guardian) => guardian.uid));
        break;
      case 'guardian':
        receiverIds.add(targetChildId);
        receiverIds.add(ownerParentUid);
        receiverIds.addAll(guardians.map((guardian) => guardian.uid));
        break;
      case 'child':
      default:
        receiverIds.add(ownerParentUid);
        receiverIds.addAll(guardians.map((guardian) => guardian.uid));
        break;
    }

    receiverIds.remove(actor.uid);
    receiverIds.removeWhere((receiverId) => receiverId.trim().isEmpty);
    return receiverIds.toList();
  }

  List<String> _resolveMemoryDayReceiverIds({
    required _ResolvedActorContext actor,
    required String ownerParentUid,
    required _NotificationAudience audience,
  }) {
    final receiverIds = <String>{};

    switch (actor.role) {
      case 'parent':
        receiverIds.addAll(audience.children.map((child) => child.id));
        receiverIds.addAll(audience.guardians.map((guardian) => guardian.uid));
        break;
      case 'guardian':
        receiverIds.add(ownerParentUid);
        receiverIds.addAll(audience.children.map((child) => child.id));
        receiverIds.addAll(audience.guardians.map((guardian) => guardian.uid));
        break;
      case 'child':
      default:
        receiverIds.add(ownerParentUid);
        receiverIds.addAll(audience.guardians.map((guardian) => guardian.uid));
        break;
    }

    receiverIds.remove(actor.uid);
    receiverIds.removeWhere((receiverId) => receiverId.trim().isEmpty);
    return receiverIds.toList();
  }

  String _resolveReceiverRole({
    required String receiverId,
    required String ownerParentUid,
    required List<AppUser> guardians,
    String? childId,
  }) {
    if (receiverId == ownerParentUid) return 'parent';
    if (childId != null && receiverId == childId) return 'child';

    for (final guardian in guardians) {
      if (guardian.uid == receiverId) return 'guardian';
    }

    return 'unknown';
  }

  String _resolveActorDisplayName(AppUser? actorUser) {
    return (actorUser?.displayName ?? actorUser?.email ?? '').trim();
  }

  String _actorDisplayNameForMessage(
    _ResolvedActorContext actor,
    AppLocalizations l10n,
  ) {
    if (actor.displayName.isNotEmpty) return actor.displayName;
    if (actor.isChild) return l10n.notificationsActorChild;
    return l10n.notificationsActorParent;
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
