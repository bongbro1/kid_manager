import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_notification.dart';
import 'package:kid_manager/repositories/notification_repository.dart';

class NotificationVM extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationVM(this._repo);

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Stream<List<AppNotification>>? _stream;

  /// ==============================
  /// 📡 START LISTEN
  /// ==============================
  void listen(String uid) {
    _isLoading = true;
    notifyListeners();

    _stream = _repo.streamUserNotifications(uid);

    _stream!.listen((data) {
      _notifications = data;
      _isLoading = false;
      notifyListeners();
    });
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
  int get unreadCount =>
      _notifications.where((e) => !e.isRead).length;
}