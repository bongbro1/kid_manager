import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';

enum LocationSharingStatus { idle, sharing, paused, error }

class ParentLocationVm extends ChangeNotifier {
  final LocationRepository _locationRepo;
  final LocationServiceInterface _locationService;

  ParentLocationVm(this._locationRepo, this._locationService);

  /* ============================================================
     STATE
  ============================================================ */

  LocationData? _myLocation;
  LocationData? get myLocation => _myLocation;

  StreamSubscription<LocationData>? _myGpsSub;

  LocationSharingStatus _status = LocationSharingStatus.idle;
  LocationSharingStatus get status => _status;

  final Set<String> _watchingIds = {};

  bool _readyForInitialFocus = false;
  bool get readyForInitialFocus => _readyForInitialFocus;

  String? _error;
  String? get error => _error;

  void _setError(String msg) {
    _error = msg;
    _status = LocationSharingStatus.error;
    notifyListeners();
  }

  /* ============================================================
     LOCATION DATA
  ============================================================ */

  Map<String, LocationData> get childrenLocations =>
      Map.unmodifiable(_childrenLocations);

  final Map<String, LocationData> _childrenLocations = {};

  final Map<String, List<LocationData>> _childrenTrails = {};
  Map<String, List<LocationData>> get childrenTrails => _childrenTrails;

  final Map<String, StreamSubscription<LocationData>> _subs = {};

  Future<void> startMyLocation() async {
    try {
      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: false,
      );
      if (!ok) {
        _setError('noLocationPermission');
        return;
      }

      await _myGpsSub?.cancel();
      _myGpsSub = _locationService.getLocationStream().listen((loc) {
        // loc của bạn đang là LocationData luôn thì ok,
        // nếu stream trả raw thì map sang LocationData
        _myLocation = loc;
        notifyListeners();
      }, onError: (e) => _setError('Lỗi GPS: $e'));
    } catch (e) {
      _setError('Lỗi bật GPS: $e');
    }
  }

  Future<LocationData?> getMyLocationOnce({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: false,
      );
      if (!ok) {
        _setError('noLocationPermission');
        return null;
      }

      // lấy 1 điểm đầu tiên từ stream
      final loc = await _locationService.getLocationStream().first.timeout(
        timeout,
      );

      _myLocation = loc;
      notifyListeners();
      return loc;
    } catch (e) {
      _setError('Không lấy được vị trí hiện tại: $e');
      return null;
    }
  }

  Future<void> stopMyLocation() async {
    await _myGpsSub?.cancel();
    _myGpsSub = null;
  }
  /* ============================================================
     WATCHING
  ============================================================ */

  Stream<LocationData> watchChildLocation(String childId) =>
      _locationRepo.watchChildLocation(childId);

  Future<void> syncWatching(List<String> newChildIds) async {
    final newSet = newChildIds.toSet();
    if (setEquals(newSet, _watchingIds)) return;

    if (kDebugMode) {
      debugPrint('SYNC WATCH CALLED size=${newSet.length}');
      debugPrint('SYNC WATCHING: $newSet');
    }
    // ==============================
    // 1️⃣ Unwatch child bị xoá
    // ==============================
    final removed = _watchingIds.difference(newSet);

    for (final id in removed) {
      await _subs[id]?.cancel();
      _subs.remove(id);
      _childrenLocations.remove(id);
      _childrenTrails.remove(id);
      if (kDebugMode) debugPrint('🛑 Unwatched $id');
    }

    // ==============================
    // 2️⃣ Watch child mới
    // ==============================
    final added = newSet.difference(_watchingIds);

    for (final id in added) {
      _subscribeChild(id);
      if (kDebugMode) debugPrint('👀 Watching $id');
    }

    _watchingIds
      ..clear()
      ..addAll(newSet);

    _status = LocationSharingStatus.sharing;
    notifyListeners();
  }

  Future<void> stopWatchingChild(String childId) async {
    await _subs[childId]?.cancel();
    _subs.remove(childId);
    _childrenLocations.remove(childId);
    _childrenTrails.remove(childId);
    notifyListeners();
  }

  Future<void> stopWatchingAllChildren() async {
    for (final s in _subs.values) {
      await s.cancel();
    }
    _subs.clear();
    _childrenLocations.clear();
    _childrenTrails.clear();

    _status = LocationSharingStatus.paused;
    notifyListeners();
  }

  /* ============================================================
     HISTORY + STATS
  ============================================================ */

  Future<List<LocationData>> loadLocationHistoryByDay(
    String childUid,
    DateTime day, {
    int? fromTs,
    int? toTs,
  }
  ) async {
    try {
      final history = await _locationRepo.getLocationHistoryByDay(
        childUid,
        day,
        fromTs: fromTs,
        toTs: toTs,
      );
      final valid = history.where(_isValidLocation).toList();

      _childrenTrails[childUid] = valid;
      if (valid.isNotEmpty) _childrenLocations[childUid] = valid.last;
      notifyListeners();
      return valid;
    } catch (e) {
      _setError('Lỗi tải lịch sử: $e');
      return [];
    }
  }

  Map<String, dynamic> getChildLocationStats(String childId) {
    final trail = _childrenTrails[childId] ?? [];
    if (trail.isEmpty) return {};

    double totalDistance = 0;
    for (int i = 1; i < trail.length; i++) {
      totalDistance += trail[i - 1].distanceTo(trail[i]);
    }

    return {
      'totalPoints': trail.length,
      'totalDistance': totalDistance,
      'firstLocation': trail.first,
      'lastLocation': trail.last,
      'timeSpan': trail.last.timestamp - trail.first.timestamp,
    };
  }

  /* ============================================================
     UTILS
  ============================================================ */

  bool _isValidLocation(LocationData loc) {
    return loc.latitude.isFinite &&
        loc.longitude.isFinite &&
        loc.latitude >= -90 &&
        loc.latitude <= 90 &&
        loc.longitude >= -180 &&
        loc.longitude <= 180;
  }

  void _subscribeChild(String childId) {
    if (_subs.containsKey(childId)) return;

    _childrenTrails.putIfAbsent(childId, () => []);

    final sub = _locationRepo.watchChildLocation(childId).listen((loc) {
      if (!_isValidLocation(loc)) return;

      _childrenLocations[childId] = loc;

      final trail = _childrenTrails[childId]!;
      if (trail.isEmpty || trail.last.timestamp != loc.timestamp) {
        trail.add(loc);
        if (trail.length > 300) {
          trail.removeRange(0, trail.length - 300);
        }
      }

      if (!_readyForInitialFocus) {
        _readyForInitialFocus = true;
      }

      notifyListeners();
    }, onError: (e) => _setError('Lỗi theo dõi $childId: $e'));

    _subs[childId] = sub;
  }

  bool isChildOnline(String childId, {int thresholdSeconds = 30}) {
    final loc = _childrenLocations[childId];
    if (loc == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - loc.timestamp;

    return diff <= thresholdSeconds * 1000;
  }

  @override
  void dispose() {
    for (final s in _subs.values) {
      s.cancel();
    }
    _myGpsSub?.cancel();
    super.dispose();
  }
}
