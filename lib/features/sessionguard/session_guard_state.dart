import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';

class SessionGuardResolvedState {
  const SessionGuardResolvedState({
    required this.status,
    required this.uid,
    required this.role,
    required this.familyId,
    required this.parentUid,
  });

  final SessionStatus status;
  final String? uid;
  final UserRole role;
  final String familyId;
  final String parentUid;

  bool get hasResolvedIdentity => familyId.isNotEmpty || parentUid.isNotEmpty;
  bool get isParent => role == UserRole.parent;
  bool get isGuardian => role == UserRole.guardian;
  bool get isLocationViewer => isParent || isGuardian;

  static SessionGuardResolvedState fromSources({
    required SessionStatus status,
    AppUser? sessionUser,
    AppUser? liveUser,
    UserProfile? profile,
  }) {
    return SessionGuardResolvedState(
      status: status,
      uid: sessionUser?.uid ?? liveUser?.uid ?? profile?.id,
      role: profile?.role ?? liveUser?.role ?? sessionUser?.role ?? UserRole.child,
      familyId: _firstNonEmpty([
        profile?.familyId,
        liveUser?.familyId,
        sessionUser?.familyId,
      ]),
      parentUid: _firstNonEmpty([
        profile?.parentUid,
        liveUser?.parentUid,
        sessionUser?.parentUid,
      ]),
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }
}
