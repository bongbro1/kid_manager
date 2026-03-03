import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_notification.dart';
import 'package:kid_manager/repositories/notification_repository.dart';

class NotificationVM extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationVM(this._repo);
  StreamSubscription? _sub;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// ==============================
  /// 📡 START LISTEN
  /// ==============================
  void listen(String uid) {
    _sub?.cancel(); // cancel trước

    _isLoading = true;
    notifyListeners();

    _sub = _repo
        .streamUserNotifications(uid)
        .listen(
          (data) {
            _notifications = data;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Notification stream error: $e");
          },
        );
  }

  /// ==============================
  /// ✅ MARK AS READ
  /// ==============================
  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
  }

  /// ==============================
  /// 🗑 DELETE
  /// ==============================
  Future<void> delete(String id) async {
    await _repo.delete(id);
  }

  /// ==============================
  /// 🔢 UNREAD COUNT
  /// ==============================
  int get unreadCount => _notifications.where((e) => !e.isRead).length;


void clear() {
  _sub?.cancel();
  _sub = null;
  _notifications = [];
  notifyListeners();
}

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
