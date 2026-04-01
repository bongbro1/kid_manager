import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_profile_patch.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/image_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

extension FirebaseUserX on User? {
  bool get hasPasswordProvider {
    return this?.providerData.any((p) => p.providerId == 'password') ?? false;
  }
}

class UserVm extends ChangeNotifier {
  final UserRepository _userRepo;
  final StorageService _storage;
  final AccessControlService _accessControl;

  UserVm(this._userRepo, this._storage, this._accessControl);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  UserProfile? profile;

  AppUser? me;
  String? get familyId => me?.familyId;

  StreamSubscription<AppUser?>? _meSub;
  StreamSubscription<UserProfile?>? _profileSubscription;
  StreamSubscription<List<AppUser>>? _childrenSub;
  StreamSubscription<List<AppUser>>? _familySub;
  StreamSubscription<List<AppUser>>? _locationMembersSub;

  final List<AppUser> _children = [];
  final List<AppUser> _allChildren = [];
  List<AppUser> get children => _children;

  final List<AppUser> _familyMembers = [];
  final List<AppUser> _allFamilyMembers = [];
  List<AppUser> get familyMembers => _familyMembers;
  final List<AppUser> _locationMembers = [];
  final List<AppUser> _allLocationMembers = [];
  List<AppUser> get locationMembers => _locationMembers;
  List<String> get childrenIds => _children.map((c) => c.uid).toList();
  List<String> get locationMemberIds =>
      _locationMembers.map((member) => member.uid).toList();

  String? _currentWatchedUid;
  String? _currentProfileUid;

  UserRole get _sessionRole => roleFromString(
    _storage.getString(StorageKeys.role),
    fallback: UserRole.child,
  );
  bool get canChangePassword {
    return FirebaseAuth.instance.currentUser.hasPasswordProvider;
  }

