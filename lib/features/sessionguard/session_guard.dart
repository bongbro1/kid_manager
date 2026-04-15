import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/features/permissions/child_supervision_setup_prompt.dart';
import 'package:kid_manager/features/permissions/permission_onboarding_flow.dart';
import 'package:kid_manager/features/sessionguard/session_bootstrap_coordinator.dart';
import 'package:kid_manager/features/sessionguard/session_guard_state.dart';
import 'package:kid_manager/features/sessionguard/session_permission_gate.dart';
import 'package:kid_manager/features/sessionguard/tracking_warmup_controller.dart';
import 'package:kid_manager/features/sessionguard/tracking_warmup_snapshot.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/auth/flash_screen.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _loading = true;
  bool _showFlash = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = context.read<StorageService>();
    final appVM = context.read<AppManagementVM>();
    final appInitVm = context.read<AppInitVM>();

    final hasSeenFlash = storage.getBool(StorageKeys.flashSeenV1) ?? false;

    if (!mounted) return;

    if (!hasSeenFlash) {
      setState(() {
        _showFlash = true;
        _loading = false;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(appVM.loadAndSeedApp());
      unawaited(appInitVm.init());
    });

    if (!mounted) return;

    setState(() {
      _showFlash = false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingOverlay();
    }

    if (_showFlash) {
      return const FlashScreen();
    }

    return const SessionGuard();
  }
}

class SessionGuard extends StatelessWidget {
  const SessionGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector3<SessionVM, UserVm, AuthVM, _SessionGuardViewData>(
      selector: (_, session, userVm, authVm) =>
          _SessionGuardViewData.fromSources(
            session: session,
            userVm: userVm,
            isLoggingOut: authVm.logoutInProgress,
          ),
      builder: (context, view, _) => SessionBootstrapCoordinator(
        resolvedSession: view.resolvedSession,
        isLoggingOut: view.isLoggingOut,
        child: _buildShell(context, view),
      ),
    );
  }

  Widget _buildShell(
    BuildContext context,
    _SessionGuardViewData view,
  ) {
    final resolvedSession = view.resolvedSession;
    final uid = resolvedSession.uid;

    switch (resolvedSession.status) {
      case SessionStatus.booting:
        return const AppLoadingScreen();
      case SessionStatus.unauthenticated:
        return const SessionPermissionGate(
          role: UserRole.child,
          copyModeOverride: PermissionOnboardingCopyMode.sharedDevice,
          child: LoginScreen(),
        );
      case SessionStatus.authenticated:
        if (uid == null || uid.isEmpty || !resolvedSession.hasResolvedIdentity) {
          return const AppLoadingScreen();
        }

        final trackingSnapshot = TrackingWarmupSnapshot(
          uid: uid,
          role: resolvedSession.role,
          familyId: resolvedSession.familyId,
          parentUid: resolvedSession.parentUid,
          allowTracking: view.allowTracking,
          displayName: view.displayName,
          timeZone: view.timeZone,
          locationMemberIds: view.locationMemberIds,
        );

        if (resolvedSession.isParent) {
          return TrackingWarmupController(
            snapshot: trackingSnapshot,
            child: const AppShell(mode: AppMode.parent),
          );
        }

        if (resolvedSession.isGuardian) {
          return ChangeNotifierProvider(
            create: (context) => ChildLocationViewModel(
              context.read<LocationRepository>(),
              context.read<LocationServiceInterface>(),
            ),
            child: TrackingWarmupController(
              snapshot: trackingSnapshot,
              child: const AppShell(mode: AppMode.guardian),
            ),
          );
        }

        return ChangeNotifierProvider(
          create: (context) => ChildLocationViewModel(
            context.read<LocationRepository>(),
            context.read<LocationServiceInterface>(),
          ),
          child: TrackingWarmupController(
            snapshot: trackingSnapshot,
            child: const ChildSupervisionSetupPrompt(
              child: AppShell(mode: AppMode.child),
            ),
          ),
        );
    }
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

@immutable
class _SessionGuardViewData {
  const _SessionGuardViewData({
    required this.resolvedSession,
    required this.isLoggingOut,
    required this.allowTracking,
    required this.displayName,
    required this.timeZone,
    required this.locationMemberIds,
  });

  final SessionGuardResolvedState resolvedSession;
  final bool isLoggingOut;
  final bool allowTracking;
  final String displayName;
  final String timeZone;
  final List<String> locationMemberIds;

  static _SessionGuardViewData fromSources({
    required SessionVM session,
    required UserVm userVm,
    required bool isLoggingOut,
  }) {
    final uid = session.user?.uid;
    final liveUser = _currentLiveUser(userVm, uid);
    final profile = _currentProfile(userVm, uid);
    final resolvedSession = SessionGuardResolvedState.fromSources(
      status: session.status,
      sessionUser: session.user,
      liveUser: liveUser,
      profile: profile,
    );

    final normalizedDisplayName =
        (profile?.name ??
                liveUser?.displayName ??
                session.user?.displayName ??
                '')
            .trim();
    final normalizedTimeZone =
        (profile?.timezone ?? liveUser?.timezone ?? session.user?.timezone ?? '')
            .trim();
    final sortedLocationMemberIds = <String>[
      ...userVm.locationMemberIds,
    ]..sort();

    return _SessionGuardViewData(
      resolvedSession: resolvedSession,
      isLoggingOut: isLoggingOut,
      allowTracking:
          profile?.allowTracking ??
          liveUser?.allowTracking ??
          session.user?.allowTracking ??
          false,
      displayName: normalizedDisplayName,
      timeZone: normalizedTimeZone,
      locationMemberIds: List<String>.unmodifiable(sortedLocationMemberIds),
    );
  }

  static AppUser? _currentLiveUser(UserVm userVm, String? uid) {
    final user = userVm.me;
    if (uid == null || user == null || user.uid != uid) {
      return null;
    }
    return user;
  }

  static UserProfile? _currentProfile(UserVm userVm, String? uid) {
    final profile = userVm.profile;
    if (uid == null || profile == null || profile.id != uid) {
      return null;
    }
    return profile;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _SessionGuardViewData &&
        other.resolvedSession == resolvedSession &&
        other.isLoggingOut == isLoggingOut &&
        other.allowTracking == allowTracking &&
        other.displayName == displayName &&
        other.timeZone == timeZone &&
        listEquals(other.locationMemberIds, locationMemberIds);
  }

  @override
  int get hashCode => Object.hash(
    resolvedSession,
    isLoggingOut,
    allowTracking,
    displayName,
    timeZone,
    Object.hashAll(locationMemberIds),
  );
}
