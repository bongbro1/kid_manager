import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/subscription/subscription_catalog_plan.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/repositories/subscription_repository.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

enum SubscriptionRegistrationStatus {
  idle,
  registered,
  contactRequested,
  failed,
}

class SubscriptionViewModel extends ChangeNotifier {
  final SubscriptionRepository _repository;

  SubscriptionViewModel(SubscriptionRepository repository)
    : _repository = repository;

  SubscriptionInfo? _subscription;
  SubscriptionInfo? get subscription => _subscription;

  List<SubscriptionCatalogPlan> _plans = const [];
  List<SubscriptionCatalogPlan> get plans => _plans;

  SubscriptionCatalogPlan? _selectedPlan;
  SubscriptionCatalogPlan? get selectedPlan => _selectedPlan;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _error;
  String? get error => _error;

  bool _isActive = false;
  bool get isActive => _isActive;

  SubscriptionRegistrationStatus _registrationStatus =
      SubscriptionRegistrationStatus.idle;
  SubscriptionRegistrationStatus get registrationStatus => _registrationStatus;

  StreamSubscription<SubscriptionInfo?>? _subscriptionStream;
  String? _activeUid;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }

  Future<void> initialize(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    _activeUid = normalizedUid;
    await loadPlans();
    await loadSubscription(normalizedUid);
    watchSubscription(normalizedUid);
    _syncSelectedPlanWithSubscription();
  }

  Future<void> loadPlans() async {
    try {
      _setLoading(true);
      _setError(null);
      _plans = await _repository.fetchPlans();
      _syncSelectedPlanWithSubscription();
      notifyListeners();
    } catch (e) {
      _setError(runtimeL10n().subscriptionLoadError('$e'));
    } finally {
      _setLoading(false);
    }
  }

  void selectPlan(String planId) {
    final normalizedId = planId.trim().toLowerCase();
    if (normalizedId.isEmpty) return;

    final nextPlan = _findPlanById(normalizedId);
    if (nextPlan == null || nextPlan.id == _selectedPlan?.id) {
      return;
    }

    _selectedPlan = nextPlan;
    _registrationStatus = SubscriptionRegistrationStatus.idle;
    notifyListeners();
  }

  Future<void> loadSubscription(String uid) async {
    try {
      _setLoading(true);
      _setError(null);

      final sub = await _repository.getSubscription(uid);
      _subscription = sub;
      _isActive = _computeIsActive(sub);
      _syncSelectedPlanWithSubscription();

      notifyListeners();
    } catch (e) {
      _setError(runtimeL10n().subscriptionLoadError('$e'));
    } finally {
      _setLoading(false);
    }
  }

  void watchSubscription(String uid) {
    _subscriptionStream?.cancel();

    _subscriptionStream = _repository
        .watchSubscription(uid)
        .listen(
          (sub) {
            _subscription = sub;
            _isActive = _computeIsActive(sub);
            _error = null;
            _syncSelectedPlanWithSubscription();
            notifyListeners();
          },
          onError: (e) {
            _error = runtimeL10n().subscriptionWatchError('$e');
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
      _syncSelectedPlanWithSubscription();

      notifyListeners();
    } catch (e) {
      _setError(runtimeL10n().subscriptionUpdateError('$e'));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> activatePlan({
    required String uid,
    required SubscriptionPlan plan,
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
      _setError(runtimeL10n().subscriptionActivateError('$e'));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startTrial({required String uid, int trialDays = 7}) async {
    try {
      _setLoading(true);
      _setError(null);

      await _repository.startTrial(uid: uid, trialDays: trialDays);
      await loadSubscription(uid);
    } catch (e) {
      _setError(runtimeL10n().subscriptionStartTrialError('$e'));
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
      _setError(runtimeL10n().subscriptionMarkExpiredError('$e'));
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
      _syncSelectedPlanWithSubscription();

      notifyListeners();
    } catch (e) {
      _setError(runtimeL10n().subscriptionClearError('$e'));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitSelectedPlan() async {
    final uid = _activeUid?.trim() ?? '';
    final plan = _selectedPlan;
    if (uid.isEmpty || plan == null) {
      return false;
    }

    try {
      _setSubmitting(true);
      _setError(null);
      _registrationStatus = SubscriptionRegistrationStatus.idle;
      notifyListeners();

      if (plan.isContactOnly) {
        await _repository.requestSchoolPlanContact(uid: uid, plan: plan);
        _registrationStatus = SubscriptionRegistrationStatus.contactRequested;
      } else {
        await _repository.registerPlan(uid: uid, plan: plan);
        _registrationStatus = SubscriptionRegistrationStatus.registered;
      }

      await loadSubscription(uid);
      return true;
    } catch (e) {
      _registrationStatus = SubscriptionRegistrationStatus.failed;
      _setError(runtimeL10n().subscriptionActivateError('$e'));
      return false;
    } finally {
      _setSubmitting(false);
    }
  }

  void clearRegistrationStatus() {
    if (_registrationStatus == SubscriptionRegistrationStatus.idle) {
      return;
    }
    _registrationStatus = SubscriptionRegistrationStatus.idle;
    notifyListeners();
  }

  bool _computeIsActive(SubscriptionInfo? sub) {
    return sub?.isActiveNow ?? false;
  }

  void _syncSelectedPlanWithSubscription() {
    if (_plans.isEmpty) {
      _selectedPlan = null;
      return;
    }

    final currentProductId =
        _subscription?.productId?.trim().toLowerCase() ?? '';

    SubscriptionCatalogPlan? resolved;

    if (currentProductId.isNotEmpty) {
      resolved = _findPlanById(currentProductId);
    }

    resolved ??= switch (_subscription?.effectivePlan) {
      SubscriptionPlan.pro => _findPlanById('premium'),
      SubscriptionPlan.free => _findPlanById('basic'),
      null => null,
    };

    SubscriptionCatalogPlan? highlightedPlan;
    for (final plan in _plans) {
      if (plan.isHighlighted) {
        highlightedPlan = plan;
        break;
      }
    }

    _selectedPlan ??= resolved ?? highlightedPlan;
    _selectedPlan ??= _plans.first;

    if (resolved != null) {
      _selectedPlan = resolved;
    }
  }

  SubscriptionCatalogPlan? _findPlanById(String id) {
    for (final plan in _plans) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _subscriptionStream?.cancel();
    super.dispose();
  }
}

class SubscriptionVM extends SubscriptionViewModel {
  SubscriptionVM(super.repository);
}
