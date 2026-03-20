import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

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
    final l10n = runtimeL10n();
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception(l10n.authLoginRequired);
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
          throw Exception(l10n.firebaseAuthCurrentPasswordIncorrect);

        case "user-mismatch":
          throw Exception(l10n.firebaseAuthUserMismatch);

        case "user-not-found":
          throw Exception(l10n.accountNotFound);

        case "too-many-requests":
          throw Exception(l10n.firebaseAuthTooManyRequests);

        case "network-request-failed":
          throw Exception(l10n.firebaseAuthNetworkFailed);

        case "requires-recent-login":
          throw Exception(l10n.sessionExpiredLoginAgain);

        default:
          throw Exception(l10n.firebaseAuthChangePasswordFailed);
      }
    }
  }

  Future<void> signOut() => _auth.signOut();
}
