import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/repositories/notification_repository.dart';

class NotificationVM extends ChangeNotifier {
  final NotificationRepository _repo;

  NotificationVM(this._repo);
  StreamSubscription? _sub;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;
  NotificationDetailModel? notificationDetail;

  bool _loading = false;
  bool get loading => _loading;

  

  /// ==============================
  /// 🔢 UNREAD COUNT
  /// ==============================
  int get unreadCount => _notifications.where((e) => !e.isRead).length;

  /// ==============================
  /// 📡 START LISTEN
  /// ==============================

  void listen(String uid) {
    _sub?.cancel(); // cancel trước

    _loading = true;
    notifyListeners();

    _sub = _repo
        .streamUserNotifications(uid)
        .listen(
          (data) {
            _notifications = data;
            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Notification stream error: $e");
          },
        );
  }

  Future<void> refresh() async {
    // có thể chỉ delay nhẹ cho UI
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> loadNotificationDetail(String id) async {
    try {
      _loading = true;
      notifyListeners();

      /// Call API / Repository
      final result = await _repo.getNotificationDetail(id);

      notificationDetail = result;
    } catch (e) {
      debugPrint("Load notification detail error: $e");
      notificationDetail = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
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
