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
  StreamSubscription<List<AppUser>>? _locationMembersSub;

  final List<AppUser> _children = [];
  List<AppUser> get children => _children;

  final List<AppUser> _familyMembers = [];
  List<AppUser> get familyMembers => _familyMembers;
  final List<AppUser> _locationMembers = [];
  List<AppUser> get locationMembers => _locationMembers;
  List<String> get childrenIds => _children.map((c) => c.uid).toList();
  List<String> get locationMemberIds =>
      _locationMembers.map((member) => member.uid).toList();

  String? _currentWatchedUid;
  String? _currentProfileUid;

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
    _familyMembers.clear();
    _locationMembers.clear();

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
    if (_currentWatchedUid == uid && _meSub != null) return;
    _currentWatchedUid = uid;

    _meSub?.cancel();
    _meSub = _userRepo
        .watchUserById(uid)
        .listen(
          (u) {
            me = u;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Lỗi tải thông tin người dùng: $e';
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
    }, onError: (e) => _setError('Lỗi tải danh sách trẻ: $e'));
  }

  void watchFamilyMembers(String familyId) {
    _familySub?.cancel();

    final myUid = _storage.getString(StorageKeys.uid);

    _familySub = _userRepo.watchFamilyMembers(familyId).listen((list) {
      _familyMembers
        ..clear()
        ..addAll(list.where((u) => u.uid != myUid));

      notifyListeners();
    }, onError: (e) => _setError('Lỗi tải danh sách thành viên: $e'));
  }

  void watchLocationMembers(String familyId, {String? excludeUid}) {
    _locationMembersSub?.cancel();

    final myUid = excludeUid ?? _storage.getString(StorageKeys.uid);

    _locationMembersSub = _userRepo
        .watchTrackableLocationMembers(familyId, excludeUid: myUid)
        .listen((list) {
          _locationMembers
            ..clear()
            ..addAll(list);
          notifyListeners();
        }, onError: (e) => _setError('Location members load error: $e'));
  }

  Future<void> watchFamilyMembersByParent(String parentUid) async {
    try {
      final familyId = await _userRepo.getFamilyId(parentUid);

      if (familyId == null || familyId.isEmpty) {
        _setError('Không tìm thấy familyId');
        return;
      }

      watchFamilyMembers(familyId);
    } catch (e) {
      _setError('Lỗi load family: $e');
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
        _error = "Không tìm thấy userId";
        return null;
      }

      profile = await _userRepo.getUserProfile(resolvedUid);

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
      _error = "Không tìm thấy userId";
      notifyListeners();
      return;
    }

    if (_currentProfileUid == resolvedUid && _profileSubscription != null)
      return;
    _currentProfileUid = resolvedUid;

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
      _error = "Không tìm thấy userId";
      return false;
    }

    if (name.trim().isEmpty) {
      _error = "Họ và tên không được để trống";
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
        _error = "Cập nhật ảnh thất bại";
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
        throw Exception('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại');
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
    _familySub?.cancel();
    _locationMembersSub?.cancel();
    _profileSubscription?.cancel();
    _meSub?.cancel();
    super.dispose();
  }
}
