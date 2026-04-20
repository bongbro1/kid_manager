import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/access_control/feature_policy.dart';

class AccessControlService {
  AccessControlService({
    Map<AppFeature, FeaturePolicy>? policies,
    Map<AppFeatureBundle, FeatureBundlePolicy>? bundlePolicies,
  }) : _policies = policies ?? FeaturePolicyCatalog.defaults,
       _bundlePolicies = bundlePolicies ?? FeaturePolicyCatalog.bundlePolicies;

  final Map<AppFeature, FeaturePolicy> _policies;
  final Map<AppFeatureBundle, FeatureBundlePolicy> _bundlePolicies;

  bool canUseFeature({
    required AppFeature feature,
    required AppUser actor,
    SubscriptionInfo? subscription,
  }) {
    final policy = _policies[feature];
    if (policy == null) {
      return false;
    }

    final effectivePlan = _resolvePlan(
      subscription: subscription ?? actor.subscription,
    );

    return policy.allowsRole(actor.role) &&
        policy.allowsPlan(effectivePlan, bundlePolicies: _bundlePolicies);
  }

  bool canAddManagedAccounts({
    required AppUser actor,
    SubscriptionInfo? subscription,
  }) {
    return canUseFeature(
      feature: AppFeature.accountProvisioning,
      actor: actor,
      subscription: subscription,
    );
  }

  bool canAccessChild({
    required AppUser actor,
    required String childUid,
    AppUser? child,
    String? childParentUid,
    Iterable<String>? guardianAssignedChildIds,
  }) {
    final normalizedChildUid = childUid.trim();
    if (normalizedChildUid.isEmpty) {
      return false;
    }

    if (child != null && child.role != UserRole.child) {
      return false;
    }

    switch (actor.role) {
      case UserRole.parent:
        return _matchesOwnedChild(
          parentUid: actor.uid,
          childUid: normalizedChildUid,
          child: child,
          childParentUid: childParentUid,
        );
      case UserRole.guardian:
        final guardianOwnerUid = actor.parentUid?.trim();
        if (guardianOwnerUid == null || guardianOwnerUid.isEmpty) {
          return false;
        }

        final assignedChildIds = _mergeAssignedChildIds(
          actorManagedChildIds: actor.managedChildIds,
          explicitAssignedChildIds: guardianAssignedChildIds,
        );
        if (!assignedChildIds.contains(normalizedChildUid)) {
          return false;
        }

        return _matchesOwnedChild(
          parentUid: guardianOwnerUid,
          childUid: normalizedChildUid,
          child: child,
          childParentUid: childParentUid,
        );
      case UserRole.child:
        return actor.uid == normalizedChildUid;
    }
  }

  bool canManageChild({
    required AppUser actor,
    required String childUid,
    AppUser? child,
    String? childParentUid,
    Iterable<String>? guardianAssignedChildIds,
  }) {
    if (actor.role == UserRole.child) {
      return false;
    }

    return canAccessChild(
      actor: actor,
      childUid: childUid,
      child: child,
      childParentUid: childParentUid,
      guardianAssignedChildIds: guardianAssignedChildIds,
    );
  }

  bool canViewLocation({
    required AppUser actor,
    required String childUid,
    required bool childAllowsTracking,
    AppUser? child,
    String? childParentUid,
    Iterable<String>? guardianAssignedChildIds,
    SubscriptionInfo? subscription,
  }) {
    if (actor.role == UserRole.child) {
      return actor.uid == childUid.trim();
    }

    if (!canUseFeature(
      feature: AppFeature.locationViewing,
      actor: actor,
      subscription: subscription,
    )) {
      return false;
    }

    if (!childAllowsTracking) {
      return false;
    }

    return canAccessChild(
      actor: actor,
      childUid: childUid,
      child: child,
      childParentUid: childParentUid,
      guardianAssignedChildIds: guardianAssignedChildIds,
    );
  }

  int? limitForFeature(AppFeature feature, {SubscriptionInfo? subscription}) {
    final policy = _policies[feature];
    if (policy?.limit == null) {
      return null;
    }
    return policy!.limit!.resolve(_resolvePlan(subscription: subscription));
  }

  SubscriptionPlan _resolvePlan({SubscriptionInfo? subscription}) {
    return subscription?.effectivePlan ?? SubscriptionPlan.free;
  }

  bool _matchesOwnedChild({
    required String parentUid,
    required String childUid,
    AppUser? child,
    String? childParentUid,
  }) {
    if (child != null) {
      return child.uid == childUid && child.parentUid == parentUid;
    }
    return childParentUid?.trim() == parentUid;
  }

  Set<String> _mergeAssignedChildIds({
    required Iterable<String> actorManagedChildIds,
    required Iterable<String>? explicitAssignedChildIds,
  }) {
    return {
      ...actorManagedChildIds
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
      ...?explicitAssignedChildIds
          ?.map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    };
  }
}
