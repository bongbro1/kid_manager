import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/imgbb_service.dart';
import 'package:kid_manager/services/storage_service.dart';

class UserVm extends ChangeNotifier {
  final UserRepository _userRepo;
  final StorageService _storage;

  UserVm(this._userRepo, this._storage);

  /* ============================================================
     GENERAL STATE
  ============================================================ */

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;
  UserProfile? profile;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  /* ============================================================
     CHILDREN (USER DOMAIN)
  ============================================================ */

  final List<AppUser> _children = [];
  List<AppUser> get children => _children;

  List<String> get childrenIds => _children.map((c) => c.uid).toList();

  StreamSubscription<List<AppUser>>? _childrenSub;

  void watchChildren(String parentUid) {
    _childrenSub?.cancel();
    _childrenSub = _userRepo.watchChildren(parentUid).listen((list) {
      debugPrint('USER_VM children=${list.length}');
      _children
        ..clear()
        ..addAll(list);
      notifyListeners();
    }, onError: (e) => _setError('Lỗi load children: $e'));
  }

  /* ============================================================
     CREATE CHILD
  ============================================================ */

  Future<String?> createChildAccount({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    required String locale,
    required String timezone,
  }) async {
    try {
      _setLoading(true);
      _error = null;

      final childUid = await _userRepo.createChildAccount(
        parentUid: parentUid,
        email: email,
        password: password,
        displayName: displayName,
        dob: dob,
        locale: locale,
        timezone: timezone,
      );

      watchChildren(parentUid);

      return childUid;
    } catch (e, s) {
      debugPrint('UserVm.createChildAccount error: $e');
      debugPrintStack(stackTrace: s);
      _setError('Không thể tạo tài khoản trẻ');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadProfile() async {
    _error = null;
    _loading = true;
    notifyListeners();

    try {
      final uid = _storage.getString(StorageKeys.uid);

      if (uid == null) {
        _error = "Không tìm thấy userId";
        _loading = false;
        notifyListeners();
        return;
      }

      profile = await _userRepo.getUserProfile(uid);
      // debugPrint("==== USER PROFILE ====");
      // debugPrint("UID: ${profile?.id}");
      // debugPrint("Avatar: ${profile?.avatarUrl}");
      // debugPrint("Cover: ${profile?.coverUrl}");
      // debugPrint("======================");
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
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
  }) async {
    // reset state
    _error = null;

    final userId = _storage.getString(StorageKeys.uid);

    if (userId == null) {
      _error = "Không tìm thấy userId";
      return false;
    }

    // ✅ validate basic (bạn tự nâng cấp)
    if (name.trim().isEmpty) {
      _error = "Họ và tên không được để trống";
      return false;
    }

    _loading = true;

    try {
      final _newprofile = UserProfile(
        id: userId,
        name: name.trim(),
        phone: phone.trim(),
        gender: gender.trim(),
        dob: dob.trim(),
        address: address.trim(),
        allowTracking: allowTracking,
      );

      await _userRepo.updateUserProfile(_newprofile);

      _loading = false;
      return true;
    } catch (e) {
      _loading = false;
      _error = e.toString();
      notifyListeners();
      return false;
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

      // 1️⃣ Upload lên ImgBB
      final url = await ImgBBService.updateUserPhoto(
        file: file,
        field: type == UserPhotoType.avatar ? 'avatarUrl' : 'coverUrl',
      );

      // 2️⃣ Update Firestore
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

  @override
  void dispose() {
    _childrenSub?.cancel();
    super.dispose();
  }
}
