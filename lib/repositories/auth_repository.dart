import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/background/native_watcher_service.dart';
import 'package:kid_manager/models/app_user.dart';
import '../services/firebase_auth_service.dart';
import 'user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuthService _authService;
  final UserRepository _users;

  AuthRepository(this._authService, this._users);

  // ===== Auth state =====
  Stream<User?> authStateChanges() => _authService.authStateChanges();

  User? currentUser() => _authService.currentUser;
  Stream<AppUser?> watchSessionUser() {
    return authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;

      // Lấy AppUser từ Firestore
      final appUser = await _users.getUserById(fbUser.uid);
      return appUser;
    });
  }

  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  }) {
    return _authService.resetPassword(uid: uid, newPassword: newPassword);
  }

  // ===== Actions =====
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
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null && token.isNotEmpty) {
        await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
            .httpsCallable('unregisterFcmToken')
            .call({
          'token': token,
        });
      }
    } catch (e, st) {
      debugPrint('[AuthRepository] unregisterFcmToken error: $e');
      debugPrintStack(stackTrace: st);
    }

    await _authService.signOut();
  }

  Future<void> registerCurrentFcmToken({
    required String platform,
  }) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[AuthRepository] registerCurrentFcmToken token=$token');

      if (token == null || token.isEmpty) return;

      await FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('registerFcmToken')
          .call({
        'token': token,
        'platform': platform,
      });

      debugPrint('[AuthRepository] registerFcmToken success');
    } catch (e, st) {
      debugPrint('[AuthRepository] registerFcmToken error: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
