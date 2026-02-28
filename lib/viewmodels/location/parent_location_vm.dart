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
        _setError('Không có quyền vị trí');
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
        _setError('Không có quyền vị trí');
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
    debugPrint("SYNC WATCH CALLED");
    final newSet = newChildIds.toSet();
    debugPrint("newChildIds ${newSet.length}");
    if (setEquals(newSet, _watchingIds)) return;

    debugPrint("🔄 SYNC WATCHING: $newSet");

    _status = LocationSharingStatus.sharing;
    notifyListeners();

    // ==============================
    // 1️⃣ Unwatch child bị xoá
    // ==============================
    final removed = _watchingIds.difference(newSet);

    for (final id in removed) {
      await _subs[id]?.cancel();
      _subs.remove(id);
      _childrenLocations.remove(id);
      _childrenTrails.remove(id);
      debugPrint("🛑 Unwatched $id");
    }

    // ==============================
    // 2️⃣ Watch child mới
    // ==============================
    final added = newSet.difference(_watchingIds);

    for (final id in added) {
      _subscribeChild(id);
      debugPrint("👀 Watching $id");
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

  List<LocationData> generateFakeHoTayHistory() {
    final baseTime = DateTime.now().millisecondsSinceEpoch;
    print("HAM NAY DC GOI generateFakeHoTayHistory");
    // Tọa độ thực tế bờ Hồ Tây, đi theo chiều kim đồng hồ
    // Bắt đầu từ góc phía Nam (đường Thanh Niên / cầu Trúc Bạch)
    final points = [
      [21.04720, 105.83600], // Điểm đầu - Đường Thanh Niên (phía Nam)
      [21.04900, 105.83550], // Đường Thụy Khuê (phía Tây Nam)
      [21.05100, 105.83480],
      [21.05320, 105.83420],
      [21.05560, 105.83380], // Phường Bưởi
      [21.05790, 105.83420],
      [21.06020, 105.83510],
      [21.06230, 105.83640], // Phố Lạc Long Quân (phía Tây)
      [21.06420, 105.83820],
      [21.06580, 105.84050],
      [21.06700, 105.84310], // Góc Tây Bắc
      [21.06780, 105.84590],
      [21.06800, 105.84880],
      [21.06760, 105.85170],
      [21.06660, 105.85440], // Phía Bắc - Xuân La
      [21.06510, 105.85680],
      [21.06310, 105.85870],
      [21.06080, 105.85990],
      [21.05840, 105.86050], // Góc Đông Bắc - Tây Hồ
      [21.05590, 105.86020],
      [21.05340, 105.85930],
      [21.05120, 105.85780], // Phố Đặng Thai Mai (phía Đông)
      [21.04920, 105.85590],
      [21.04760, 105.85360],
      [21.04660, 105.85100],
      [21.04630, 105.84830], // Phía Đông Nam - Quảng Bá
      [21.04680, 105.84560],
      [21.04780, 105.84310],
      [21.04910, 105.84080],
      [21.05030, 105.83870],
      [21.04900, 105.83720], // Đường Thanh Niên quay về
      [21.04780, 105.83650],
      [21.04720, 105.83600], // Điểm kết thúc (về điểm đầu)
    ];

    return List.generate(points.length, (i) {
      return LocationData(
        latitude: points[i][0],
        longitude: points[i][1],
        accuracy: 8,
        speed: 4.0,
        heading: (i * (360 / points.length)).toDouble(),
        isMock: false,
        timestamp: baseTime + (i * 5000),
      );
    });
  }
  /* ============================================================
     HISTORY + STATS
  ============================================================ */

  Future<List<LocationData>> loadLocationHistory(String childId) async {
    try {
      final history = await _locationRepo.getLocationHistory(childId);
      final valid = history.where(_isValidLocation).toList();

      _childrenTrails[childId] = valid;
      if (valid.isNotEmpty) {
        _childrenLocations[childId] = valid.last;
      }
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
