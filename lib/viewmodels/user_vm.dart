import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/auth_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';

class UserVM extends ChangeNotifier {
  final UserRepository _userRepo;

  UserVM(this._userRepo);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  Future<bool> createChild({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    String locale = 'vi',
    String timezone = 'Asia/Ho_Chi_Minh',
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _userRepo.createChildAccount(
        parentUid: parentUid,
        email: email,
        password: password,
        displayName: displayName,
        dob: dob,
        locale: locale,
        timezone: timezone,
      );

      return true;
    } catch (e) {
      _error = 'Không thể tạo tài khoản con';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}