import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/app_user.dart';
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
        return await _users.getUserById(fbUser.uid);
      } catch (e, st) {
        debugPrint('[AuthRepository] watchSessionUser error: $e');
        debugPrintStack(stackTrace: st);
        return null;
      }
    });
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

  Future<void> logout() async {
    try {
      final installationId = await FcmInstallationService.getInstallationId();

      await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('unregisterFcmToken')
          .call({
        'installationId': installationId,
      });
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
}
