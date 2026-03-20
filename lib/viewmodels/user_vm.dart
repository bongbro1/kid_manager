import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/image_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class UserVm extends ChangeNotifier {
  final UserRepository _userRepo;
  final StorageService _storage;

  UserVm(this._userRepo, this._storage);

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

  final List<AppUser> _children = [];
  List<AppUser> get children => _children;

  final List<AppUser> _familyMembers = [];
  List<AppUser> get familyMembers => _familyMembers;
  List<String> get childrenIds => _children.map((c) => c.uid).toList();

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  Future<void> setCurrentUser(String uid) async {
    if (uid.isEmpty) return;

    _error = null;
    watchMe(uid);
    listenProfile(uid: uid);
  }

  Future<void> clear() async {
    await _childrenSub?.cancel();
    await _profileSubscription?.cancel();
    await _meSub?.cancel();

    _childrenSub = null;
    _profileSubscription = null;
    _meSub = null;

    _loading = false;
    _error = null;
    profile = null;
    me = null;
    _children.clear();

    notifyListeners();
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
    _meSub?.cancel();

    _meSub = _userRepo
        .watchUserById(uid)
        .listen(
          (u) {
            me = u;
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
      _children
        ..clear()
        ..addAll(list);
      notifyListeners();
    }, onError: (e) => _setError(runtimeL10n().userVmLoadChildrenError('$e')));
  }

  void watchFamilyMembers(String familyId) {
    _familySub?.cancel();

    final myUid = _storage.getString(StorageKeys.uid);

    _familySub = _userRepo.watchFamilyMembers(familyId).listen((list) {
      _familyMembers
        ..clear()
        ..addAll(list.where((u) => u.uid != myUid));

      notifyListeners();
    }, onError: (e) => _setError(runtimeL10n().userVmLoadMembersError('$e')));
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

      // Quan trọng: bind luôn AppUser realtime cho phiên hiện tại
      watchMe(resolvedUid);
      listenProfile(uid: resolvedUid);

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

    _profileSubscription?.cancel();
    _profileSubscription = _userRepo
        .listenUserProfile(resolvedUid)
        .listen(
          (data) {
            profile = data;
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
      final newProfile = UserProfile(
        id: userId,
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

      await _userRepo.updateUserProfile(newProfile);
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

  Future<bool> updateUserPhoto({
    required File file,
    required UserPhotoType type,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final url = await FirebaseStorageService.uploadUserPhoto(
        file: file,
        uid: uid,
        type: type,
      );

      final success = await _userRepo.updateUserPhotoUrl(
        uid: uid,
        url: url,
        type: type,
      );

      if (!success) {
        _error = runtimeL10n().userVmUpdatePhotoFailed;
        return false;
      }

      if (profile != null) {
        if (type == UserPhotoType.avatar) {
          profile = profile!.copyWith(avatarUrl: url);
        } else {
          profile = profile!.copyWith(coverUrl: url);
        }
      }

      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint("Update photo error: $e");
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addChildAccount({
    required String name,
    required String email,
    required String password,
    required DateTime dob,
    String role = 'child',
    required String locale,
    required String timezone,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final parentUid = _storage.getString(StorageKeys.uid);

      if (parentUid == null) {
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

  @override
  void dispose() {
    _childrenSub?.cancel();
    _profileSubscription?.cancel();
    _meSub?.cancel();
    super.dispose();
  }
}
