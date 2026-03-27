import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/repositories/otp_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/location/device_time_zone_service.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';
import '../repositories/auth_repository.dart';

class AuthVM extends ChangeNotifier {
  AuthVM(this._authRepo, this._userRepo, this._otpRepo, this._storage) {
    _listenAuthState();
  }

  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final OtpRepository _otpRepo;
  final StorageService _storage;

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
    return _runAuthAction<UserCredential?>(() async {
      final cred = await _authRepo.login(email, password);

      final user = cred.user;
      if (user == null) {
        throw Exception("User null");
      }

      final userInfo = await _userRepo.getUserById(user.uid);

      if (userInfo == null) {
        await _authRepo.logout();
        throw Exception("accountNotFound");
      }

      if (userInfo.isActive != true) {
        await _authRepo.logout();
        throw Exception("accountNotActivated");
      }

      _user = user;
      notifyListeners();
      return cred;
    });
  }

  Future<void> onLoginSuccess(String userId) async {}

  Future<bool> forgotPassword(String email) async {
    final result = await _runAuthAction<bool>(() async {
      await _otpRepo.requestPasswordReset(email: email);
      return true;
    });
    return result ?? false;
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final result = await _runAuthAction<bool>(() async {
      final passError = Validators.validatePassword(
        newPassword,
        l10n: runtimeL10n(),
      );
      if (passError != null) {
        throw Exception(passError);
      }

      final confirmError = Validators.validateConfirmPassword(
        newPassword,
        confirmPassword,
        l10n: runtimeL10n(),
      );
      if (confirmError != null) {
        throw Exception(confirmError);
      }

      await _authRepo.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      return true;
    });

    return result ?? false;
  }

  Future<void> resetPassword({
    required String resetSessionToken,
    required String newPassword,
  }) async {
    await _runAuthAction<void>(() async {
      await _authRepo.resetPassword(
        resetSessionToken: resetSessionToken,
        newPassword: newPassword,
      );
    });
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _error = null;

    var shouldCleanupAuthState = false;

    try {
      final cred = await _authRepo.register(email: email, password: password);
      final user = cred.user;
      if (user == null) {
        throw Exception("User null");
      }

      shouldCleanupAuthState = true;

      await _userRepo.createParentIfMissing(
        uid: user.uid,
        email: user.email ?? email,
      );

      await _otpRepo.requestEmailOtp();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e);
      return false;
    } on FirebaseFunctionsException catch (e) {
      _error = _mapFunctionsError(e);
      return false;
    } on Exception catch (e) {
      _error = e.toString().replaceFirst("Exception: ", "");
      return false;
    } catch (_) {
      _error = runtimeL10n().authGenericError;
      return false;
    } finally {
      if (_error != null && shouldCleanupAuthState) {
        await _safeCleanupAuthState();
      }
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _safeCleanupAuthState();
    } catch (e) {
      _error = e.toString();
      debugPrint("Logout error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<T?> _runAuthAction<T>(Future<T> Function() action) async {
    _setLoading(true);
    _error = null;

    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      debugPrint("AUTH ERROR (Firebase): $e");
      _error = _mapFirebaseError(e);
      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint("AUTH ERROR (Functions): $e");
      _error = _mapFunctionsError(e);
      return null;
    } on Exception catch (e) {
      debugPrint("AUTH ERROR (Exception): $e");
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

  Future<void> _safeCleanupAuthState() async {
    await _authRepo.logout();
    await FcmPushReceiverService.onSignedOut();
    await _storage.clearAuthData();
    _user = null;
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

  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'resource-exhausted':
        return runtimeL10n().otpTooManyAttempts;
      case 'failed-precondition':
        return runtimeL10n().authSendOtpFailed;
      case 'unauthenticated':
        return runtimeL10n().authLoginRequired;
      case 'invalid-argument':
        return runtimeL10n().authGenericError;
      default:
        return runtimeL10n().authGenericError;
    }
  }

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
    // Intentionally left disabled until Apple Sign-In is configured.
  }

  Future<void> loginWithPhone() async {
    // Intentionally left disabled until phone auth flow is configured.
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
      final resolvedTimeZone = await DeviceTimeZoneService.instance
          .getDeviceTimeZone();

      if (existingUser == null) {
        await _userRepo.createParentIfMissing(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          locale: user.locale ?? 'vi',
          timezone: user.timezone ?? resolvedTimeZone,
          isActive: true,
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
