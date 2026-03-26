import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/repositories/otp_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';
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

  AppUser? currentUser;

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

      final userInfo = await _userRepo.getUserById(uid);

      if (userInfo == null) {
        await _authRepo.logout();
        throw Exception("accountNotFound");
      }

      if (userInfo.isActive != true) {
        await _authRepo.logout();
        throw Exception("accountNotActivated");
      }

      _user = user;
      debugPrint("User : $_user");
      notifyListeners();

      return cred;
    });
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

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _runAuthAction(() async {
      /// validate password rule
      final passError = Validators.validatePassword(
        newPassword,
        l10n: runtimeL10n(),
      );
      if (passError != null) {
        throw Exception(passError);
      }

      /// validate confirm password
      final confirmError = Validators.validateConfirmPassword(
        newPassword,
        confirmPassword,
        l10n: runtimeL10n(),
      );
      if (confirmError != null) {
        throw Exception(confirmError);
      }

      /// gọi repo
      await _authRepo.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
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
      await _authRepo.logout();
      await FcmPushReceiverService.onSignedOut();
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

      _error = runtimeL10n().authGenericError;
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
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

  // login social

  Future<void> loginWithGoogle() async {
    try {
      _setError(null);
      _setLoading(true);

      final user = await _authRepo.signInWithGoogle();

      await _handleUser(user);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithFacebook() async {
    try {
      _setError(null);
      _setLoading(true);

      final user = await _authRepo.signInWithFacebook();
      await _handleUser(user);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithApple() async {
    // try {
    //   _setError(null);
    //   _setLoading(true);

    //   final user = await _authRepo.signInWithApple();
    //   await _handleUser(user);
    // } catch (e) {
    //   _setError(e.toString());
    // } finally {
    //   _setLoading(false);
    // }
  }

  Future<void> loginWithPhone() async {
    // try {
    //   _setError(null);
    //   _setLoading(true);

    //   await _authRepo.signInWithPhone();
    // } catch (e) {
    //   _setError(e.toString());
    // } finally {
    //   _setLoading(false);
    // }
  }

  bool _isSendingOtp = false;
  bool get isSendingOtp => _isSendingOtp;

  Future<void> sendOtpSms(String phone) async {
    try {
      _isSendingOtp = true;
      notifyListeners();

      _setError(null);

      await _authRepo.sendOtpSms(phone, (verificationId) {
        debugPrint("[AUTH_PHONE] OTP sent: $verificationId");
      });
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtpSmS(String code) async {
    try {
      _isSendingOtp = true;
      notifyListeners();

      _setError(null);

      final user = await _authRepo.verifyOtpSms(code);
      await _handleUser(user);
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _isSendingOtp = false;
      notifyListeners();
    }
  }

  Future<void> _handleUser(AppUser? user) async {
    if (user == null) {
      _setError(runtimeL10n().authLoginCancelled);
      return;
    }
    try {
      final existingUser = await _authRepo.getUser(user.uid);

      if (existingUser == null) {
        await _userRepo.createParentIfMissing(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          locale: user.locale ?? 'vi',
          timezone: user.timezone ?? 'Asia/Ho_Chi_Minh',
        );
        currentUser = await _authRepo.getUser(user.uid);
      } else {
        currentUser = existingUser;
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
