import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/app_management_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/access_control/feature_policy.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

class AppManagementVM extends ChangeNotifier {
  final AppManagementRepository _repo;
  final UserRepository _userRepo;
  final StorageService _storage;
  final AccessControlService _accessControl;

  AppManagementVM(
    this._repo,
    this._userRepo,
    this._storage,
    this._accessControl,
  );

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<AppItemModel> _apps = [];
  List<AppItemModel> get apps => _apps;

  Map<DateTime, int> _usageMap = {};
  Map<DateTime, int> get usageMap => _usageMap;

  Map<String, Map<DateTime, int>> _appUsageMap = {};
  Map<String, Map<DateTime, int>> get appUsageMap => _appUsageMap;

  Map<DateTime, Map<int, int>> _hourlyUsage = {};
  Map<DateTime, Map<int, int>> get hourlyUsage => _hourlyUsage;

  List<ChildItem> children = [];

  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;
  bool get hasChild => children.isNotEmpty;

  int _usageVersion = 0;
  int get usageVersion => _usageVersion;

  StreamSubscription<List<AppUser>>? _childrenSub;
  int _childrenWatchGeneration = 0;
  int _loadGeneration = 0;

  Future<AppUser?> _resolveActor() async {
    final uid = _storage.getString(StorageKeys.uid)?.trim();
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return _userRepo.getUserById(uid);
  }

  Future<AppUser?> _resolveActorSnapshot() async {
    final actor = await _resolveActor();
    if (actor != null) {
      return actor;
    }

    final uid = _storage.getString(StorageKeys.uid)?.trim();
    if (uid == null || uid.isEmpty) {
      return null;
    }

    final role = roleFromString(
      _storage.getString(StorageKeys.role),
      fallback: UserRole.child,
    );
    if (!role.isAdultManager) {
      return null;
    }

    final parentUid = _storage.getString(StorageKeys.parentId)?.trim();
    final managedChildIds =
        _storage.getStringList(StorageKeys.managedChildIds) ?? const <String>[];

    return AppUser(
      uid: uid,
      role: role,
      parentUid: parentUid == null || parentUid.isEmpty ? null : parentUid,
      managedChildIds: managedChildIds
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }

  Future<AppUser?> _resolveManagedChild(String childId) async {
    return _userRepo.getUserById(childId);
  }

  Future<String?> _requireAuthorizedManagedChildId(String childId) async {
    final normalizedChildId = childId.trim();
    if (normalizedChildId.isEmpty) {
      return null;
    }

    final actor = await _resolveActorSnapshot();
    if (actor == null ||
        !actor.role.isAdultManager ||
        !_accessControl.canUseFeature(
          feature: AppFeature.appManagement,
          actor: actor,
        )) {
      return null;
    }

    final child = await _resolveManagedChild(normalizedChildId);
    if (child == null ||
        !_accessControl.canManageChild(
          actor: actor,
          childUid: normalizedChildId,
          child: child,
        )) {
      return null;
    }

    return normalizedChildId;
  }

  void _resetLoadedData() {
    _apps = [];
    _usageMap = {};
    _appUsageMap = {};
    _hourlyUsage = {};
    _usageVersion++;
  }

  bool _isStaleLoad(int generation, String childId) {
    return generation != _loadGeneration || _selectedChildId != childId;
  }

  Future<void> selectChild(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty || _selectedChildId == normalizedUid) return;

    _selectedChildId = normalizedUid;
    _error = null;
    notifyListeners();
    await loadAppsForSelectedChild();
  }

