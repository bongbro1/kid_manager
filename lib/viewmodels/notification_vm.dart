import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  List<NotificationSource> _sources = const [];

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

  NotificationReadFilter _activeReadFilter = NotificationReadFilter.all;
  NotificationReadFilter get activeReadFilter => _activeReadFilter;

  String _searchKeyword = "";
  String get searchKeyword => _searchKeyword;

  NotificationDetailModel? notificationDetail;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _uid;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  bool _markingAllRead = false;
  bool get markingAllRead => _markingAllRead;

  StreamSubscription? _unreadSub;
  bool _disposed = false;
  bool _notifyQueued = false;
  NotificationPredicate? _boundFilter;

  void _safeNotifyListeners() {
    if (_disposed) {
      return;
    }

    final schedulerPhase = WidgetsBinding.instance.schedulerPhase;
    final canNotifyNow =
        schedulerPhase == SchedulerPhase.idle ||
        schedulerPhase == SchedulerPhase.postFrameCallbacks;

    if (canNotifyNow) {
      notifyListeners();
      return;
    }

    if (_notifyQueued) {
      return;
    }

    _notifyQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyQueued = false;
      if (_disposed) return;
      notifyListeners();
    });
  }

  Future<void> bindUser({
    required String? uid,
    required List<NotificationSource> sources,
    NotificationPredicate? filter,
  }) async {
    if (_disposed) return;
    if (uid == null || uid.isEmpty) {
      await clear();
      return;
    }

    if (_uid == uid && _cache.isNotEmpty) return;

    await listenMulti(uid: uid, sources: sources, filter: filter);
  }

  Future<void> listenMulti({
    required String uid,
    required List<NotificationSource> sources,
    NotificationPredicate? filter,
  }) async {
    if (_disposed) return;
    _uid = null;
    await _cancelAll();
    _resetState();
    _uid = uid;
    _sources = List<NotificationSource>.from(sources);
    _boundFilter = filter;
    _loading = true;
    _error = null;

    _safeNotifyListeners();

    final previousUnreadSub = _unreadSub;
    if (previousUnreadSub != null) {
      unawaited(previousUnreadSub.cancel());
    }
    _unreadSub = _repo
        .watchUnreadCount(uid, sources: sources)
        .listen(
          (unreadValue) {
            if (_disposed || _uid != uid) return;
            _unreadCount = unreadValue;
            _safeNotifyListeners();
          },
          onError: (e) {
            if (_disposed || _uid != uid) return;
            _error = 'Notification unread stream error: $e';
            _unreadCount = 0;
            _safeNotifyListeners();
          },
        );

    for (final src in sources) {
      final sub = _repo
          .watchBySource(uid, src)
          .listen(
            (list) {
              if (_disposed || _uid != uid) return;
              _cache[src] = list;

              if (_lastCreatedAt == null && list.isNotEmpty) {
                _lastCreatedAt = Timestamp.fromDate(list.last.createdAt!);
              }

              unawaited(_emitMerged(sources, filter));
            },
            onError: (e) {
              if (_disposed || _uid != uid) return;
              _error = 'Notification stream error ($src): $e';
              _cache[src] = const [];
              unawaited(_emitMerged(sources, filter));
            },
          );

      _subs.add(sub);
    }
  }

  Future<void> loadMore() async {
    if (_disposed) return;
    if (_loadingMore || !_hasMore || _lastCreatedAt == null || _uid == null) {
      return;
    }

    _loadingMore = true;
    _safeNotifyListeners();

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
      await _emitMerged(_cache.keys.toList(), null);
      _lastCreatedAt = Timestamp.fromDate(more.last.createdAt!);

      if (snap.docs.length < _maxCountInPage) {
        _hasMore = false;
      }

      debugPrint(
        "📊 Total notifications now = ${_notifications.length} newLastCreatedAt=$_lastCreatedAt",
      );
    } catch (e) {
      debugPrint("loadMore error: $e");
    } finally {
      _loadingMore = false;
      _safeNotifyListeners();
    }
  }

  void setFilter(NotificationFilter filter) {
    _activeFilter = filter;
    _emitMerged(_cache.keys.toList(), null);
  }

  void setReadFilter(NotificationReadFilter filter) {
    _activeReadFilter = filter;
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

  List<AppNotification> _applyReadFilter(List<AppNotification> list) {
    switch (_activeReadFilter) {
      case NotificationReadFilter.all:
        return list;
      case NotificationReadFilter.unread:
        return list.where((n) => !n.isRead).toList();
      case NotificationReadFilter.read:
        return list.where((n) => n.isRead).toList();
    }
  }

  void setSearch(String keyword) {
    _searchKeyword = keyword.trim().toLowerCase();
    _emitMerged(_cache.keys.toList(), null);
  }

  List<AppNotification> _applySearch(List<AppNotification> list) {
    if (_searchKeyword.isEmpty) return list;

    return list.where((n) {
      final title = n.title.toLowerCase();
      final body = n.body.toLowerCase();
      return title.contains(_searchKeyword) || body.contains(_searchKeyword);
    }).toList();
  }

  Future<void> _emitMerged(
    List<NotificationSource> sources,
    NotificationPredicate? filter,
  ) async {
    if (_disposed) return;
    final all = <AppNotification>[];

    for (final src in sources) {
      all.addAll(_cache[src] ?? const []);
    }

    final merged = [...all, ..._paged];

    final seen = <String>{};
    final dedup = <AppNotification>[];

    for (final n in merged) {
      if (seen.add(n.id)) {
        dedup.add(n);
      }
    }

    dedup.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    var result = dedup;

    if (filter != null) {
      result = result.where(filter).toList();
    }

    result = _applyFilter(result);
    result = _applyReadFilter(result);
    result = _applySearch(result);

    _notifications = result;
    _loading = false;
    _safeNotifyListeners();
  }

  Future<void> loadNotificationDetailItem(AppNotification n) async {
    if (_disposed) return;
    try {
      _loading = true;
      _safeNotifyListeners();

      notificationDetail = await _repo.getNotificationDetailByItem(_uid, n);
    } catch (e) {
      debugPrint("Load notification detail error: $e");
      notificationDetail = null;
      _error = e.toString();
    } finally {
      _loading = false;
      _safeNotifyListeners();
    }
  }

  void prepareNotificationDetailLoad() {
    notificationDetail = null;
    _loading = true;
    _error = null;
    _safeNotifyListeners();
  }

  Future<void> refresh() async {
    final uid = _uid;
    final sources = List<NotificationSource>.from(_sources);

    if (_disposed || uid == null || sources.isEmpty) {
      return;
    }

    try {
      _error = null;

      final sourceResults = await Future.wait(
        sources.map(
          (source) => _repo.fetchBySource(
            uid,
            source,
            fetchSource: Source.serverAndCache,
          ),
        ),
      );
      final unreadCount = await _repo.fetchUnreadCount(
        uid,
        sources: sources,
        fetchSource: Source.serverAndCache,
      );

      for (var i = 0; i < sources.length; i++) {
        _cache[sources[i]] = sourceResults[i];
      }

      _paged.clear();
      _loadingMore = false;

      final globalItems = _cache[NotificationSource.global] ?? const [];
      _lastCreatedAt = globalItems.isNotEmpty
          ? Timestamp.fromDate(globalItems.last.createdAt ?? DateTime.now())
          : null;
      _hasMore =
          sources.contains(NotificationSource.global) &&
          globalItems.length >= _maxCountInPage;

      _unreadCount = unreadCount;

      await _emitMerged(sources, _boundFilter);
    } catch (e) {
      _error = 'Notification refresh error: $e';
      _safeNotifyListeners();
    }
  }

  Future<void> loadNotificationDetail(String id, AppNotification n) async {
    if (_disposed) return;
    try {
      _loading = true;
      _safeNotifyListeners();
      notificationDetail = await _repo.getNotificationDetailByItem(id, n);
    } catch (e) {
      notificationDetail = null;
      _error = e.toString();
    } finally {
      _loading = false;
      _safeNotifyListeners();
    }
  }

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
      if (!n.isRead) {
        _markLocalAsReadByIds({n.id});
        if (_unreadCount > 0) {
          _unreadCount -= 1;
        }
        _safeNotifyListeners();
      }
    } catch (e) {
      debugPrint("❌ markAsRead error: $e");
      rethrow;
    }
  }

  Future<int> markAllAsRead() async {
    final uid = _uid;
    if (uid == null || _markingAllRead) {
      return 0;
    }

    _markingAllRead = true;
    _safeNotifyListeners();

    try {
      final updatedCount = await _repo.markAllAsRead(
        uid: uid,
        sources: _sources,
      );

      if (updatedCount > 0) {
        _markAllLoadedAsRead();
        _unreadCount = (_unreadCount - updatedCount).clamp(0, _unreadCount);
        _safeNotifyListeners();
      }

      return updatedCount;
    } finally {
      _markingAllRead = false;
      _safeNotifyListeners();
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

  void _markLocalAsReadByIds(Set<String> ids) {
    if (ids.isEmpty) return;

    for (final entry in _cache.entries) {
      _cache[entry.key] = entry.value
          .map(
            (item) =>
                ids.contains(item.id) ? item.copyWith(isRead: true) : item,
          )
          .toList(growable: false);
    }

    for (var i = 0; i < _paged.length; i++) {
      final item = _paged[i];
      if (ids.contains(item.id)) {
        _paged[i] = item.copyWith(isRead: true);
      }
    }

    unawaited(_emitMerged(_sources, null));
  }

  void _markAllLoadedAsRead() {
    for (final entry in _cache.entries) {
      _cache[entry.key] = entry.value
          .map((item) => item.isRead ? item : item.copyWith(isRead: true))
          .toList(growable: false);
    }

    for (var i = 0; i < _paged.length; i++) {
      final item = _paged[i];
      if (!item.isRead) {
        _paged[i] = item.copyWith(isRead: true);
      }
    }

    unawaited(_emitMerged(_sources, null));
  }

  Future<void> clear() async {
    if (_disposed) return;
    _uid = null;
    await _cancelAll();
    _resetState();
    _safeNotifyListeners();
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
    _sources = const [];
    _notifications = [];
    _paged.clear();
    _cache.clear();

    _lastCreatedAt = null;
    _hasMore = true;
    _loadingMore = false;

    _activeFilter = NotificationFilter.all;
    _activeReadFilter = NotificationReadFilter.all;
    _searchKeyword = "";

    notificationDetail = null;

    _loading = false;
    _error = null;

    _unreadCount = 0;
    _markingAllRead = false;
    _boundFilter = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _uid = null;
    unawaited(_cancelAll());
    super.dispose();
  }
}
