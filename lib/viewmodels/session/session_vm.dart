import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/auth_repository.dart';

class SessionVM extends ChangeNotifier {
  final AuthRepository _repo;

  SessionVM(this._repo) {
    _bootstrap();
  }

  AppUser? _user;
  AppUser? get user => _user;

  bool _splashDone = false;

  SessionStatus _authStatus = SessionStatus.booting;

  SessionStatus get status {
    if (!_splashDone) return SessionStatus.booting;
    return _authStatus;
  }

  StreamSubscription<AppUser?>? _sub;

  void _bootstrap() {
    _sub = _repo.watchSessionUser().listen(
      (user) {
        _user = user;
        _authStatus = user == null
            ? SessionStatus.unauthenticated
            : SessionStatus.authenticated;
        debugPrint("[SESSION_VM] user=${_user?.uid}");
        debugPrint("[SESSION_VM] status=$_authStatus");

        notifyListeners();
      },
      onError: (e) {
        _user = null;
        _authStatus = SessionStatus.unauthenticated;
        debugPrint('[SessionVM] auth stream error: $e');
        notifyListeners();
      },
    );
  }

  void finishSplash() {
    if (_splashDone) return;
    _splashDone = true;
    notifyListeners();
  }

  bool get isParent => _user?.role == UserRole.parent;
  bool get isChild => _user?.role == UserRole.child;
  bool get isGuardian => _user?.role == UserRole.guardian;
  bool get isLocationViewer => isParent || isGuardian;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
