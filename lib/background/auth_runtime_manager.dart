import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/background/native_watcher_service.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';

enum _RuntimeState { stopped, starting, running, stopping }

class AuthRuntimeManager {
  static StreamSubscription<User?>? _sub;

  static _RuntimeState _state = _RuntimeState.stopped;
  static String? _currentUid;

  /// Prevent race condition
  static int _opToken = 0;
  static String? _lastAuthUid;
  static String? _parentId;
  static String? _displayName;

  static void start({required String parentId, required String displayName}) {
    _parentId = parentId;
    _displayName = displayName;
    _sub?.cancel();

    User? lastUser;

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final sameUser = lastUser?.uid == user?.uid;

      // Ignore duplicate event for same uid
      if (sameUser) return;

      lastUser = user;
      _handleAuthChanged(user);
    });
  }

  static Future<void> stop() async {
    _opToken++; // cancel pending login flow
    await _safeLogout(_opToken);
  }

  static Future<void> _handleAuthChanged(User? user) async {
    final token = ++_opToken;

    final newUid = user?.uid;

    // 🔒 Prevent auth refresh restart
    if (newUid != null &&
        _lastAuthUid == newUid &&
        _state == _RuntimeState.running) {
      return;
    }

    _lastAuthUid = newUid;

    if (user == null) {
      await _safeLogout(token);
    } else {
      await _safeLogin(user.uid, token);
    }
  }

  // ================= LOGIN =================

  static Future<void> _safeLogin(String uid, int token) async {
    if (_state == _RuntimeState.running && _currentUid == uid) {
      final running = await NativeWatcherService.isWatcherRunning();
      if (running) {
        debugPrint("🟡 Runtime already running and watcher alive");
        return;
      }
    }

    if (_state == _RuntimeState.starting) return;

    _state = _RuntimeState.starting;
    _currentUid = uid;

    debugPrint("🟢 Runtime starting for $uid");

    try {
      if (token != _opToken) return;

      await FcmPushReceiverService.init(uid);

      if (token != _opToken) return;

      if (_parentId != null && _displayName != null) {
        final running = await NativeWatcherService.isWatcherRunning();

        if (!running) {
          final ok = await NativeWatcherService.startWatcher(
            userId: uid,
            parentId: _parentId,
            childName: _displayName,
          );

          debugPrint(
            ok
                ? "✅ Native watcher started"
                : "❌ Native watcher failed to start",
          );
        } else {
          debugPrint("🟡 Native watcher already running");
        }
      }

      if (token != _opToken) return;

      _state = _RuntimeState.running;
      debugPrint("✅ Runtime running");
    } catch (e) {
      debugPrint("❌ Runtime start failed: $e");
      _state = _RuntimeState.stopped;
    }
  }

  // ================= LOGOUT =================

  static Future<void> _safeLogout(int token) async {
    /// already stopped
    if (_state == _RuntimeState.stopped || _state == _RuntimeState.stopping)
      return;

    _state = _RuntimeState.stopping;

    debugPrint("🔴 Runtime stopping");

    try {
      if (token != _opToken) return;

      await NativeWatcherService.stopWatcher();
    } catch (e) {
      debugPrint("❌ Runtime stop error: $e");
    }

    if (token != _opToken) return;
    _parentId = null;
    _currentUid = null;
    _state = _RuntimeState.stopped;

    debugPrint("⛔ Runtime stopped");
  }

  static Future<void> dispose() async {
    _sub?.cancel();
    _sub = null;
    _opToken++; // cancel pending flows
    await _safeLogout(_opToken);
  }
}
