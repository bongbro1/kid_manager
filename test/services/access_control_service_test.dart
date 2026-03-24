import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/access_control/feature_policy.dart';

void main() {
  late AccessControlService service;

  setUp(() {
    service = AccessControlService();
  });

  AppUser buildUser({
    required String uid,
    required UserRole role,
    String? parentUid,
    List<String> managedChildIds = const <String>[],
    SubscriptionInfo? subscription,
    bool allowTracking = true,
  }) {
    return AppUser(
      uid: uid,
      role: role,
      parentUid: parentUid,
      managedChildIds: managedChildIds,
      subscription: subscription,
      allowTracking: allowTracking,
    );
  }

  final freeSubscription = SubscriptionInfo(
    plan: SubscriptionPlan.free,
    status: SubscriptionStatus.active,
  );

  final proSubscription = SubscriptionInfo(
    plan: SubscriptionPlan.pro,
    status: SubscriptionStatus.active,
  );

  group('canUseFeature', () {
    test('parent can use safe route on free plan', () {
      final parent = buildUser(
        uid: 'parent-1',
        role: UserRole.parent,
        subscription: freeSubscription,
      );

      expect(
        service.canUseFeature(
          feature: AppFeature.safeRoute,
          actor: parent,
        ),
        isTrue,
      );
      expect(
        service.limitForFeature(
          AppFeature.safeRoute,
          subscription: freeSubscription,
        ),
        3,
      );
    });

    test('free plan can use zone features but remains quota limited', () {
      final guardian = buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        subscription: freeSubscription,
      );

      expect(
        service.canUseFeature(
          feature: AppFeature.safeZone,
          actor: guardian,
        ),
        isTrue,
      );
      expect(
        service.canUseFeature(
          feature: AppFeature.dangerZone,
          actor: guardian,
        ),
        isTrue,
      );
      expect(
        service.limitForFeature(
          AppFeature.safeZone,
          subscription: freeSubscription,
        ),
        3,
      );
    });

    test('pro plan is unlimited for zone features', () {
      expect(
        service.limitForFeature(
          AppFeature.safeZone,
          subscription: proSubscription,
        ),
        isNull,
      );
    });

    test('pro-only policy stays easy to configure', () {
      final service = AccessControlService(
        policies: {
          AppFeature.safeRoute: const FeaturePolicy.proOnly(
            feature: AppFeature.safeRoute,
            allowedRoles: {UserRole.parent, UserRole.guardian},
          ),
        },
      );
      final parent = buildUser(
        uid: 'parent-1',
        role: UserRole.parent,
        subscription: freeSubscription,
      );

      expect(
        service.canUseFeature(
          feature: AppFeature.safeRoute,
          actor: parent,
        ),
        isFalse,
      );
      expect(
        service.canUseFeature(
          feature: AppFeature.safeRoute,
          actor: parent,
          subscription: proSubscription,
        ),
        isTrue,
      );
    });

    test('child cannot use app management', () {
      final child = buildUser(uid: 'child-1', role: UserRole.child);

      expect(
        service.canUseFeature(
          feature: AppFeature.appManagement,
          actor: child,
        ),
        isFalse,
      );
    });
  });

  group('child ownership', () {
    final child = buildUser(
      uid: 'child-1',
      role: UserRole.child,
      parentUid: 'parent-1',
    );

    test('parent can manage own child', () {
      final parent = buildUser(uid: 'parent-1', role: UserRole.parent);

      expect(
        service.canManageChild(
          actor: parent,
          childUid: child.uid,
          child: child,
        ),
        isTrue,
      );
    });

    test('guardian can manage only assigned child', () {
      final guardian = buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        managedChildIds: ['child-1'],
      );

      expect(
        service.canManageChild(
          actor: guardian,
          childUid: child.uid,
          child: child,
        ),
        isTrue,
      );
      expect(
        service.canManageChild(
          actor: guardian,
          childUid: 'child-2',
          childParentUid: 'parent-1',
        ),
        isFalse,
      );
    });

    test('guardian cannot manage sibling child without assignment', () {
      final guardian = buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        managedChildIds: ['child-1'],
      );

      expect(
        service.canManageChild(
          actor: guardian,
          childUid: 'child-2',
          childParentUid: 'parent-1',
          guardianAssignedChildIds: const ['child-1'],
        ),
        isFalse,
      );
    });

    test('guardian cannot manage child of another parent', () {
      final guardian = buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-2',
        managedChildIds: ['child-1'],
      );

      expect(
        service.canManageChild(
          actor: guardian,
          childUid: child.uid,
          child: child,
        ),
        isFalse,
      );
    });

    test('child can access self but cannot manage others', () {
      final actor = buildUser(uid: 'child-1', role: UserRole.child);

      expect(
        service.canAccessChild(
          actor: actor,
          childUid: 'child-1',
        ),
        isTrue,
      );
      expect(
        service.canManageChild(
          actor: actor,
          childUid: 'child-1',
        ),
        isFalse,
      );
    });
  });

  group('location access', () {
    test('assigned guardian can view child location', () {
      final guardian = buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        managedChildIds: ['child-1'],
      );
      final child = buildUser(
        uid: 'child-1',
        role: UserRole.child,
        parentUid: 'parent-1',
      );

      expect(
        service.canViewLocation(
          actor: guardian,
          childUid: child.uid,
          childAllowsTracking: true,
          child: child,
        ),
        isTrue,
      );
    });

    test('guardian cannot view child location when tracking is disabled', () {
      final guardian = buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        managedChildIds: ['child-1'],
      );
      final child = buildUser(
        uid: 'child-1',
        role: UserRole.child,
        parentUid: 'parent-1',
        allowTracking: false,
      );

      expect(
        service.canViewLocation(
          actor: guardian,
          childUid: child.uid,
          childAllowsTracking: false,
          child: child,
        ),
        isFalse,
      );
    });
  });
}
