import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';

class ScheduleSessionState {
  final String currentUid;
  final UserRole? role;
  final bool isChildMode;
  final String ownerParentUid;
  final String? familyId;
  final String? selectedChildId;
  final String? lockedChildName;
  final List<AppUser> children;

  const ScheduleSessionState({
    required this.currentUid,
    required this.role,
    required this.isChildMode,
    required this.ownerParentUid,
    required this.familyId,
    required this.selectedChildId,
    required this.lockedChildName,
    required this.children,
  });

  ScheduleSessionState copyWith({
    String? currentUid,
    UserRole? role,
    bool? isChildMode,
    String? ownerParentUid,
    String? familyId,
    String? selectedChildId,
    String? lockedChildName,
    List<AppUser>? children,
  }) {
    return ScheduleSessionState(
      currentUid: currentUid ?? this.currentUid,
      role: role ?? this.role,
      isChildMode: isChildMode ?? this.isChildMode,
      ownerParentUid: ownerParentUid ?? this.ownerParentUid,
      familyId: familyId ?? this.familyId,
      selectedChildId: selectedChildId ?? this.selectedChildId,
      lockedChildName: lockedChildName ?? this.lockedChildName,
      children: children ?? this.children,
    );
  }
}

class ScheduleSessionResolver {
  final StorageService storage;
  final UserVm userVm;

  const ScheduleSessionResolver({
    required this.storage,
    required this.userVm,
  });

  Future<ScheduleSessionState?> resolve({
    String? initialChildId,
    bool lockChildSelection = false,
    bool watchChildrenForParent = false,
  }) async {
    final currentUid = storage.getString(StorageKeys.uid);
    final role = roleFromString(
      storage.getString(StorageKeys.role),
      fallback: UserRole.child,
    );

    if (currentUid == null || currentUid.isEmpty) return null;

    final isChildMode = lockChildSelection || role == UserRole.child;

    if (isChildMode) {
      if (userVm.profile == null || userVm.profile!.id != currentUid) {
        await userVm.loadProfile(caller: 'schedule_session_resolver');
      }

      final ownerParentUid = userVm.profile?.parentUid;
      if (ownerParentUid == null || ownerParentUid.isEmpty) return null;

      final lockedChildName = (userVm.profile?.name ?? '').trim();

      return ScheduleSessionState(
        currentUid: currentUid,
        role: role,
        isChildMode: true,
        ownerParentUid: ownerParentUid,
        familyId: userVm.familyId,
        selectedChildId: initialChildId ?? currentUid,
        lockedChildName: lockedChildName.isEmpty ? null : lockedChildName,
        children: const <AppUser>[],
      );
    }

    var ownerParentUid = currentUid;

    // Guardian reuses the parent-owned schedule namespace, so we must resolve
    // the actual owner parent uid instead of treating guardian as the owner.
    if (role == UserRole.guardian) {
      if (userVm.profile == null || userVm.profile!.id != currentUid) {
        await userVm.loadProfile(
          uid: currentUid,
          caller: 'schedule_session_resolver_guardian',
        );
      }

      final resolvedOwnerUid = userVm.profile?.parentUid?.trim() ?? '';
      if (resolvedOwnerUid.isEmpty) return null;
      ownerParentUid = resolvedOwnerUid;
    }

    if (watchChildrenForParent) {
      userVm.watchChildren(ownerParentUid);
    }

    final children = List<AppUser>.unmodifiable(userVm.children);

    return ScheduleSessionState(
      currentUid: currentUid,
      role: role,
      isChildMode: false,
      ownerParentUid: ownerParentUid,
      familyId: userVm.familyId,
      selectedChildId: resolveDefaultChildId(
        initialChildId: initialChildId,
        children: children,
      ),
      lockedChildName: null,
      children: children,
    );
  }

  static String? resolveDefaultChildId({
    required String? initialChildId,
    required List<AppUser> children,
  }) {
    if (initialChildId != null && initialChildId.isNotEmpty) {
      return initialChildId;
    }
    if (children.isEmpty) return null;
    return children.first.uid;
  }
}
