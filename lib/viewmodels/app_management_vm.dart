import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/repositories/app_management_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/usage_rule.dart';

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

  List<ChildItem> children = [];

  String? _selectedChildId;
  String? get selectedChildId => _selectedChildId;

  Future<void> selectChild(String uid) async {
    if (_selectedChildId == uid) return;

    _selectedChildId = uid;
    notifyListeners();
    await loadAppsForSelectedChild();
  }

  Future<void> loadAppsForSelectedChild() async {
    if (_selectedChildId == null) {
      _apps = [];
      _loading = false;
      notifyListeners();
      return;
    }
    await loadApps(_selectedChildId!);
  }

  /// Load + seed + sync usage
  Future<void> loadApps(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      _apps = await _repo.loadAppsFromFirestore(userId);
      notifyListeners();
      await _repo.syncTodayUsage(userId: userId);
    } catch (e, stack) {
      debugPrint("❌ loadApps ERROR: $e");
      debugPrint("STACK: $stack");

      _error = 'Không thể đồng bộ ứng dụng';
    } finally {
      _setLoading(false);
    }
  }

  /// Chỉ sync usage (khi app đã seed)
  Future<void> syncUsageOnly(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      await _repo.syncTodayUsage(userId: userId);
    } catch (e) {
      _error = 'Không thể cập nhật usage';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChildren() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = _storage.getString(StorageKeys.uid);

      if (uid == null) {
        _error = "Không tìm thấy userId";
        _loading = false;
        notifyListeners();
        return;
      }

      children = await _userRepo.getChildrenByParentUid(uid);
      autoSelectFirstChild();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  void autoSelectFirstChild() {
    if (children.isEmpty) return;

    if (_selectedChildId == null) {
      _selectedChildId = children.first.id;
      loadAppsForSelectedChild();
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<void> loadAndSeedApp() async {
    try {
      final role = _storage.getString(StorageKeys.role);
      final userId = _storage.getString(StorageKeys.uid);
      if (role != 'child') {
        return;
      }

      if (userId == null) {
        return;
      }

      await _repo.loadAndSeedAppToFirebase(userId);
    } catch (e, s) {
      debugPrint("❌ loadAndSeedApp error: $e");
      debugPrint("$s");
    }
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
}
