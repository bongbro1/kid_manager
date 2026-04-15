import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/utils/app_localizations_loader.dart';

enum LocationSharingStatus { idle, sharing, paused, error }

class ParentLocationVm extends ChangeNotifier {
  static const Duration _currentShareMinInterval = Duration(seconds: 5);

  final LocationRepository _locationRepo;
  final LocationServiceInterface _locationService;

  ParentLocationVm(this._locationRepo, this._locationService);

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
  bool _shareMyCurrentEnabled = false;
  int _lastSharedCurrentTimestamp = 0;
  int _lastSharedCurrentSentAtMs = 0;

  Future<AppLocalizations>? _l10nFuture;
  String? _l10nUid;

  final Map<String, LocationData> _childrenLocations = {};
  final Map<String, List<LocationData>> _childrenTrails = {};
  final Map<String, StreamSubscription<LocationData>> _subs = {};

  Future<AppLocalizations> _getL10n() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_l10nFuture != null && _l10nUid == uid) {
      return _l10nFuture!;
    }

    final fallbackLang =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'en'
        ? 'en'
        : 'vi';
    _l10nUid = uid;
    _l10nFuture = AppLocalizationsLoader.loadForUser(
      userRepository: UserRepository.background(FirebaseFirestore.instance),
      uid: uid,
      fallbackLang: fallbackLang,
    );
    return _l10nFuture!;
  }

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

  Map<String, List<LocationData>> get childrenTrails => _childrenTrails;

  Future<void> startMyLocation() async {
    final l10n = await _getL10n();

    try {
      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: false,
      );
      if (!ok) {
        _setError(l10n.noLocationPermission);
        return;
      }

      await _myGpsSub?.cancel();
      _myGpsSub = _locationService.getLocationStream().listen(
        (loc) {
          _myLocation = loc;
          if (_shareMyCurrentEnabled) {
            unawaited(_publishCurrentLocation(loc));
          }
          notifyListeners();
        },
        onError: (e) => _setError(l10n.parentLocationGpsError('$e')),
      );
    } catch (e) {
      _setError(l10n.parentLocationEnableGpsError('$e'));
    }
  }

  Future<LocationData?> getMyLocationOnce({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final l10n = await _getL10n();

    try {
      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: false,
      );
      if (!ok) {
        _setError(l10n.noLocationPermission);
        return null;
      }

      final loc = await _locationService.getLocationStream().first.timeout(
        timeout,
      );

      _myLocation = loc;
      notifyListeners();
      return loc;
    } catch (e) {
      _setError(l10n.parentLocationCurrentLocationError('$e'));
      return null;
    }
  }

  Future<void> stopMyLocation() async {
    await _myGpsSub?.cancel();
    _myGpsSub = null;
    _lastSharedCurrentTimestamp = 0;
    _lastSharedCurrentSentAtMs = 0;
  }

  Future<void> setCurrentSharingEnabled(bool enabled) async {
    if (_shareMyCurrentEnabled == enabled) {
      return;
    }

    _shareMyCurrentEnabled = enabled;
    if (!enabled) {
      _lastSharedCurrentTimestamp = 0;
      _lastSharedCurrentSentAtMs = 0;
      return;
    }

    final current = _myLocation;
    if (current != null) {
      await _publishCurrentLocation(current, force: true);
    }
  }

  Future<void> _publishCurrentLocation(
    LocationData location, {
    bool force = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force) {
      if (_lastSharedCurrentTimestamp == location.timestamp) {
        return;
      }
      final elapsedSinceLastShare = nowMs - _lastSharedCurrentSentAtMs;
      if (elapsedSinceLastShare < _currentShareMinInterval.inMilliseconds) {
        return;
      }
    }

    final payload = TrackingPayload(
      deviceId: uid,
      location: location,
      motion: location.motion.isEmpty ? 'unknown' : location.motion,
      transport: location.transport.name,
    );

    try {
      await _locationRepo.updateMyCurrent(payload);
      _lastSharedCurrentTimestamp = location.timestamp;
      _lastSharedCurrentSentAtMs = nowMs;
    } catch (e, st) {
      debugPrint('ParentLocationVm current publish error: $e');
      debugPrint('$st');
    }
  }
  /* ============================================================
     WATCHING
  ============================================================ */

  Stream<LocationData> watchChildLocation(String childId) =>
      _locationRepo.watchChildLocation(childId);

  Future<void> syncWatching(List<AppUser> members) async {
    final memberById = <String, AppUser>{
      for (final member in members) member.uid: member,
    };
    final newSet = memberById.keys.toSet();
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
      final member = memberById[id];
      if (member == null) continue;
      _subscribeMember(member);
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
    int? startMinuteOfDay,
    int? endMinuteOfDay,
  }) async {
    final l10n = await _getL10n();

    try {
      final history = await _locationRepo.getLocationHistoryByDay(
        childUid,
        day,
        fromTs: fromTs,
        toTs: toTs,
        startMinuteOfDay: startMinuteOfDay,
        endMinuteOfDay: endMinuteOfDay,
      );
      return history.where(_isValidLocation).toList();
    } catch (e) {
      _setError(l10n.parentLocationHistoryLoadError('$e'));
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

  Future<void> _setChildWatchError(String childId, Object error) async {
    final l10n = await _getL10n();
    _setError(l10n.parentLocationWatchChildError(childId, '$error'));
  }

  void _subscribeMember(AppUser member) {
    if (_subs.containsKey(member.uid)) return;

    _childrenTrails.putIfAbsent(member.uid, () => []);
    final preferRealtime = member.isChild;

    final sub = _locationRepo
        .watchChildLocation(member.uid, preferRealtime: preferRealtime)
        .listen(
      (loc) {
        if (!_isValidLocation(loc)) return;

        _childrenLocations[member.uid] = loc;

        final trail = _childrenTrails[member.uid]!;
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
      },
      onError: (e) => unawaited(_setChildWatchError(member.uid, e)),
    );

    _subs[member.uid] = sub;
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
