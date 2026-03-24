import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/helpers/zone/zone_overlap.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParentZonesVm extends ChangeNotifier {
  final ZoneRepository _repo;
  final FirebaseAuth _auth;
  final ProfileRepository _profileRepository;
  final AccessControlService _accessControl;

  ParentZonesVm(
    this._repo,
    this._profileRepository,
    this._accessControl, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  StreamSubscription<List<GeoZone>>? _sub;

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
    _zones = latest;
    _error = null;
    notifyListeners();
  }

  Future<void> _ensureCanManageChild(String childUid) async {
    final actorUid = _auth.currentUser?.uid?.trim();
    if (actorUid == null || actorUid.isEmpty) {
      throw StateError('Unauthenticated');
    }

    final actor = await _profileRepository.getUserById(actorUid);
    final child = await _profileRepository.getUserById(childUid);
    if (actor == null ||
        child == null ||
        !_accessControl.canManageChild(
          actor: actor,
          childUid: childUid,
          child: child,
        )) {
      throw StateError('Access denied');
    }
  }

  Future<void> bind(String childUid) async {
    try {
      await _ensureCanManageChild(childUid);
      await _sub?.cancel();
      _sub = _repo.watchZones(childUid).listen((list) {
        debugPrint("zones length = ${list.length}");
        _zones = list;
        _error = null;
        notifyListeners();
      }, onError: (e) {
        debugPrint("watchZones error: $e");
        _setError(e);
      });
    } catch (e) {
      _setError(e);
    }
  }

  Future<void> toggleEnabled(String childUid, GeoZone zone, bool enabled) async {
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
      rethrow;
    }
  }

  Future<void> save(String childUid, GeoZone zone) async {
    _setLoading(true);
    clearError();
    try {
      await _ensureCanManageChild(childUid);
      final uid = _auth.currentUser?.uid;
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
    final uid = _auth.currentUser?.uid ?? "";
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
    _sub?.cancel();
    super.dispose();
  }
}
