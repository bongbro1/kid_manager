import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword({
    required String uid,
    required String newPassword,
  }) async {
    final callable = _functions.httpsCallable("resetUserPassword");

    await callable.call({"uid": uid, "newPassword": newPassword});
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception("Bạn chưa đăng nhập");
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );

      /// 1️⃣ re-authenticate
      await user.reauthenticateWithCredential(credential);

      /// 2️⃣ update password
      await user.updatePassword(newPassword);

      /// 3️⃣ reload
      await user.reload();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "wrong-password":
        case "invalid-credential":
          throw Exception("Mật khẩu hiện tại không đúng");

        case "user-mismatch":
          throw Exception("Tài khoản xác thực không khớp");

        case "user-not-found":
          throw Exception("Tài khoản không tồn tại");

        case "too-many-requests":
          throw Exception("Bạn thử sai quá nhiều lần. Vui lòng thử lại sau");

        case "network-request-failed":
          throw Exception("Lỗi kết nối mạng. Vui lòng kiểm tra Internet");

        case "requires-recent-login":
          throw Exception("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại");

        default:
          throw Exception("Không thể đổi mật khẩu. Vui lòng thử lại");
      }
    }
  }

  Future<void> signOut() => _auth.signOut();
}
