import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kid_manager/background/tracking_background_service.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/services/firebase_auth_service.dart';
import 'package:kid_manager/services/notifications/fcm_installation_service.dart';

import 'user_repository.dart';

class AuthRepository {
  AuthRepository(this._authService, this._users);

  final FirebaseAuthService _authService;
  final UserRepository _users;

  Stream<User?> authStateChanges() => _authService.authStateChanges();

  User? currentUser() => _authService.currentUser;

  Stream<AppUser?> watchSessionUser() {
    return authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        return null;
      }

      try {
        final user = await _users.getUserById(fbUser.uid);

        if (user == null) {
          debugPrint(
            '[AuthRepository] Firestore user missing -> fallback Firebase',
          );
          if (_isEmailPasswordUser(fbUser)) {
            return null;
          }
          return AppUser.fromFirebase(fbUser);
        }

        if (!user.isActive && _isEmailPasswordUser(fbUser)) {
          return null;
        }

        return user;
      } catch (e, st) {
        debugPrint('[AuthRepository] watchSessionUser error: $e');
        debugPrintStack(stackTrace: st);

        if (_isEmailPasswordUser(fbUser)) {
          return null;
        }

        return AppUser.fromFirebase(fbUser);
      }
    });
  }

  Future<AppUser?> getUser(String uid) async {
    return _users.getUserById(uid);
  }

  Future<void> resetPassword({
    required String resetSessionToken,
    required String newPassword,
  }) {
    return _authService.resetPassword(
      resetSessionToken: resetSessionToken,
      newPassword: newPassword,
    );
  }

  Future<UserCredential> login(String email, String password) {
    return _authService.signIn(email.trim(), password);
  }

  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    final cred = await _authService.signUp(email.trim(), password);
    return cred;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return _authService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() async {
    await TrackingBackgroundService.stop();

    final currentUser = _authService.currentUser;

    if (currentUser != null) {
      try {
        final installationId = await FcmInstallationService.getInstallationId();

        await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
            .httpsCallable('unregisterFcmToken')
            .call({'installationId': installationId});
      } on FirebaseFunctionsException catch (e, st) {
        if (e.code == 'unauthenticated') {
          if (kDebugMode) {
            debugPrint(
              '[AuthRepository] unregisterFcmToken skipped: auth already expired during logout.',
            );
          }
        } else {
          debugPrint(
            '[AuthRepository] unregisterFcmToken fail '
            'code=${e.code} message=${e.message} details=${e.details}',
          );
          debugPrintStack(stackTrace: st);
        }
      } catch (e, st) {
        debugPrint('[AuthRepository] unregisterFcmToken error: $e');
        debugPrintStack(stackTrace: st);
      }
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      debugPrint('[AuthRepository] deleteToken error: $e');
      debugPrintStack(stackTrace: st);
    }

    await _authService.signOut();
  }

  Future<AppUser?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      return null;
    }

    return AppUser.fromFirebase(firebaseUser);
  }

  Future<AppUser?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();

    if (result.status != LoginStatus.success) {
      return null;
    }

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.token,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final user = userCredential.user;
    if (user == null) {
      return null;
    }

    return AppUser.fromFirebase(user);
  }

  String? _verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _normalizePhoneForFirebase(String phone) {
    final trimmed = phone.trim();
    if (trimmed.startsWith('00')) {
      return '+${trimmed.substring(2).replaceAll(_phoneFormattingRegExp, '')}';
    }
    if (trimmed.startsWith('+')) {
      return '+${trimmed.substring(1).replaceAll(_phoneFormattingRegExp, '')}';
    }
    return trimmed.replaceAll(_phoneFormattingRegExp, '');
  }

  String _mapPhoneAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'too-many-requests':
        return 'too-many-requests: We have blocked OTP requests from this device temporarily. Please try again later.';
      case 'invalid-phone-number':
        return 'invalid-phone-number: The phone number must be in E.164 format, for example +84973564344.';
      case 'app-not-authorized':
        return 'app-not-authorized: Firebase Phone Auth is not authorized for Android package com.example.kid_manager. Verify the package name, SHA-1, and SHA-256 in Firebase Console.';
      default:
        return '${error.code}: ${error.message}';
    }
  }

  Future<void> sendOtpSms(
    String phone,
    Function(String verificationId) onCodeSent,
  ) async {
    final completer = Completer<void>();
    final normalizedPhone = _normalizePhoneForFirebase(phone);

    if (!_e164PhoneRegExp.hasMatch(normalizedPhone)) {
      throw Exception(
        'invalid-phone-number: The phone number must be in E.164 format, for example +84973564344.',
      );
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: normalizedPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint("PHONE verificationCompleted");
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("PHONE verificationFailed: ${e.code} - ${e.message}");
        if (!completer.isCompleted) {
          completer.completeError(Exception(_mapPhoneAuthError(e)));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint("PHONE codeSent: $verificationId");
        _verificationId = verificationId;
        onCodeSent(verificationId);

        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint("PHONE timeout: $verificationId");
        _verificationId = verificationId;
      },
    );

    return completer.future;
  }

  Future<AppUser?> verifyOtpSms(String smsCode) async {
    if (_verificationId == null) {
      throw Exception("VerificationId null");
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: smsCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      return null;
    }

    return AppUser.fromFirebase(firebaseUser);
  }

  bool _isEmailPasswordUser(User user) {
    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }
}
