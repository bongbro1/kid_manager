import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/firebase_auth_service.dart';
import 'package:kid_manager/services/notifications/fcm_installation_service.dart';

import 'user_repository.dart';

class AuthRepository {
  final FirebaseAuthService _authService;
  final UserRepository _users;

  AuthRepository(this._authService, this._users);

  Stream<User?> authStateChanges() => _authService.authStateChanges();

  User? currentUser() => _authService.currentUser;

  Stream<AppUser?> watchSessionUser() {
    return authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;

      try {
        final user = await _users.getUserById(fbUser.uid);

        /// 🔹 nếu Firestore chưa có user
        if (user == null) {
          debugPrint(
            '[AuthRepository] Firestore user missing → fallback Firebase',
          );
          return AppUser.fromFirebase(fbUser);
        }

        return user;
      } catch (e, st) {
        debugPrint('[AuthRepository] watchSessionUser error: $e');
        debugPrintStack(stackTrace: st);

        /// 🔹 fallback để SessionVM vẫn authenticated
        return AppUser.fromFirebase(fbUser);
      }
    });
  }

  Future<AppUser?> getUser(String uid) async {
    return await _users.getUserById(uid);
  }

  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  }) {
    return _authService.resetPassword(uid: uid, newPassword: newPassword);
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
    try {
      final installationId = await FcmInstallationService.getInstallationId();

      await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('unregisterFcmToken')
          .call({'installationId': installationId});
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        '[AuthRepository] unregisterFcmToken fail '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('[AuthRepository] unregisterFcmToken error: $e');
      debugPrintStack(stackTrace: st);
    }

    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e, st) {
      debugPrint('[AuthRepository] deleteToken error: $e');
      debugPrintStack(stackTrace: st);
    }

    await _authService.signOut();
  }

  // auth socials
  Future<AppUser?> signInWithGoogle() async {
    try {
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
    } catch (e) {
      rethrow;
    }
  }

  Future<AppUser?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();

    if (result.status != LoginStatus.success) return null;

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.token,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final user = userCredential.user;
    if (user == null) return null;

    return AppUser.fromFirebase(user);
  }

  String? _verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendOtpSms(
    String phone,
    Function(String verificationId) codeSent,
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        debugPrint("FirebaseAuthException: ${e.code} - ${e.message}");
        throw Exception(e.message);
      },

      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        codeSent(verificationId);
      },

      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// verify OTP
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

    if (firebaseUser == null) return null;

    return AppUser.fromFirebase(firebaseUser);
  }
}
