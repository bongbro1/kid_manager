import 'package:firebase_auth/firebase_auth.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/access_control/feature_policy.dart';

enum SafeRouteAccessIssue {
  unauthenticated,
  actorNotFound,
  childNotFound,
  invalidChildTarget,
  featureDenied,
  manageDenied,
  locationFeatureDenied,
  locationAccessDenied,
  trackingDisabled,
}

class SafeRouteAccessResult {
  const SafeRouteAccessResult._({required this.issue, this.actor, this.child});

  const SafeRouteAccessResult.allowed({
    required AppUser actor,
    required AppUser child,
  }) : this._(issue: null, actor: actor, child: child);

  const SafeRouteAccessResult.denied(SafeRouteAccessIssue issue)
    : this._(issue: issue);

  final SafeRouteAccessIssue? issue;
  final AppUser? actor;
  final AppUser? child;

  bool get isAllowed => issue == null && actor != null && child != null;

  String? get ownerParentUid {
    final resolvedActor = actor;
    if (resolvedActor == null) {
      return null;
    }

    final ownerParentUid = resolvedActor.isGuardian
        ? (resolvedActor.parentUid ?? '').trim()
        : resolvedActor.uid.trim();
    return ownerParentUid.isEmpty ? null : ownerParentUid;
  }
}

SafeRouteAccessResult evaluateSafeRouteAccess({
  required AccessControlService accessControl,
  required AppUser actor,
  required AppUser child,
  bool requireManageChild = false,
  bool requireViewLocation = false,
}) {
  if (!child.isChild) {
    return const SafeRouteAccessResult.denied(
      SafeRouteAccessIssue.invalidChildTarget,
    );
  }

  if (!accessControl.canUseFeature(
    feature: AppFeature.safeRoute,
    actor: actor,
  )) {
    return const SafeRouteAccessResult.denied(
      SafeRouteAccessIssue.featureDenied,
    );
  }

  final canAccessChild = accessControl.canAccessChild(
    actor: actor,
    childUid: child.uid,
    child: child,
  );

  if (requireManageChild &&
      !accessControl.canManageChild(
        actor: actor,
        childUid: child.uid,
        child: child,
      )) {
    return const SafeRouteAccessResult.denied(
      SafeRouteAccessIssue.manageDenied,
    );
  }

  if (requireViewLocation) {
    if (!accessControl.canUseFeature(
      feature: AppFeature.locationViewing,
      actor: actor,
    )) {
      return const SafeRouteAccessResult.denied(
        SafeRouteAccessIssue.locationFeatureDenied,
      );
    }

    if (!child.allowTracking) {
      return const SafeRouteAccessResult.denied(
        SafeRouteAccessIssue.trackingDisabled,
      );
    }

    if (!canAccessChild) {
      return const SafeRouteAccessResult.denied(
        SafeRouteAccessIssue.locationAccessDenied,
      );
    }
  }

  return SafeRouteAccessResult.allowed(actor: actor, child: child);
}

Future<SafeRouteAccessResult> loadSafeRouteAccess({
  required String childId,
  required ProfileRepository profileRepository,
  required AccessControlService accessControl,
  FirebaseAuth? auth,
  bool requireManageChild = false,
  bool requireViewLocation = false,
}) async {
  final actorUid =
      auth?.currentUser?.uid.trim() ??
      FirebaseAuth.instance.currentUser?.uid.trim();
  if (actorUid == null || actorUid.isEmpty) {
    return const SafeRouteAccessResult.denied(
      SafeRouteAccessIssue.unauthenticated,
    );
  }

  final actor = await profileRepository.getUserById(actorUid);
  if (actor == null) {
    return const SafeRouteAccessResult.denied(
      SafeRouteAccessIssue.actorNotFound,
    );
  }

  final child = await profileRepository.getUserById(childId);
  if (child == null) {
    return const SafeRouteAccessResult.denied(
      SafeRouteAccessIssue.childNotFound,
    );
  }

  return evaluateSafeRouteAccess(
    accessControl: accessControl,
    actor: actor,
    child: child,
    requireManageChild: requireManageChild,
    requireViewLocation: requireViewLocation,
  );
}

String resolveSafeRouteAccessMessage(
  AppLocalizations l10n,
  SafeRouteAccessIssue issue,
) {
  final isVietnamese = l10n.localeName.toLowerCase().startsWith('vi');
  switch (issue) {
    case SafeRouteAccessIssue.unauthenticated:
    case SafeRouteAccessIssue.actorNotFound:
      return l10n.safeRouteErrorLoginAgain;
    case SafeRouteAccessIssue.childNotFound:
      return isVietnamese
          ? 'Không tìm thấy thông tin của bé này.'
          : 'Child information could not be found.';
    case SafeRouteAccessIssue.invalidChildTarget:
    case SafeRouteAccessIssue.featureDenied:
    case SafeRouteAccessIssue.manageDenied:
      return isVietnamese
          ? 'Bạn không có quyền thao tác với bé này.'
          : 'You do not have permission to manage this child.';
    case SafeRouteAccessIssue.locationFeatureDenied:
    case SafeRouteAccessIssue.locationAccessDenied:
      return isVietnamese
          ? 'Bạn không có quyền xem vị trí của bé này.'
          : 'You do not have permission to view this child location.';
    case SafeRouteAccessIssue.trackingDisabled:
      return isVietnamese
          ? 'Bé đang tắt chia sẻ vị trí nên chưa thể dùng Safe Route.'
          : 'Safe Route is unavailable because this child has location sharing turned off.';
  }
}
