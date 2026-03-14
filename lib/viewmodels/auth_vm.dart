import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/repositories/otp_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import '../repositories/auth_repository.dart';

class AuthVM extends ChangeNotifier {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final OtpRepository _otpRepo;
  final StorageService _storage;

  AuthVM(this._authRepo, this._userRepo, this._otpRepo, this._storage) {
    _listenAuthState();
  }

  User? _user;
  User? get user => _user;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  StreamSubscription<User?>? _sub;

  void _listenAuthState() {
    _sub = _authRepo.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<UserCredential?> login(String email, String password) async {
    return await _runAuthAction<UserCredential?>(() async {
      final cred = await _authRepo.login(email, password);

      final user = cred.user;
      if (user == null) throw Exception("User null");

      final uid = user.uid;

      /// ðŸ”Ž Ä‘á»c user document
      final userInfo = await _userRepo.getUserById(uid);

      if (userInfo == null) {
        await _authRepo.logout();
        throw Exception("accountNotFound");
      }

      // /// âŒ chÆ°a verify OTP
      if (userInfo.isActive != true) {
        await _authRepo.logout();
        throw Exception("accountNotActivated");
      }

      ///  há»£p lá»‡
      _user = user;
      debugPrint("User : $_user");
      notifyListeners();

      await _authRepo.registerCurrentFcmToken(
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
      );
      return cred;
    });
  }

  Future<bool> verifyOtp(String code) async {
    _loading = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final result = await _otpRepo.verifyOtp(uid: uid, inputCode: code);

    _loading = false;
    notifyListeners();

    switch (result) {
      case OtpVerifyResult.success:
        return true;
      case OtpVerifyResult.invalid:
        _error = "invalidCode";
        return false;
      case OtpVerifyResult.expired:
        _error = "codeExpired";
        return false;
      case OtpVerifyResult.tooManyAttempts:
        _error = "tooManyAttempts";
        return false;
      default:
        _error = "unknownError";
        return false;
    }
  }

  Future<void> onLoginSuccess(String userId) async {}

  Future<String?> forgotPassword(String email) async {
    return await _runAuthAction<String>(() async {
      // 1ï¸âƒ£ tÃ¬m user theo email
      final user = await _userRepo.getUserByEmail(email);

      if (user == null) {
        throw Exception("emailNotRegistered");
      }

      // 2ï¸âƒ£ táº¡o OTP
      await _otpRepo.createOtp(
        uid: user.id,
        email: email,
        type: MailType.resetPassword,
      );

      return user.id;
    });
  }

  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  }) async {
    await _runAuthAction(() async {
      await _authRepo.resetPassword(uid: uid, newPassword: newPassword);
    });
  }

  Future<String?> register(String email, String password) async {
    return await _runAuthAction<String>(() async {
      // 1ï¸âƒ£ táº¡o account
      final cred = await _authRepo.register(email: email, password: password);

      final user = cred.user;
      if (user == null) throw Exception("User null");

      final uid = user.uid;

      // 2ï¸âƒ£ táº¡o user doc
      await _userRepo.createParentIfMissing(
        uid: uid,
        email: user.email ?? email,
      );

      // 3ï¸âƒ£ táº¡o OTP
      await _otpRepo.createOtp(
        uid: uid,
        email: email,
        type: MailType.verifyEmail,
      );

      await _authRepo.logout();
      return uid;
    });
  }

  Future<void> logout() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FcmPushReceiverService.removeToken(user.uid);
      }

      await _authRepo.logout();
      await _storage.clearAuthData();
      _user = null;
    } catch (e) {
      _error = e.toString();
      debugPrint("âŒ Logout error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<T?> _runAuthAction<T>(Future<T> Function() action) async {
    _setLoading(true);
    _error = null;

    try {
      final result = await action();
      return result;
    } on FirebaseAuthException catch (e) {
      debugPrint("AUTH ERROR (Firebase): $e");

      _error = _mapFirebaseError(e);
      return null;
    } on Exception catch (e) {
      debugPrint("AUTH ERROR (Exception): $e");

      // láº¥y message tháº­t
      _error = e.toString().replaceFirst("Exception: ", "");
      return null;
    } catch (e) {
      debugPrint("AUTH ERROR (Unknown): $e");

      _error = 'CÃ³ lá»—i xáº£y ra. Vui lÃ²ng thá»­ láº¡i.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'accountNotFound';
      case 'wrong-password':
        return 'wrongPassword';
      case 'email-already-in-use':
        return 'emailInUse';
      case 'invalid-email':
        return 'emailInvalid';
      case 'weak-password':
        return 'weakPassword';
      default:
        return 'loginFailed';
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}


