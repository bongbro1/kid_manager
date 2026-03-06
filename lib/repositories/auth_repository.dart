import 'package:kid_manager/background/foreground_watcher.dart';
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
    RealtimeAppMonitor.stop();
    await _authService.signOut();
  }
}
