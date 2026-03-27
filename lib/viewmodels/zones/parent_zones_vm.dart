import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/helpers/zone/zone_overlap.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentZonesVm extends ChangeNotifier {
  final ZoneRepositoryInterface _repo;
  final ProfileRepositoryInterface _profileRepository;
  final AccessControlService _accessControl;
  final String? Function() _currentUserUidProvider;

  ParentZonesVm(
    this._repo,
    this._profileRepository,
    this._accessControl, {
    FirebaseAuth? auth,
    String? Function()? currentUserUidProvider,
  }) : _currentUserUidProvider =
           currentUserUidProvider ??
           (() => (auth ?? FirebaseAuth.instance).currentUser?.uid.trim());

  StreamSubscription<List<GeoZone>>? _sub;
  int _bindGeneration = 0;
  String? _boundChildUid;

  List<GeoZone> _zones = [];
  List<GeoZone> get zones => _zones;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void _setError(Object? e) {
    _error = e?.toString();
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<void> _reloadZones(String childUid) async {
    final latest = await _repo.getZonesOnce(childUid);
    if (_boundChildUid != null && _boundChildUid != childUid) {
      return;
    }
    _zones = latest;
    _error = null;
    notifyListeners();
  }

  Future<({AppUser actor, AppUser child})> _loadAccessContext(
    String childUid,
  ) async {
    final actorUid = _currentUserUidProvider()?.trim();
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Unauthenticated');
    }

    final actor = await _profileRepository.getUserById(actorUid);
    final child = await _profileRepository.getUserById(childUid);
    if (actor == null || child == null) {
      throw StateError('Access denied');
    }

    return (actor: actor, child: child);
  }

  Future<void> _ensureCanViewChild(String childUid) async {
    final access = await _loadAccessContext(childUid);
    if (!_accessControl.canAccessChild(
      actor: access.actor,
      childUid: childUid,
      child: access.child,
    )) {
      throw StateError('Access denied');
    }
  }

  Future<void> _ensureCanManageChild(String childUid) async {
    final access = await _loadAccessContext(childUid);
    if (!_accessControl.canManageChild(
      actor: access.actor,
      childUid: childUid,
      child: access.child,
    )) {
      throw StateError('Access denied');
    }
  }

  bool _isCurrentBind(int generation, String childUid) {
    return _bindGeneration == generation && _boundChildUid == childUid;
  }

  Future<void> bind(String childUid) async {
    final generation = ++_bindGeneration;
    _boundChildUid = childUid;

    final staleSub = _sub;
    _sub = null;
    await staleSub?.cancel();
    if (!_isCurrentBind(generation, childUid)) {
      return;
    }

    _zones = [];
    _error = null;
    notifyListeners();

    try {
      await _ensureCanViewChild(childUid);
      if (!_isCurrentBind(generation, childUid)) {
        return;
      }

      _sub = _repo
          .watchZones(childUid)
          .listen(
            (list) {
              if (!_isCurrentBind(generation, childUid)) {
                return;
              }
              _zones = list;
              _error = null;
              notifyListeners();
            },
            onError: (e) {
              if (!_isCurrentBind(generation, childUid)) {
                return;
              }
              _setError(e);
            },
          );
    } catch (e) {
      if (_isCurrentBind(generation, childUid)) {
        _setError(e);
      }
    }
  }

  Future<void> toggleEnabled(
    String childUid,
    GeoZone zone,
    bool enabled,
  ) async {
    try {
      clearError();
      await _ensureCanManageChild(childUid);
      final now = DateTime.now().millisecondsSinceEpoch;
      await _repo.upsertZone(
        childUid,
        zone.copyWith(enabled: enabled, updatedAt: now),
      );
      await _reloadZones(childUid);
    } catch (e) {
      debugPrint('toggle zone failed: $e');
      _setError(e);
    }
  }

  Future<void> delete(String childUid, String zoneId) async {
    try {
      clearError();
      await _ensureCanManageChild(childUid);
      await _repo.deleteZone(childUid, zoneId);
      await _reloadZones(childUid);
    } catch (e) {
      debugPrint('delete zone failed: $e');
      _setError(e);
      rethrow;
    }
  }

  Future<void> save(String childUid, GeoZone zone) async {
    _setLoading(true);
    clearError();
    try {
      await _ensureCanManageChild(childUid);
      final uid = _currentUserUidProvider()?.trim();
      if (uid == null || uid.isEmpty) {
        throw StateError("Unauthenticated");
      }
      // check overlap bằng list đang có trong VM
      final hit = findOverlappingZone(candidate: zone, existing: _zones);
      if (hit != null) {
        throw Exception("Zone overlaps with '${hit.name}'");
      }

      final now = DateTime.now().millisecondsSinceEpoch;

      final fixed = zone.copyWith(
        createdBy: zone.createdBy.isNotEmpty ? zone.createdBy : uid,
        createdAt: zone.createdAt == 0 ? now : zone.createdAt,
        updatedAt: now,
      );

      await _repo.upsertZone(childUid, fixed);
      await _reloadZones(childUid);
    } catch (e) {
      debugPrint('save zone failed: $e');
      _setError(e);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  GeoZone newDraftZone({
    required String id,
    required double lat,
    required double lng,
  }) {
    final uid = _currentUserUidProvider()?.trim() ?? "";
    final now = DateTime.now().millisecondsSinceEpoch;

    return GeoZone(
      id: id,
      name: "Vùng mới",
      type: ZoneType.safe,
      lat: lat,
      lng: lng,
      radiusM: 64,
      enabled: true,
      createdBy: uid,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  void dispose() {
    _bindGeneration++;
    _boundChildUid = null;
    _sub?.cancel();
    super.dispose();
  }
}
