import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/repositories/notification_repository.dart';

typedef NotificationPredicate = bool Function(AppNotification n);

class NotificationVM extends ChangeNotifier {
  final NotificationRepository _repo;
  NotificationVM(this._repo);

  final List<StreamSubscription> _subs = [];
  final Map<NotificationSource, List<AppNotification>> _cache = {};

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  NotificationDetailModel? notificationDetail;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _uid; // ✅ lưu uid đang listen



  /// ==============================
  /// 🔢 UNREAD COUNT
  /// ==============================
  int get unreadCount => _notifications.where((e) => !e.isRead).length;

  /// ==============================
  /// 📡 START LISTEN
  /// ==============================

  void listen(String uid) {
    listenMulti(uid: uid, sources: const [NotificationSource.global]);
  }

  void listenMulti({
    required String uid,
    required List<NotificationSource> sources,
    NotificationPredicate? filter,
  }) {
    _uid = uid;

    _cancelAll();
    _loading = true;
    _error = null;
    notifyListeners();

    for (final src in sources) {
      final sub = _repo.watchBySource(uid, src).listen(
            (list) {
          debugPrint("📥 notif source=$src uid=$uid count=${list.length}"
              " latest=${list.isNotEmpty ? list.first.id : 'none'}");
          _cache[src] = list;
          _emitMerged(sources, filter);
        },
        onError: (e) {
          debugPrint("❌ notif source=$src error=$e");
          _error = e.toString();
          _loading = false;
          notifyListeners();
        },
      );
      _subs.add(sub);
    }
  }

  void _emitMerged(List<NotificationSource> sources, NotificationPredicate? filter) {
    final all = <AppNotification>[];
    for (final src in sources) {
      all.addAll(_cache[src] ?? const []);
    }

    final seen = <String>{};
    var dedup = <AppNotification>[];
    for (final n in all) {
      if (seen.add(n.id)) dedup.add(n);
    }

    if (filter != null) {
      dedup = dedup.where(filter).toList();
    }

    dedup.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    _notifications = dedup;
    _loading = false;
    notifyListeners();
  }


  Future<void> loadNotificationDetailItem(AppNotification n) async {
    try {
      _loading = true;
      notifyListeners();

      notificationDetail = await _repo.getNotificationDetailByItem(_uid!, n);
    } catch (e) {
      debugPrint("Load notification detail error: $e");
      notificationDetail = null;
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  Future<void> refresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> loadNotificationDetail(String id) async {
    try {
      _loading = true;
      notifyListeners();
      notificationDetail = await _repo.getNotificationDetail(id);
    } catch (e) {
      notificationDetail = null;
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ✅ auto đúng source: global vs userInbox
  Future<void> markAsRead(AppNotification n) async {
    final uid = _uid;
    if (uid == null) return;

    if (n.store == NotificationStore.userInbox) {
      await _repo.markAsReadInbox(uid, n.id);
    } else {
      await _repo.markAsReadGlobal(n.id);
    }
  }

  Future<void> delete(AppNotification n) async {
    final uid = _uid;
    if (uid == null) return;

    if (n.store == NotificationStore.userInbox) {
      await _repo.deleteInbox(uid, n.id);
    } else {
      await _repo.deleteGlobal(n.id);
    }
  }


  void clear() {
    _cancelAll();
    _notifications = [];
    notifyListeners();
  }

  void _cancelAll() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _cache.clear();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}