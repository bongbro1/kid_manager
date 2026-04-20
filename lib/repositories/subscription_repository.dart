import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/subscription/subscription_catalog_plan.dart';
import 'package:kid_manager/models/user/user_subscription.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  SubscriptionRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _plansRef =>
      _firestore.collection('subscription_plans');
  CollectionReference<Map<String, dynamic>> get _registrationsRef =>
      _firestore.collection('subscription_registrations');
  CollectionReference<Map<String, dynamic>> get _contactRequestsRef =>
      _firestore.collection('subscription_contact_requests');

  static const List<SubscriptionCatalogPlan> _defaultPlans = [
    SubscriptionCatalogPlan(
      id: 'basic',
      entitlementPlan: SubscriptionPlan.free,
      sortOrder: 0,
    ),
    SubscriptionCatalogPlan(
      id: 'premium',
      entitlementPlan: SubscriptionPlan.pro,
      sortOrder: 1,
      isHighlighted: true,
    ),
    SubscriptionCatalogPlan(
      id: 'school',
      entitlementPlan: SubscriptionPlan.pro,
      sortOrder: 2,
      isContactOnly: true,
    ),
  ];

  Future<List<SubscriptionCatalogPlan>> fetchPlans() async {
    final snapshot = await _plansRef.orderBy('sortOrder').get();
    if (snapshot.docs.isEmpty) {
      await _seedDefaultPlans();
      return _defaultPlans;
    }

    final plans =
        snapshot.docs
            .map((doc) {
              final data = doc.data();
              final merged = <String, dynamic>{'id': doc.id, ...data};
              return SubscriptionCatalogPlan.fromMap(merged);
            })
            .where((plan) => plan.id.isNotEmpty && plan.isActive)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return plans.isEmpty ? _defaultPlans : plans;
  }

  Future<SubscriptionInfo?> getSubscription(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['subscription'] == null) return null;

    return SubscriptionInfo.fromMap(
      Map<String, dynamic>.from(data['subscription']),
    );
  }

  Stream<SubscriptionInfo?> watchSubscription(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['subscription'] == null) return null;

      return SubscriptionInfo.fromMap(
        Map<String, dynamic>.from(data['subscription']),
      );
    });
  }

  Future<void> updateSubscription({
    required String uid,
    required SubscriptionInfo subscription,
  }) async {
    await _usersRef.doc(uid).set({
      'subscription': subscription.toMap(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearSubscription(String uid) async {
    await _usersRef.doc(uid).set({
      'subscription': FieldValue.delete(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> activatePlan({
    required String uid,
    required SubscriptionPlan plan,
    DateTime? startAt,
    DateTime? endAt,
    String? productId,
    String? platform,
  }) async {
    final subscription = SubscriptionInfo(
      plan: plan,
      status: SubscriptionStatus.active,
      startAt: startAt ?? DateTime.now(),
      endAt: endAt,
      productId: productId,
      platform: platform,
    );

    await updateSubscription(uid: uid, subscription: subscription);
  }

  Future<void> registerPlan({
    required String uid,
    required SubscriptionCatalogPlan plan,
  }) async {
    final now = DateTime.now();

    await activatePlan(
      uid: uid,
      plan: plan.entitlementPlan,
      startAt: now,
      productId: plan.id,
      platform: 'manual',
    );

    await _registrationsRef.add({
      'uid': uid,
      'planId': plan.id,
      'entitlementPlan': plan.entitlementPlan.wireValue,
      'status': 'registered',
      'source': 'app',
      'isContactOnly': plan.isContactOnly,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> requestSchoolPlanContact({
    required String uid,
    required SubscriptionCatalogPlan plan,
  }) async {
    final user = await getUser(uid);

    await _contactRequestsRef.add({
      'uid': uid,
      'planId': plan.id,
      'entitlementPlan': plan.entitlementPlan.wireValue,
      'source': 'app',
      'status': 'pending',
      'displayName': user?.displayName,
      'email': user?.email,
      'phone': user?.phone,
      'familyId': user?.familyId,
      'requestedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markExpired(String uid) async {
    final current = await getSubscription(uid);
    if (current == null) return;

    final updated = current.copyWith(status: SubscriptionStatus.expired);

    await updateSubscription(uid: uid, subscription: updated);
  }

  Future<void> startTrial({required String uid, int trialDays = 7}) async {
    final now = DateTime.now();

    final subscription = SubscriptionInfo(
      plan: SubscriptionPlan.pro,
      status: SubscriptionStatus.trial,
      startAt: now,
      endAt: now.add(Duration(days: trialDays)),
    );

    await updateSubscription(uid: uid, subscription: subscription);
  }

  Future<bool> isSubscriptionActive(String uid) async {
    final sub = await getSubscription(uid);
    return sub?.isActiveNow ?? false;
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<void> _seedDefaultPlans() async {
    final batch = _firestore.batch();

    for (final plan in _defaultPlans) {
      batch.set(_plansRef.doc(plan.id), plan.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }
}
