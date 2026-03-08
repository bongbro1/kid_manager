import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/repositories/subscription_repository.dart';

class SubscriptionVM extends ChangeNotifier {
  final SubscriptionRepository _repository;

  SubscriptionVM(this._repository);

  SubscriptionInfo? _subscription;
  SubscriptionInfo? get subscription => _subscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isActive = false;
  bool get isActive => _isActive;

  StreamSubscription<SubscriptionInfo?>? _subscriptionStream;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> loadSubscription(String uid) async {
    try {
      _setLoading(true);
      _setError(null);

      final sub = await _repository.getSubscription(uid);
      _subscription = sub;
      _isActive = _computeIsActive(sub);

      notifyListeners();
    } catch (e) {
      _setError('Không tải được subscription: $e');
    } finally {
      _setLoading(false);
    }
  }

  void watchSubscription(String uid) {
    _subscriptionStream?.cancel();

    _subscriptionStream = _repository.watchSubscription(uid).listen(
      (sub) {
        _subscription = sub;
        _isActive = _computeIsActive(sub);
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Theo dõi subscription thất bại: $e';
        notifyListeners();
      },
    );
  }

  Future<void> updateSubscription({
    required String uid,
    required SubscriptionInfo subscription,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _repository.updateSubscription(
        uid: uid,
        subscription: subscription,
      );

      _subscription = subscription;
      _isActive = _computeIsActive(subscription);

      notifyListeners();
    } catch (e) {
      _setError('Cập nhật subscription thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> activatePlan({
    required String uid,
    required String plan,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _repository.activatePlan(
        uid: uid,
        plan: plan,
        startAt: startAt,
        endAt: endAt,
      );

      await loadSubscription(uid);
    } catch (e) {
      _setError('Kích hoạt gói thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startTrial({
    required String uid,
    int trialDays = 7,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      await _repository.startTrial(uid: uid, trialDays: trialDays);
      await loadSubscription(uid);
    } catch (e) {
      _setError('Bắt đầu trial thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markExpired(String uid) async {
    try {
      _setLoading(true);
      _setError(null);

      await _repository.markExpired(uid);
      await loadSubscription(uid);
    } catch (e) {
      _setError('Đánh dấu expired thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearSubscription(String uid) async {
    try {
      _setLoading(true);
      _setError(null);

      await _repository.clearSubscription(uid);
      _subscription = null;
      _isActive = false;

      notifyListeners();
    } catch (e) {
      _setError('Xóa subscription thất bại: $e');
    } finally {
      _setLoading(false);
    }
  }

  bool _computeIsActive(SubscriptionInfo? sub) {
    if (sub == null) return false;

    final now = DateTime.now();

    if (sub.status != 'active' && sub.status != 'trial') {
      return false;
    }

    if (sub.endAt != null && sub.endAt!.isBefore(now)) {
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}