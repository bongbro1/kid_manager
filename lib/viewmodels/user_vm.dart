import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/repositories/user_repository.dart';

class UserVm extends ChangeNotifier {
  final UserRepository _userRepo;

  UserVm(this._userRepo);

  /* ============================================================
     GENERAL STATE
  ============================================================ */

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }

  /* ============================================================
     CHILDREN (USER DOMAIN)
  ============================================================ */

  final List<AppUser> _children = [];
  List<AppUser> get children => _children;

  List<String> get childrenIds =>
      _children.map((c) => c.uid).toList();

  StreamSubscription<List<AppUser>>? _childrenSub;

  void watchChildren(String parentUid) {
    _childrenSub?.cancel();
    _childrenSub = _userRepo.watchChildren(parentUid).listen(
          (list) {
        debugPrint('USER_VM children=${list.length}');
        _children
          ..clear()
          ..addAll(list);
        notifyListeners();
      },
      onError: (e) => _setError('Lỗi load children: $e'),
    );
  }

  /* ============================================================
     CREATE CHILD
  ============================================================ */

  Future<bool> createChildAccount({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    required String locale,
    required String timezone,
  }) async {
    try {
      _setLoading(true);

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final childUid = cred.user!.uid;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(childUid)
          .set({
        "uid": childUid,
        "email": email,
        "displayName": displayName,
        "parentUid": parentUid,
        "role": "child",
        "dob": dob?.millisecondsSinceEpoch,
        "locale": locale,
        "timezone": timezone,
        "createdAt": FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e, s) {
      debugPrint('CreateChildAccount error: $e');
      debugPrintStack(stackTrace: s);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _childrenSub?.cancel();
    super.dispose();
  }
}
