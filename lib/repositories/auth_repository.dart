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
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<AppUser?>? profileSub;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = authStateChanges().listen(
          (fbUser) {
            profileSub?.cancel();
            profileSub = null;

            if (fbUser == null) {
              if (!controller.isClosed) {
                controller.add(null);
              }
              return;
            }

            profileSub = _users.watchUserById(fbUser.uid).listen(
              (user) {
                if (!controller.isClosed) {
                  controller.add(_mapSessionUser(fbUser: fbUser, user: user));
                }
              },
              onError: (e, st) {
                debugPrint('[AuthRepository] watchSessionUser error: $e');
                debugPrintStack(stackTrace: st);

                if (controller.isClosed) {
                  return;
                }

                if (_isEmailPasswordUser(fbUser)) {
                  controller.add(null);
                } else {
                  controller.add(AppUser.fromFirebase(fbUser));
                }
              },
            );
          },
          onError: (e, st) {
            if (!controller.isClosed) {
              controller.addError(e, st);
            }
          },
          onDone: () {
            profileSub?.cancel();
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );
      },
      onCancel: () async {
        await profileSub?.cancel();
        await authSub?.cancel();
      },
    );

    return controller.stream;
  }

  AppUser? _mapSessionUser({
    required User fbUser,
    required AppUser? user,
  }) {
    if (user == null) {
      debugPrint('[AuthRepository] Firestore user missing -> fallback Firebase');
      if (_isEmailPasswordUser(fbUser)) {
        return null;
      }
      return AppUser.fromFirebase(fbUser);
    }

    if (!user.isActive && _isEmailPasswordUser(fbUser)) {
      return null;
    }

    return user;
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

  Future<void> sendOtpSms(
    String phone,
    Function(String verificationId) onCodeSent,
  ) async {
    final completer = Completer<void>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint("PHONE verificationCompleted");
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint("PHONE verificationFailed: ${e.code} - ${e.message}");
        if (!completer.isCompleted) {
          completer.completeError(Exception("${e.code}: ${e.message}"));
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
