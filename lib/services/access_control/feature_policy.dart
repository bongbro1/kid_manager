import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';

enum AppFeature {
  accountProvisioning,
  safeZone,
  dangerZone,
  safeRoute,
  locationSharing,
  locationViewing,
  familyChat,
  sos,
  notifications,
  appManagement,
}

enum AppFeatureBundle {
  safetyToolkit,
}

class PlanLimit {
  const PlanLimit(this.maxByPlan);

  final Map<SubscriptionPlan, int?> maxByPlan;

  int? resolve(SubscriptionPlan plan) => maxByPlan[plan];

  bool isUnlimited(SubscriptionPlan plan) => resolve(plan) == null;
}

class FeatureBundlePolicy {
  const FeatureBundlePolicy({
    required this.bundle,
    required this.allowedPlans,
  });

  const FeatureBundlePolicy.proOnly({
    required AppFeatureBundle bundle,
  }) : this(
         bundle: bundle,
         allowedPlans: const {SubscriptionPlan.pro},
       );

  const FeatureBundlePolicy.freeWithQuota({
    required AppFeatureBundle bundle,
  }) : this(
         bundle: bundle,
         allowedPlans: const {
           SubscriptionPlan.free,
           SubscriptionPlan.pro,
         },
       );

  final AppFeatureBundle bundle;
  final Set<SubscriptionPlan> allowedPlans;

  bool allowsPlan(SubscriptionPlan plan) => allowedPlans.contains(plan);
}

class FeaturePolicy {
  const FeaturePolicy({
    required this.feature,
    required this.allowedRoles,
    this.allowedPlans = const {},
    this.bundle,
    this.limit,
  });

  const FeaturePolicy.proOnly({
    required AppFeature feature,
    required Set<UserRole> allowedRoles,
    PlanLimit? limit,
  }) : this(
         feature: feature,
         allowedRoles: allowedRoles,
         allowedPlans: const {SubscriptionPlan.pro},
         limit: limit,
       );

  const FeaturePolicy.freeWithQuota({
    required AppFeature feature,
    required Set<UserRole> allowedRoles,
    required PlanLimit limit,
  }) : this(
         feature: feature,
         allowedRoles: allowedRoles,
         allowedPlans: const {
           SubscriptionPlan.free,
           SubscriptionPlan.pro,
         },
         limit: limit,
       );

  final AppFeature feature;
  final Set<UserRole> allowedRoles;
  final Set<SubscriptionPlan> allowedPlans;
  final AppFeatureBundle? bundle;
  final PlanLimit? limit;

  bool allowsRole(UserRole role) => allowedRoles.contains(role);

  bool allowsPlan(
    SubscriptionPlan plan, {
    required Map<AppFeatureBundle, FeatureBundlePolicy> bundlePolicies,
  }) {
    final featureBundle = bundle;
    if (featureBundle != null) {
      final bundlePolicy = bundlePolicies[featureBundle];
      if (bundlePolicy == null) {
        return false;
      }
      return bundlePolicy.allowsPlan(plan);
    }
    return allowedPlans.contains(plan);
  }
}

class FeaturePolicyCatalog {
  const FeaturePolicyCatalog._();

  static const sharedZoneLimit = PlanLimit({
    SubscriptionPlan.free: 3,
    SubscriptionPlan.pro: null,
  });

  static const sharedSafeRouteLimit = PlanLimit({
    SubscriptionPlan.free: 3,
    SubscriptionPlan.pro: null,
  });

  static const Map<AppFeatureBundle, FeatureBundlePolicy> bundlePolicies = {
    AppFeatureBundle.safetyToolkit: FeatureBundlePolicy.freeWithQuota(
      bundle: AppFeatureBundle.safetyToolkit,
    ),
  };

  static const Map<AppFeature, FeaturePolicy> defaults = {
    AppFeature.accountProvisioning: FeaturePolicy(
      feature: AppFeature.accountProvisioning,
      allowedRoles: {UserRole.parent},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
    AppFeature.safeZone: FeaturePolicy(
      feature: AppFeature.safeZone,
      allowedRoles: {UserRole.parent, UserRole.guardian},
      bundle: AppFeatureBundle.safetyToolkit,
      limit: sharedZoneLimit,
    ),
    AppFeature.dangerZone: FeaturePolicy(
      feature: AppFeature.dangerZone,
      allowedRoles: {UserRole.parent, UserRole.guardian},
      bundle: AppFeatureBundle.safetyToolkit,
      limit: sharedZoneLimit,
    ),
    AppFeature.safeRoute: FeaturePolicy(
      feature: AppFeature.safeRoute,
      allowedRoles: {UserRole.parent, UserRole.guardian},
      bundle: AppFeatureBundle.safetyToolkit,
      limit: sharedSafeRouteLimit,
    ),
    AppFeature.locationSharing: FeaturePolicy(
      feature: AppFeature.locationSharing,
      allowedRoles: {UserRole.child, UserRole.guardian},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
    AppFeature.locationViewing: FeaturePolicy(
      feature: AppFeature.locationViewing,
      allowedRoles: {UserRole.parent, UserRole.guardian, UserRole.child},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
    AppFeature.familyChat: FeaturePolicy(
      feature: AppFeature.familyChat,
      allowedRoles: {UserRole.parent, UserRole.guardian, UserRole.child},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
    AppFeature.sos: FeaturePolicy(
      feature: AppFeature.sos,
      allowedRoles: {UserRole.parent, UserRole.guardian, UserRole.child},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
    AppFeature.notifications: FeaturePolicy(
      feature: AppFeature.notifications,
      allowedRoles: {UserRole.parent, UserRole.guardian, UserRole.child},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
    AppFeature.appManagement: FeaturePolicy(
      feature: AppFeature.appManagement,
      allowedRoles: {UserRole.parent, UserRole.guardian},
      allowedPlans: {SubscriptionPlan.free, SubscriptionPlan.pro},
    ),
  };
}
