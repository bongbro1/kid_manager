import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final List<AppNotification> _paged = [];
  List<AppNotification> get notifications => _notifications;
  final int _maxCountInPage = 20;
  Timestamp? _lastCreatedAt;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  NotificationFilter _activeFilter = NotificationFilter.all;
  NotificationFilter get activeFilter => _activeFilter;

  String _searchKeyword = "";
  String get searchKeyword => _searchKeyword;

  NotificationDetailModel? notificationDetail;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _uid; // ✅ lưu uid đang listen

  /// ==============================
  /// 🔢 UNREAD COUNT
  /// ==============================
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  StreamSubscription? _unreadSub;

  /// ==============================
  /// 📡 START LISTEN
  /// ==============================

  // void listen(String uid) {
  //   listenMulti(
  //     uid: uid,
  //     sources: const [NotificationSource.userInbox, NotificationSource.global],
  //   );
  // }


  Future<void> listenMulti({
    required String uid,
    required List<NotificationSource> sources,
    NotificationPredicate? filter,
  }) async {
    _uid = null;
    await _cancelAll();
    _resetState();
    _uid = uid;
    _loading = true;
    _error = null;

    notifyListeners();

    // lắng nghe số lượng thông báo
    _unreadSub?.cancel();
    _unreadSub = _repo.watchUnreadCount(uid).listen((count) {
      if (_uid != uid) return;
      _unreadCount = count;
      notifyListeners();
    });

    for (final src in sources) {
      final sub = _repo.watchBySource(uid, src).listen((list) {
        if (_uid != uid) return;
        _cache[src] = list;

        if (_lastCreatedAt == null && list.isNotEmpty) {
          _lastCreatedAt = Timestamp.fromDate(list.last.createdAt!);
        }

        _emitMerged(sources, filter);
      });

      _subs.add(sub);
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _lastCreatedAt == null || _uid == null)
      return;
    _loadingMore = true;
    try {
      final snap = await _repo.fetchOlderNotifications(
        uid: _uid!,
        lastCreatedAt: _lastCreatedAt!,
      );
      if (snap.docs.isEmpty) {
        _hasMore = false;
        return;
      }

      final more = snap.docs
          .map(
            (d) => AppNotification.fromMap(
              d.id,
              d.data(),
              store: NotificationStore.global,
            ),
          )
          .toList();

      final existingIds = {
        ..._notifications.map((e) => e.id),
        ..._paged.map((e) => e.id),
      };

      _paged.addAll(more.where((n) => !existingIds.contains(n.id)));
      _emitMerged(_cache.keys.toList(), null);
      _lastCreatedAt = Timestamp.fromDate(more.last.createdAt!);
      if (snap.docs.length < _maxCountInPage) {
        _hasMore = false;
      }

      debugPrint(
        "📊 Total notifications now = ${_notifications.length}"
        " newLastCreatedAt=$_lastCreatedAt",
      );
    } catch (e) {
      debugPrint("loadMore error: $e");
    } finally {
      _loadingMore = false;
    }
  }

  void setFilter(NotificationFilter filter) {
    _activeFilter = filter;
    _emitMerged(_cache.keys.toList(), null);
  }

  List<AppNotification> _applyFilter(List<AppNotification> list) {
    if (_activeFilter == NotificationFilter.all) {
      return list;
    }

    return list.where((n) {
      final type = n.notificationType;
      return type.filter == _activeFilter;
    }).toList();
  }

  void setSearch(String keyword) {
    _searchKeyword = keyword.trim().toLowerCase();

    _emitMerged(_cache.keys.toList(), null);
  }

  List<AppNotification> _applySearch(List<AppNotification> list) {
    if (_searchKeyword.isEmpty) return list;

    return list.where((n) {
      final title = (n.title).toLowerCase();
      final body = (n.body).toLowerCase();

      return title.contains(_searchKeyword) || body.contains(_searchKeyword);
    }).toList();
  }

  Future<void> _emitMerged(
    List<NotificationSource> sources,
    NotificationPredicate? filter,
  ) async {
    final all = <AppNotification>[];

    for (final src in sources) {
      all.addAll(_cache[src] ?? const []);
    }

    // merge realtime + paged
    final merged = [...all, ..._paged];

    // dedup
    final seen = <String>{};
    final dedup = <AppNotification>[];

    for (final n in merged) {
      if (seen.add(n.id)) {
        dedup.add(n);
      }
    }

    // sort trước
    dedup.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    // apply filter/search sau cùng
    var result = dedup;

    if (filter != null) {
      result = result.where(filter).toList();
    }

    result = _applyFilter(result);
    result = _applySearch(result);

    _notifications = result;

    _loading = false;
    notifyListeners();
  }

  Future<void> loadNotificationDetailItem(AppNotification n) async {
    try {
      _loading = true;
      notifyListeners();

      notificationDetail = await _repo.getNotificationDetailByItem(_uid, n);
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

  Future<void> loadNotificationDetail(String id, AppNotification n) async {
    try {
      _loading = true;
      notifyListeners();
      notificationDetail = await _repo.getNotificationDetailByItem(id, n);
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

    try {
      debugPrint("🔎 markAsRead store=${n.store} vmUid=$uid notifId=${n.id}");

      if (n.store == NotificationStore.userInbox) {
        await _repo.markAsReadInbox(uid, n.id);
      } else {
        await _repo.markAsReadGlobal(n.id);
      }
    } catch (e) {
      debugPrint("❌ markAsRead error: $e");
      rethrow;
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

  Future<void> clear() async {
    _uid = null; // chặn event cũ ngay lập tức
    await _cancelAll();
    _resetState();
    notifyListeners();
  }

  Future<void> _cancelAll() async {
    final futures = <Future<void>>[];

    for (final s in _subs) {
      futures.add(s.cancel());
    }
    _subs.clear();

    if (_unreadSub != null) {
      futures.add(_unreadSub!.cancel());
      _unreadSub = null;
    }

    await Future.wait(futures);
    _cache.clear();
  }

  void _resetState() {
    _notifications = [];
    _paged.clear();
    _cache.clear();

    _lastCreatedAt = null;
    _hasMore = true;
    _loadingMore = false;

    _activeFilter = NotificationFilter.all;
    _searchKeyword = "";

    notificationDetail = null;

    _loading = false;
    _error = null;

    _unreadCount = 0;
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