  Future<void> watchChildren(String parentUid) async {
    _childrenWatchGeneration++;
    _loadGeneration++;
    final watchGeneration = _childrenWatchGeneration;
    await _childrenSub?.cancel();
    _childrenSub = null;

    _loading = true;
    _error = null;
    _resetLoadedData();
    notifyListeners();

    _childrenSub = _userRepo
        .watchChildrenByParentUid(parentUid)
        .listen(
          (list) async {
            if (watchGeneration != _childrenWatchGeneration) return;
            final actor = await _resolveActorSnapshot();

            final filtered = actor == null
                ? <AppUser>[
                    if (roleFromString(
                      _storage.getString(StorageKeys.role),
                      fallback: UserRole.child,
                    ).isAdultManager)
                      ...list,
                  ]
                : list
                      .where(
                        (user) => _accessControl.canManageChild(
                          actor: actor,
                          childUid: user.uid,
                          child: user,
                        ),
                      )
                      .toList(growable: false);

            children = filtered.map(ChildItem.fromUser).toList();

            if (children.isEmpty) {
              _selectedChildId = null;
              _error = null;
              _resetLoadedData();
              _loading = false;
              notifyListeners();
              return;
            }

            final shouldReselect =
                _selectedChildId == null ||
                !children.any((c) => c.id == _selectedChildId);

            if (shouldReselect) {
              _selectedChildId = children.first.id;
              notifyListeners();
              await loadAppsForSelectedChild();
              if (watchGeneration != _childrenWatchGeneration) return;
            }

            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            if (watchGeneration != _childrenWatchGeneration) return;
            _error = e.toString();
            _selectedChildId = null;
            _resetLoadedData();
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<void> loadAppsForSelectedChild() async {
    final childId = _selectedChildId?.trim();
    final loadGeneration = ++_loadGeneration;

    if (childId == null || childId.isEmpty) {
      _error = null;
      _resetLoadedData();
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final authorizedChildId = await _requireAuthorizedManagedChildId(childId);
      if (authorizedChildId == null) {
        _resetLoadedData();
        _error = runtimeL10n().appManagementSyncFailed;
        return;
      }

      final loadedApps = await _repo.loadAppsFromFirestore(authorizedChildId);
      if (_isStaleLoad(loadGeneration, childId)) return;

      final usageResult = await _repo.loadUsageHistory(authorizedChildId);
      if (_isStaleLoad(loadGeneration, childId)) return;

      _apps = loadedApps;
      _usageMap = usageResult.totalUsage;
      _appUsageMap = usageResult.perAppUsage;
      _hourlyUsage = usageResult.hourlyUsage;
      _usageVersion++;
    } on FirebaseException catch (e, stack) {
      debugPrint('loadApps ERROR: $e');
      debugPrint('STACK: $stack');

      if (_isStaleLoad(loadGeneration, childId)) return;
      _resetLoadedData();
      _error = runtimeL10n().appManagementSyncFailed;
    } catch (e, stack) {
      debugPrint('loadApps ERROR: $e');
      debugPrint('STACK: $stack');

      if (_isStaleLoad(loadGeneration, childId)) return;
      _resetLoadedData();
      _error = runtimeL10n().appManagementSyncFailed;
    } finally {
      if (_isStaleLoad(loadGeneration, childId)) return;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadApps(String userId) async {
    final normalizedUid = userId.trim();
    _selectedChildId = normalizedUid.isEmpty ? null : normalizedUid;
    await loadAppsForSelectedChild();
  }

  Future<void> autoSelectFirstChild() async {
    if (children.isEmpty) {
      _selectedChildId = null;
      _error = null;
      _resetLoadedData();
      notifyListeners();
      return;
    }

    final shouldReselect =
        _selectedChildId == null ||
        !children.any((c) => c.id == _selectedChildId);

    if (shouldReselect) {
      _selectedChildId = children.first.id;
      notifyListeners();
      await loadAppsForSelectedChild();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> loadAndSeedApp() async {
    _setLoading(true);
    _error = null;

    try {
      final role = _storage.getString(StorageKeys.role);
      final userId = _storage.getString(StorageKeys.uid);

      if (roleFromString(role, fallback: UserRole.child) != UserRole.child) {
        _setLoading(false);
        return;
      }

      if (userId == null) {
        _error = runtimeL10n().appManagementUserIdNotFound;
        _setLoading(false);
        return;
      }

      await _repo.loadAndSeedAppToFirebase(userId);
    } catch (e, s) {
      _error = e.toString();
      debugPrint('loadAndSeedApp error: $e');
      debugPrint('$s');
    }

    _setLoading(false);
  }

  Future<void> saveUsageRule({
    required String userId,
    required String packageName,
    required UsageRule rule,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final authorizedChildId = await _requireAuthorizedManagedChildId(userId);
      if (authorizedChildId == null) {
        throw StateError('Not allowed to manage this child');
      }

      await _repo.saveUsageRuleForApp(
        userId: authorizedChildId,
        packageName: packageName,
        rule: rule,
      );
    } catch (e) {
      debugPrint('Save rule failed: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UsageRule?> loadUsageRule({
    required String childId,
    required String packageName,
  }) async {
    final authorizedChildId = await _requireAuthorizedManagedChildId(childId);
    if (authorizedChildId == null) {
      throw StateError('Not allowed to manage this child');
    }
    return _repo.fetchUsageRule(
      userId: authorizedChildId,
      packageName: packageName,
    );
  }

  Future<void> loadUsageHistory(String selectedChildId) async {
    try {
      final authorizedChildId =
          await _requireAuthorizedManagedChildId(selectedChildId);
      if (authorizedChildId == null) {
        throw StateError('Not allowed to manage this child');
      }

      final result = await _repo.loadUsageHistory(authorizedChildId);
      if (_selectedChildId != selectedChildId) return;

      _usageMap = result.totalUsage;
      _appUsageMap = result.perAppUsage;
      _hourlyUsage = result.hourlyUsage;
      _usageVersion++;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('loadUsageHistory ERROR: $e');
      debugPrint('STACK: $stack');
    }
  }

  Future<void> clear() async {
    _childrenWatchGeneration++;
    _loadGeneration++;
    await _childrenSub?.cancel();
    _childrenSub = null;

    _loading = false;
    _error = null;
    _resetLoadedData();
    children = [];
    _selectedChildId = null;

    notifyListeners();
  }

  Future<void> suspendChildrenWatch({bool notify = false}) async {
    _childrenWatchGeneration++;
    _loadGeneration++;
    await _childrenSub?.cancel();
    _childrenSub = null;

    if (notify) {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _childrenWatchGeneration++;
    _loadGeneration++;
    _childrenSub?.cancel();
    super.dispose();
  }
}
