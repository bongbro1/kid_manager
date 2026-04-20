import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_subscription.dart';

class SubscriptionRepository {
  final FirebaseFirestore _firestore;
  SubscriptionRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

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
  }) async {
    final subscription = SubscriptionInfo(
      plan: plan,
      status: SubscriptionStatus.active,
      startAt: startAt ?? DateTime.now(),
      endAt: endAt,
    );

    await updateSubscription(uid: uid, subscription: subscription);
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
}