  String? get _storedParentOwnerUid {
    final value = _storage.getString(StorageKeys.parentId)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  List<String> get _storedManagedChildIds {
    final values =
        _storage.getStringList(StorageKeys.managedChildIds) ?? const <String>[];
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  AppUser? get _resolvedActor {
    final currentUser = me;
    if (currentUser != null) {
      return currentUser;
    }

    final currentUid = _storage.getString(StorageKeys.uid)?.trim();
    final currentProfile = profile;
    if (currentUid == null ||
        currentUid.isEmpty ||
        currentProfile == null ||
        currentProfile.id != currentUid) {
      return null;
    }

    return AppUser(
      uid: currentUid,
      role: currentProfile.role,
      phone: currentProfile.phone.trim().isEmpty
          ? null
          : currentProfile.phone.trim(),
      displayName: currentProfile.name.trim().isEmpty
          ? null
          : currentProfile.name.trim(),
      coverUrl: currentProfile.coverUrl,
      avatarUrl: currentProfile.avatarUrl,
      locale: currentProfile.locale,
      timezone: currentProfile.timezone,
      allowTracking: currentProfile.allowTracking,
      parentUid: currentProfile.parentUid,
      managedChildIds: currentProfile.managedChildIds,
    );
  }

  AppUser? get actorSnapshot {
    final actor = _resolvedActor;
    if (actor != null) {
      return actor;
    }

    final currentUid = _storage.getString(StorageKeys.uid)?.trim();
    if (currentUid == null || currentUid.isEmpty) {
      return null;
    }

    return AppUser(
      uid: currentUid,
      role: _sessionRole,
      parentUid: _storedParentOwnerUid,
      managedChildIds: _storedManagedChildIds,
    );
  }

  List<AppUser> _filterChildrenByAccess(List<AppUser> list) {
    final actor = actorSnapshot;
    if (actor == null) {
      return _sessionRole == UserRole.guardian ? <AppUser>[] : list;
    }

    return list
        .where(
          (child) => _accessControl.canAccessChild(
            actor: actor,
            childUid: child.uid,
            child: child,
          ),
        )
        .toList(growable: false);
  }

  List<AppUser> _filterLocationMembersByAccess(List<AppUser> list) {
    final actor = actorSnapshot;
    if (actor == null) {
      return _sessionRole == UserRole.guardian ? <AppUser>[] : list;
    }

    return list
        .where((member) {
          if (member.role == UserRole.child) {
            return _accessControl.canAccessChild(
              actor: actor,
              childUid: member.uid,
              child: member,
            );
          }

          if (actor.role.isAdultManager) {
            return member.role == UserRole.guardian && member.allowTracking;
          }

          return false;
        })
        .toList(growable: false);
  }

  List<AppUser> _filterFamilyMembersByAccess(List<AppUser> list) {
    final actor = actorSnapshot;
    if (actor == null) {
      return list;
    }

    if (actor.role == UserRole.parent) {
      return list;
    }

    if (actor.role == UserRole.guardian) {
      return list
          .where((member) {
            if (member.role == UserRole.parent) {
              return member.uid == (actor.parentUid?.trim() ?? '');
            }
            if (member.role == UserRole.child) {
              return _accessControl.canAccessChild(
                actor: actor,
                childUid: member.uid,
                child: member,
              );
            }
            return false;
          })
          .toList(growable: false);
    }

    return list
        .where((member) => member.role == UserRole.parent)
        .toList(growable: false);
  }

  void _recomputeChildren({bool notify = true}) {
    final filtered = _filterChildrenByAccess(_allChildren);
    _children
      ..clear()
      ..addAll(filtered);
    if (notify) {
      notifyListeners();
    }
  }

  void _recomputeLocationMembers({bool notify = true}) {
    final filtered = _filterLocationMembersByAccess(_allLocationMembers);
    _locationMembers
      ..clear()
      ..addAll(filtered);
    if (notify) {
      notifyListeners();
    }
  }

  void _recomputeFamilyMembers({bool notify = true}) {
    final filtered = _filterFamilyMembersByAccess(_allFamilyMembers);
    _familyMembers
      ..clear()
      ..addAll(filtered);
    if (notify) {
      notifyListeners();
    }
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  Future<void> setCurrentUser(String uid) async {
    if (uid.isEmpty) return;
    if (_currentWatchedUid == uid && _currentProfileUid == uid) return;
    _error = null;
    watchMe(uid);
    listenProfile(uid: uid);
  }

  Future<void> clear() async {
    _currentWatchedUid = null;
    _currentProfileUid = null;
    await _childrenSub?.cancel();
    await _familySub?.cancel();
    await _locationMembersSub?.cancel();
    await _profileSubscription?.cancel();
    await _meSub?.cancel();

    _childrenSub = null;
    _familySub = null;
    _locationMembersSub = null;
    _profileSubscription = null;
    _meSub = null;

    _loading = false;
    _error = null;
    profile = null;
    me = null;
    _children.clear();
    _allChildren.clear();
    _familyMembers.clear();
    _allFamilyMembers.clear();
    _locationMembers.clear();
    _allLocationMembers.clear();

    notifyListeners();
  }

  Future<void> suspendSessionStreams({bool notify = false}) async {
    _currentWatchedUid = null;
    _currentProfileUid = null;

    await _childrenSub?.cancel();
    await _familySub?.cancel();
    await _locationMembersSub?.cancel();
    await _profileSubscription?.cancel();
    await _meSub?.cancel();

    _childrenSub = null;
    _familySub = null;
    _locationMembersSub = null;
    _profileSubscription = null;
    _meSub = null;

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> loadUsers() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      users = await _userRepo.loadAllUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<UserItem> users = [];

  void watchMe(String uid) {
    if (_currentWatchedUid == uid && _meSub != null) return;
    _currentWatchedUid = uid;

    _meSub?.cancel();
    _meSub = _userRepo
        .watchUserById(uid)
        .listen(
          (u) {
            me = u;
            _recomputeChildren(notify: false);
            _recomputeFamilyMembers(notify: false);
            _recomputeLocationMembers(notify: false);
            notifyListeners();
          },
          onError: (e) {
            _error = runtimeL10n().userVmLoadUserError('$e');
            notifyListeners();
          },
        );
  }

  void watchChildren(String parentUid) {
    _childrenSub?.cancel();

    _childrenSub = _userRepo.watchChildren(parentUid).listen((list) {
      _allChildren
        ..clear()
        ..addAll(list);
      _recomputeChildren();
    }, onError: (e) => _setError(runtimeL10n().userVmLoadChildrenError('$e')));
  }

  void watchFamilyMembers(String familyId) {
    _familySub?.cancel();

    _familySub = _userRepo.watchFamilyMembers(familyId).listen((list) {
      _allFamilyMembers
        ..clear()
        ..addAll(list);
      _recomputeFamilyMembers();
    }, onError: (e) => _setError(runtimeL10n().userVmLoadMembersError('$e')));
  }

  void watchLocationMembers(String familyId, {String? excludeUid}) {
    _locationMembersSub?.cancel();

    final myUid = excludeUid ?? _storage.getString(StorageKeys.uid);

    _locationMembersSub = _userRepo
        .watchTrackableLocationMembers(familyId, excludeUid: myUid)
        .listen((list) {
          _allLocationMembers
            ..clear()
            ..addAll(list);
          _recomputeLocationMembers();
        }, onError: (e) => _setError('Location members load error: $e'));
  }

  Future<void> watchFamilyMembersByParent(String parentUid) async {
    try {
      final familyId = await _userRepo.getFamilyId(parentUid);

      if (familyId == null || familyId.isEmpty) {
        _setError(runtimeL10n().userVmFamilyIdNotFound);
        return;
      }

      watchFamilyMembers(familyId);
    } catch (e) {
      _setError(runtimeL10n().userVmLoadFamilyError('$e'));
    }
  }

  Future<UserProfile?> loadProfile({
    String? uid,
    String caller = 'unknown',
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final storageUid = _storage.getString(StorageKeys.uid);
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      final resolvedUid = uid ?? storageUid ?? authUid;

      debugPrint('[loadProfile][$caller] param uid=$uid');
      debugPrint('[loadProfile][$caller] storage uid=$storageUid');
      debugPrint('[loadProfile][$caller] auth uid=$authUid');
      debugPrint('[loadProfile][$caller] resolvedUid=$resolvedUid');

      if (resolvedUid == null || resolvedUid.isEmpty) {
        _error = runtimeL10n().userVmUserIdNotFound;
        return null;
      }

      profile = await _userRepo.getUserProfile(resolvedUid);
      _recomputeChildren(notify: false);
      _recomputeFamilyMembers(notify: false);
      _recomputeLocationMembers(notify: false);

      if (_currentWatchedUid != resolvedUid) {
        watchMe(resolvedUid);
      }
      if (_currentProfileUid != resolvedUid) {
        listenProfile(uid: resolvedUid);
      }

      return profile;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void listenProfile({String? uid}) {
    final storageUid = _storage.getString(StorageKeys.uid);
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    final resolvedUid = uid ?? storageUid ?? authUid;
    if (resolvedUid == null || resolvedUid.isEmpty) {
      _error = runtimeL10n().userVmUserIdNotFound;
      notifyListeners();
      return;
    }

    if (_currentProfileUid == resolvedUid && _profileSubscription != null) {
      return;
    }
    _currentProfileUid = resolvedUid;

    _profileSubscription?.cancel();
    _profileSubscription = _userRepo
        .listenUserProfile(resolvedUid)
        .listen(
          (data) {
            profile = data;
            _recomputeChildren(notify: false);
            _recomputeFamilyMembers(notify: false);
            _recomputeLocationMembers(notify: false);
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<UserRole> fetchUserRole(String uid) {
    return _userRepo.getUserRole(uid);
  }

  Future<bool> updateUserInfo({
    required String name,
    required String phone,
    required String gender,
    required String dob,
    required String address,
    required bool allowTracking,
    String? locale,
  }) async {
    _error = null;

    final userId = _storage.getString(StorageKeys.uid);

    if (userId == null) {
      _error = runtimeL10n().userVmUserIdNotFound;
      return false;
    }

    if (name.trim().isEmpty) {
      _error = runtimeL10n().userVmFullNameRequired;
      return false;
    }

    _loading = true;
    notifyListeners();

    try {
      final patch = UserProfilePatch(
        name: name.trim(),
        phone: phone.trim(),
        gender: gender.trim(),
        dob: dob.trim(),
        address: address.trim(),
        allowTracking: allowTracking,
        locale: locale?.trim(),
      );
      if (locale != null) {
        final localeCode = locale.trim();
        await _storage.setString(StorageKeys.locale, localeCode);
        await _storage.setString('preferredLocale', localeCode);
      }

      await _userRepo.patchUserProfile(uid: userId, patch: patch);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> syncUserTimeZone({
    required String uid,
    required String timeZone,
    String? currentTimeZone,
  }) async {
    final normalizedUid = uid.trim();
    final normalizedTimeZone = timeZone.trim();
    final normalizedCurrentTimeZone =
        (currentTimeZone ?? profile?.timezone ?? me?.timezone)?.trim() ?? '';

    if (normalizedUid.isEmpty ||
        normalizedTimeZone.isEmpty ||
        normalizedTimeZone == normalizedCurrentTimeZone) {
      return;
    }

    await _userRepo.updateTimeZone(
      uid: normalizedUid,
      timezone: normalizedTimeZone,
    );

    if (profile?.id == normalizedUid) {
      profile = profile?.copyWith(timezone: normalizedTimeZone);
    }
    if (me?.uid == normalizedUid) {
      me = me?.copyWith(timezone: normalizedTimeZone);
    }

    notifyListeners();
  }

  void updateLocalPhoto(File file, UserPhotoType type) {
    final localUrl = file.path;

    if (profile != null) {
      if (type == UserPhotoType.avatar) {
        profile = profile!.copyWith(avatarUrl: localUrl);
      } else {
        profile = profile!.copyWith(coverUrl: localUrl);
      }
    }

    notifyListeners();
  }

  Future<bool> updateUserPhoto({
    required File file,
    required UserPhotoType type,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final url = await FirebaseStorageService.uploadUserPhoto(
        file: file,
        uid: uid,
        type: type,
      );

      unawaited(_userRepo.updateUserPhotoUrl(uid: uid, url: url, type: type));

      if (profile != null) {
        profile = type == UserPhotoType.avatar
            ? profile!.copyWith(avatarUrl: url)
            : profile!.copyWith(coverUrl: url);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Update photo error: $e");
      return false;
    }
  }

  Future<bool> addChildAccount({
    required String name,
    required String email,
    required String password,
    required DateTime dob,
    UserRole role = UserRole.child,
    required String locale,
    required String timezone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final actor = actorSnapshot;
      if (actor == null ||
          !_accessControl.canAddManagedAccounts(actor: actor)) {
        throw Exception(runtimeL10n().firestorePermissionDenied);
      }

      final parentUid = actor.uid;

      if (parentUid.isEmpty) {
        throw Exception(runtimeL10n().sessionExpiredLoginAgain);
      }
      await _userRepo.createChildAccount(
        parentUid: parentUid,
        email: email,
        password: password,
        displayName: name,
        dob: dob,
        role: role,
        locale: locale,
        timezone: timezone,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> assignGuardianChildren({
    required String guardianUid,
    required List<String> childIds,
  }) async {
    final actor = actorSnapshot;
    if (actor == null || actor.role != UserRole.parent) {
      throw Exception(runtimeL10n().firestorePermissionDenied);
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _userRepo.assignGuardianChildren(
        parentUid: actor.uid,
        guardianUid: guardianUid,
        childIds: childIds,
      );
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _childrenSub?.cancel();
    _familySub?.cancel();
    _locationMembersSub?.cancel();
    _profileSubscription?.cancel();
    _meSub?.cancel();
    super.dispose();
  }
}
