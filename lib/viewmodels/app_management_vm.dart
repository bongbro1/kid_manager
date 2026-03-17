import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/app_management_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

class AppManagementVM extends ChangeNotifier {
  final AppManagementRepository _repo;
  final UserRepository _userRepo;
  final StorageService _storage;

  AppManagementVM(this._repo, this._userRepo, this._storage);

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<AppItemModel> _apps = [];
  List<AppItemModel> get apps => _apps;

  Map<DateTime, int> _usageMap = {};
  Map<DateTime, int> get usageMap => _usageMap;

  // cho từng app
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

  Future<void> selectChild(String uid) async {
    if (_selectedChildId == uid) return;

    _selectedChildId = uid;
    notifyListeners();
    await loadAppsForSelectedChild();
  }

  Future<void> watchChildren(String parentUid) async {
    _childrenSub?.cancel();

    _loading = true;
    notifyListeners();

    _childrenSub = _userRepo
        .watchChildrenByParentUid(parentUid)
        .listen(
          (list) async {
            // 🔹 filter bỏ guardian
            final filtered = list.where((u) => roleToString(u.role) != roleToString(UserRole.guardian)).toList();

            children = filtered.map(ChildItem.fromUser).toList();

            await autoSelectFirstChild();

            _loading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _loading = false;
            notifyListeners();
          },
        );
  }

  Future<void> loadAppsForSelectedChild() async {
    if (_selectedChildId == null) {
      _apps = [];
      _loading = false;
      notifyListeners();
      return;
    }
    await loadApps(_selectedChildId!);
    await loadUsageHistory(_selectedChildId!);
  }

  /// Load + seed + sync usage
  Future<void> loadApps(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      // await _repo.migrateLegacyTimeRange(userId)

      _apps = await _repo.loadAppsFromFirestore(userId);
      notifyListeners();
      // await _repo.syncTodayUsage(userId: userId);
    } catch (e, stack) {
      debugPrint("❌ loadApps ERROR: $e");
      debugPrint("STACK: $stack");

      _error = 'Không thể đồng bộ ứng dụng';
    } finally {
      _setLoading(false);
    }
  }

  /// Chỉ sync usage (khi app đã seed)
  // Future<void> syncUsageOnly(String userId) async {
  //   _setLoading(true);
  //   _error = null;

  //   try {
  //     await _repo.syncTodayUsage(userId: userId);
  //   } catch (e) {
  //     _error = 'Không thể cập nhật usage';
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Future<void> loadChildren() async {
  //   _loading = true;
  //   _error = null;
  //   notifyListeners();

  //   try {
  //     final uid = _storage.getString(StorageKeys.uid);

  //     if (uid == null) {
  //       _error = "Không tìm thấy userId";
  //       _loading = false;
  //       notifyListeners();
  //       return;
  //     }

  //     children = await _userRepo.getChildrenByParentUid(uid);
  //     autoSelectFirstChild();
  //   } catch (e) {
  //     _error = e.toString();
  //   }

  //   _loading = false;
  //   notifyListeners();
  // }
  Future<void> autoSelectFirstChild() async {
    if (children.isEmpty) return;

    if (_selectedChildId == null) {
      if (!children.any((c) => c.id == _selectedChildId)) {
        _selectedChildId = children.first.id;
      }

      await loadAppsForSelectedChild();

      notifyListeners();
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

      if (role != 'child') {
        _setLoading(false);
        return;
      }

      if (userId == null) {
        _error = "UserId not found";
        _setLoading(false);
        return;
      }

      await _repo.loadAndSeedAppToFirebase(userId);
    } catch (e, s) {
      _error = e.toString();
      debugPrint("❌ loadAndSeedApp error: $e");
      debugPrint("$s");
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

      await _repo.saveUsageRuleForApp(
        userId: userId,
        packageName: packageName,
        rule: rule,
      );
    } catch (e) {
      debugPrint("❌ Save rule failed: $e");
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<UsageRule?> loadUsageRule({
    required String childId,
    required String packageName,
  }) {
    return _repo.fetchUsageRule(userId: childId, packageName: packageName);
  }

  Future<void> loadUsageHistory(String selectedChildId) async {
    try {
      final result = await _repo.loadUsageHistory(selectedChildId);

      _usageMap = result.totalUsage;
      _appUsageMap = result.perAppUsage;

      /// NEW
      _hourlyUsage = result.hourlyUsage;

      _usageVersion++;
      notifyListeners();
    } catch (e, stack) {
      debugPrint("❌ loadUsageHistory ERROR: $e");
      debugPrint("STACK: $stack");
    }
  }

  Future<void> clear() async {
    await _childrenSub?.cancel();
    _childrenSub = null;

    _loading = false;
    _error = null;
    _apps = [];
    _usageMap = {};
    _appUsageMap = {};
    children = [];
    _selectedChildId = null;
    _usageVersion = 0;

    notifyListeners();
  }

  @override
  void dispose() {
    _childrenSub?.cancel();
    super.dispose();
  }

  // Future<void> rebuildUsageFlat(String selectedChildId) async {
  //   await _repo.rebuildUsageDailyFlat(selectedChildId);
  // }
}
