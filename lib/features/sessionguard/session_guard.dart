import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/background/auth_runtime_manager.dart';
import 'package:kid_manager/background/tracking_background_service.dart';
import 'package:kid_manager/background/tracking_runtime_store.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/features/permissions/permission_onboarding_flow.dart';
import 'package:kid_manager/features/sessionguard/session_guard_state.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/services/location/device_time_zone_service.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';
import 'package:kid_manager/services/notifications/sos_tap_router.dart';
import 'package:kid_manager/services/notifications/sos_notification_service.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
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
  bool _showPermission = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = context.read<StorageService>();
    final appVM = context.read<AppManagementVM>();

    final hasSeenFlash = storage.getBool(StorageKeys.flashSeenV1) ?? false;

    if (!mounted) return;

    // ❗ LẦN ĐẦU → KHÔNG check permission gì hết
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
    });

    // 👉 Sau khi qua flash mới check
    final permissionService = context.read<PermissionService>();

    final hasSeenPermissionFlow =
        storage.getBool(StorageKeys.permissionOnboardingSeenV1) ?? false;

    final permissionResults = await permissionService.checkAllPermissions();

    final hasMissingPermissions = permissionResults.values.any((e) => !e);

    if (!mounted) return;

    setState(() {
      _showFlash = false;
      _showPermission = !hasSeenPermissionFlow || hasMissingPermissions;
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

    if (_showPermission) {
      return PermissionOnboardingFlow(
        onFinished: (_) async {
          await context.read<StorageService>().setBool(
            StorageKeys.permissionOnboardingSeenV1,
            true,
          );

          if (!mounted) return;

          setState(() {
            _showPermission = false;
          });
        },
      );
    }

    return const SessionGuard();
  }
}

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard>
    with WidgetsBindingObserver {
  SessionStatus? _lastStatus;
  String? _lastUid;
  bool? _lastIsLocationViewer;
  String? _lastFamilyId;
  bool _initCalled = false;

  String? _pushInitedForUid;
  String? _bootstrappedUid;
  String? _bootstrapQueuedForUid;
  String? _bootstrapRetryScheduledForUid;
  bool _sessionBootstrapInFlight = false;
  Timer? _bootstrapRetryTimer;
  bool _sessionCleanupInFlight = false;
  String? _timeZoneSyncInFlightForUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initCalled) {
        _initCalled = true;
        context.read<AppInitVM>().init();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_syncAuthenticatedUserTimeZone());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SessionVM, UserVm>(
      builder: (context, session, userVm, _) {
        final status = session.status;
        final uid = session.user?.uid;
        final liveUser = _currentLiveUser(userVm, uid);
        final profile = _currentProfile(userVm, uid);
        final resolvedSession = SessionGuardResolvedState.fromSources(
          status: status,
          sessionUser: session.user,
          liveUser: liveUser,
          profile: profile,
        );
        final isParent = resolvedSession.isParent;
        final isGuardian = resolvedSession.isGuardian;
        final isLocationViewer = resolvedSession.isLocationViewer;
        final familyId = resolvedSession.familyId;
        final parentUid = resolvedSession.parentUid;
        final prevStatus = _lastStatus;
        final prevUid = _lastUid;

        final shouldClearSessionState =
            status == SessionStatus.unauthenticated &&
            (prevStatus != SessionStatus.unauthenticated || prevUid != null);

        final shouldEnsureSessionBootstrap =
            status == SessionStatus.authenticated &&
            uid != null &&
            (_bootstrappedUid != uid || !resolvedSession.hasResolvedIdentity) &&
            !_sessionBootstrapInFlight &&
            _bootstrapQueuedForUid != uid &&
            (_bootstrapRetryScheduledForUid != uid ||
                resolvedSession.hasResolvedIdentity);

        final shouldTriggerLocationMembersWatch =
            status == SessionStatus.authenticated &&
            isLocationViewer == true &&
            uid != null &&
            familyId.isNotEmpty &&
            (_lastStatus != status ||
                _lastUid != uid ||
                _lastIsLocationViewer != isLocationViewer ||
                _lastFamilyId != familyId);

        _lastStatus = status;
        _lastUid = uid;
        _lastIsLocationViewer = isLocationViewer;
        _lastFamilyId = familyId;

        if (shouldClearSessionState && !_sessionCleanupInFlight) {
          _sessionCleanupInFlight = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              _resetBootstrapState();
              await _clearSessionScopedState();
            } finally {
              _sessionCleanupInFlight = false;
            }
          });
        }

        if (shouldEnsureSessionBootstrap) {
          _queueSessionBootstrap(uid: uid);
        }

        if (shouldTriggerLocationMembersWatch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final currentUid = uid;
            if (currentUid.isEmpty) return;
            final normalizedFamilyId = familyId.trim();
            if (normalizedFamilyId.isEmpty) return;
            final userVm = context.read<UserVm>();
            userVm.watchFamilyMembers(normalizedFamilyId);
            userVm.watchLocationMembers(
              normalizedFamilyId,
              excludeUid: currentUid,
            );
            final managedOwnerUid = isGuardian == true ? parentUid : currentUid;
            if ((isParent == true || isGuardian == true) &&
                managedOwnerUid.isNotEmpty) {
              userVm.watchChildren(managedOwnerUid);
            }
          });
        }

        debugPrint(
          '[SessionGuard] status=$status uid=$uid '
          'hasResolvedIdentity=${resolvedSession.hasResolvedIdentity} '
          'isParent=${resolvedSession.isParent} '
          'isGuardian=${resolvedSession.isGuardian} '
          'isLocationViewer=${resolvedSession.isLocationViewer} '
          'familyId=${resolvedSession.familyId} '
          'parentUid=${resolvedSession.parentUid}',
        );

        switch (status) {
          case SessionStatus.booting:
            return const AppLoadingScreen();

          case SessionStatus.unauthenticated:
            _pushInitedForUid = null;
            return const LoginScreen();

          case SessionStatus.authenticated:
            if (uid == null) {
              return const AppLoadingScreen();
            }

            if (!resolvedSession.hasResolvedIdentity) {
              return const AppLoadingScreen();
            }

            if (isParent == true) {
              return const _ParentWarmupShell();
            }

            if (isGuardian == true) {
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                    create: (context) => ChildLocationViewModel(
                      context.read<LocationRepository>(),
                      context.read<LocationServiceInterface>(),
                    ),
                  ),
                ],
                child: const _GuardianWarmupShell(),
              );
            }

            return ChangeNotifierProvider(
              create: (context) => ChildLocationViewModel(
                context.read<LocationRepository>(),
                context.read<LocationServiceInterface>(),
              ),
              child: const _ChildWarmupShell(),
            );
        }
      },
    );
  }

  AppUser? _currentLiveUser(UserVm userVm, String? uid) {
    final user = userVm.me;
    if (uid == null || user == null || user.uid != uid) {
      return null;
    }
    return user;
  }

  UserProfile? _currentProfile(UserVm userVm, String? uid) {
    final profile = userVm.profile;
    if (uid == null || profile == null || profile.id != uid) {
      return null;
    }
    return profile;
  }

  void _queueSessionBootstrap({required String uid}) {
    _bootstrapQueuedForUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _bootstrapQueuedForUid = null;

      final currentSession = context.read<SessionVM>();
      if (currentSession.status != SessionStatus.authenticated ||
          currentSession.user?.uid != uid) {
        return;
      }

      _sessionBootstrapInFlight = true;
      try {
        await _runSessionBootstrap(uid: uid);
      } finally {
        _sessionBootstrapInFlight = false;
      }
    });
  }

  Future<void> _runSessionBootstrap({required String uid}) async {
    try {
      final userVm = context.read<UserVm>();
      final storage = context.read<StorageService>();
      final appManagementVm = context.read<AppManagementVM>();
      final notificationVm = context.read<NotificationVM>();

      final loadedProfile = await userVm.loadProfile(
        uid: uid,
        caller: 'SessionGuard',
      );

      debugPrint('[SessionGuard] loadedProfile=${loadedProfile?.id}');

      if (!mounted) return;

      final currentSession = context.read<SessionVM>();
      if (currentSession.status != SessionStatus.authenticated ||
          currentSession.user?.uid != uid) {
        return;
      }

      final liveUser = _currentLiveUser(userVm, uid);
      final profile = _currentProfile(userVm, uid) ?? loadedProfile;
      final resolvedSession = SessionGuardResolvedState.fromSources(
        status: currentSession.status,
        sessionUser: currentSession.user,
        liveUser: liveUser,
        profile: profile,
      );

      if (!resolvedSession.hasResolvedIdentity) {
        debugPrint(
          '[SessionGuard] bootstrap waiting for resolved identity uid=$uid',
        );
        _scheduleBootstrapRetry(uid);
        return;
      }

      await notificationVm.bindUser(
        uid: uid,
        sources: const [
          NotificationSource.global,
          NotificationSource.userInbox,
        ],
      );

      if (_pushInitedForUid != uid && profile != null) {
        _pushInitedForUid = uid;
        await FcmPushReceiverService.init(uid);
        if (!mounted) return;
        await SosNotificationService.instance.init(
          onTapSos: SosTapRouter.handleTap,
          role: profile.role,
        );
      }

      if (!mounted) return;

      final verifiedSession = context.read<SessionVM>();
      if (verifiedSession.status != SessionStatus.authenticated ||
          verifiedSession.user?.uid != uid) {
        return;
      }

      await storage.setString(StorageKeys.uid, uid);

      final sessionUser = verifiedSession.user;
      final resolvedRole = resolvedSession.role;
      final resolvedDisplayName =
          (profile?.name ??
                  liveUser?.displayName ??
                  sessionUser?.displayName ??
                  '')
              .trim();
      final resolvedParentOwnerUid = resolvedRole == UserRole.parent
          ? uid
          : resolvedSession.parentUid;
      final managedOwnerUid = resolvedRole == UserRole.guardian
          ? resolvedParentOwnerUid
          : uid;
      final managedChildIds =
          <String>{
                ...?profile?.managedChildIds,
                ...?liveUser?.managedChildIds,
                ...?sessionUser?.managedChildIds,
              }
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);

      await _syncAuthenticatedUserTimeZone(
        uid: uid,
        currentTimeZone: profile?.timezone ?? sessionUser?.timezone,
      );
      if (!mounted) return;

      await storage.setString(StorageKeys.role, roleToString(resolvedRole));
      if (resolvedDisplayName.isNotEmpty) {
        await storage.setString(StorageKeys.displayName, resolvedDisplayName);
      } else {
        await storage.remove(StorageKeys.displayName);
      }
      await storage.setString(StorageKeys.role, roleToString(resolvedRole));
      if (resolvedDisplayName.isNotEmpty) {
        await storage.setString(StorageKeys.displayName, resolvedDisplayName);
      } else {
        await storage.remove(StorageKeys.displayName);
      }

      if (resolvedParentOwnerUid.isNotEmpty) {
        await storage.setString(StorageKeys.parentId, resolvedParentOwnerUid);
      } else {
        await storage.remove(StorageKeys.parentId);
      }
      if (managedChildIds.isNotEmpty) {
        await storage.setStringList(
          StorageKeys.managedChildIds,
          managedChildIds,
        );
      } else {
        await storage.remove(StorageKeys.managedChildIds);
      }

      if (resolvedRole == UserRole.child) {
        if (resolvedParentOwnerUid.isNotEmpty &&
            resolvedDisplayName.isNotEmpty) {
          AuthRuntimeManager.start(
            parentId: resolvedParentOwnerUid,
            displayName: resolvedDisplayName,
          );
        } else {
          debugPrint(
            '[SessionGuard] skip native watcher config '
            'uid=$uid parentId="$resolvedParentOwnerUid" '
            'displayName="$resolvedDisplayName"',
          );
        }
      } else {
        await AuthRuntimeManager.stop();
      }

      userVm.watchMe(uid);

      if ((resolvedRole == UserRole.parent ||
              resolvedRole == UserRole.guardian) &&
          managedOwnerUid.isNotEmpty) {
        unawaited(appManagementVm.watchChildren(managedOwnerUid));
      }

      _bootstrappedUid = uid;
      _bootstrapRetryScheduledForUid = null;
    } catch (e, st) {
      debugPrint('[SessionGuard] bootstrap failed uid=$uid error=$e');
      debugPrintStack(stackTrace: st);
      _scheduleBootstrapRetry(uid);
    }
  }

  void _scheduleBootstrapRetry(String uid) {
    if (_bootstrapRetryScheduledForUid == uid) return;
    _bootstrapRetryScheduledForUid = uid;
    _bootstrapRetryTimer?.cancel();
    _bootstrapRetryTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final session = context.read<SessionVM>();
      if (session.status != SessionStatus.authenticated ||
          session.user?.uid != uid) {
        _bootstrapRetryScheduledForUid = null;
        return;
      }
      _bootstrapRetryScheduledForUid = null;
      setState(() {});
    });
  }

  void _resetBootstrapState() {
    _bootstrappedUid = null;
    _bootstrapQueuedForUid = null;
    _bootstrapRetryScheduledForUid = null;
    _bootstrapRetryTimer?.cancel();
    _bootstrapRetryTimer = null;
    _sessionBootstrapInFlight = false;
  }

  Future<void> _clearSessionScopedState() async {
    if (!mounted) return;

    final notificationVm = context.read<NotificationVM>();
    final userVm = context.read<UserVm>();
    final appManagementVm = context.read<AppManagementVM>();
    final parentLocationVm = context.read<ParentLocationVm>();
    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    await notificationVm.clear();
    await userVm.clear();
    await appManagementVm.clear();
    await parentLocationVm.stopWatchingAllChildren();
    await parentLocationVm.stopMyLocation();
    await TrackingBackgroundService.stop();
    await AuthRuntimeManager.stop();
    scheduleVm.resetForNewSession();
    memoryVm.resetForNewSession();
    birthdayVm.resetForNewSession();
    _pushInitedForUid = null;
  }

  Future<void> _syncAuthenticatedUserTimeZone({
    String? uid,
    String? currentTimeZone,
  }) async {
    if (!mounted) return;

    final session = context.read<SessionVM>();
    if (session.status != SessionStatus.authenticated) {
      return;
    }

    final resolvedUid = (uid ?? session.user?.uid)?.trim();
    if (resolvedUid == null || resolvedUid.isEmpty) {
      return;
    }
    final authUid = FirebaseAuth.instance.currentUser?.uid?.trim();
    if (authUid == null || authUid.isEmpty || authUid != resolvedUid) {
      debugPrint(
        '[SessionGuard] skip timezone sync until auth uid matches session '
        'uid authUid=$authUid sessionUid=$resolvedUid',
      );
      return;
    }
    if (_timeZoneSyncInFlightForUid == resolvedUid) {
      return;
    }

    _timeZoneSyncInFlightForUid = resolvedUid;
    try {
      final normalizedTimeZone = await DeviceTimeZoneService.instance
          .getDeviceTimeZone();
      final userVm = context.read<UserVm>();
      await userVm.syncUserTimeZone(
        uid: resolvedUid,
        timeZone: normalizedTimeZone,
        currentTimeZone:
            currentTimeZone ??
            userVm.profile?.timezone ??
            userVm.me?.timezone ??
            session.user?.timezone,
      );
      await TrackingRuntimeStore.syncTimeZone(
        userId: resolvedUid,
        timeZone: normalizedTimeZone,
      );
    } catch (e, st) {
      debugPrint('[SessionGuard] sync timezone error: $e');
      debugPrint('$st');
    } finally {
      if (_timeZoneSyncInFlightForUid == resolvedUid) {
        _timeZoneSyncInFlightForUid = null;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _ParentWarmupShell extends StatefulWidget {
  const _ParentWarmupShell();

  @override
  State<_ParentWarmupShell> createState() => _ParentWarmupShellState();
}

class _ParentWarmupShellState extends State<_ParentWarmupShell> {
  bool _started = false;

  late final UserVm _userVm;
  late final ParentLocationVm _locationVm;
  Timer? _syncChildrenDebounce;
  Set<String> _lastSyncedChildren = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _userVm = context.read<UserVm>();
    _locationVm = context.read<ParentLocationVm>();

    _userVm.addListener(_onUserChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _syncChildrenWatch();
      unawaited(_locationVm.startMyLocation());
    });
  }

  void _onUserChanged() {
    _syncChildrenWatch();
  }

  void _syncChildrenWatch() {
    if (!mounted) return;

    _syncChildrenDebounce?.cancel();
    _syncChildrenDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      final latestIds = _userVm.locationMemberIds.toSet();
      if (setEquals(latestIds, _lastSyncedChildren)) return;

      _lastSyncedChildren = latestIds;
      unawaited(_locationVm.syncWatching(latestIds.toList()));
    });
  }

  @override
  void dispose() {
    _userVm.removeListener(_onUserChanged);
    _syncChildrenDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell(mode: AppMode.parent);
  }
}

class _GuardianWarmupShell extends StatefulWidget {
  const _GuardianWarmupShell();

  @override
  State<_GuardianWarmupShell> createState() => _GuardianWarmupShellState();
}

class _GuardianWarmupShellState extends State<_GuardianWarmupShell> {
  bool _started = false;
  bool _selfTrackingActive = false;

  late final UserVm _userVm;
  late final ParentLocationVm _locationVm;
  late final ChildLocationViewModel _childLocationVm;
  late final LocationServiceInterface _locationService;
  Timer? _syncMembersDebounce;
  Set<String> _lastSyncedMembers = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _userVm = context.read<UserVm>();
    _locationVm = context.read<ParentLocationVm>();
    _childLocationVm = context.read<ChildLocationViewModel>();
    _locationService = context.read<LocationServiceInterface>();

    _userVm.addListener(_onUserChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _syncWatching();
      unawaited(_locationVm.startMyLocation());
      await _syncSelfTracking();
    });
  }

  void _onUserChanged() {
    _syncWatching();
    unawaited(_syncSelfTracking());
  }

  void _syncWatching() {
    if (!mounted) return;

    _syncMembersDebounce?.cancel();
    _syncMembersDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      final latestIds = _userVm.locationMemberIds.toSet();
      if (setEquals(latestIds, _lastSyncedMembers)) return;

      _lastSyncedMembers = latestIds;
      unawaited(_locationVm.syncWatching(latestIds.toList()));
    });
  }

  Future<void> _syncSelfTracking() async {
    final me = _userVm.me;
    final shouldShare = me?.isGuardian == true && me?.allowTracking == true;

    if (shouldShare && !_selfTrackingActive) {
      final hasForegroundPermission = await _locationService
          .hasLocationPermission(requireBackground: false);
      final serviceEnabled = await _locationService.isServiceEnabled();
      if (!hasForegroundPermission || !serviceEnabled) {
        return;
      }

      await _childLocationVm.startLocationSharing(background: true);
      _selfTrackingActive = _childLocationVm.isSharing;
      return;
    }

    if (!shouldShare && _selfTrackingActive) {
      await _childLocationVm.stopSharing(clearData: false);
      _selfTrackingActive = false;
    }
  }

  @override
  void dispose() {
    _userVm.removeListener(_onUserChanged);
    _syncMembersDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell(mode: AppMode.guardian);
  }
}

class _ChildWarmupShell extends StatefulWidget {
  const _ChildWarmupShell();

  @override
  State<_ChildWarmupShell> createState() => _ChildWarmupShellState();
}

class _ChildWarmupShellState extends State<_ChildWarmupShell> {
  bool _ready = false;
  bool _started = false;
  bool _selfTrackingActive = false;

  late final UserVm _userVm;
  late final ChildLocationViewModel _childLocationVm;
  late final LocationServiceInterface _locationService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _userVm = context.read<UserVm>();
    _childLocationVm = context.read<ChildLocationViewModel>();
    _locationService = context.read<LocationServiceInterface>();
    _userVm.addListener(_onUserChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _syncSelfTracking();
      setState(() => _ready = true);
    });
  }

  void _onUserChanged() {
    unawaited(_syncSelfTracking());
  }

  Future<void> _syncSelfTracking() async {
    final me = _userVm.me;
    final shouldShare = me?.isChild == true && me?.allowTracking == true;

    if (shouldShare && !_selfTrackingActive) {
      final hasForegroundPermission = await _locationService
          .hasLocationPermission(requireBackground: false);
      final serviceEnabled = await _locationService.isServiceEnabled();
      if (!hasForegroundPermission || !serviceEnabled) {
        return;
      }

      await _childLocationVm.startLocationSharing(background: true);
      _selfTrackingActive = _childLocationVm.isSharing;
      return;
    }

    if (!shouldShare && _selfTrackingActive) {
      await _childLocationVm.stopSharing(clearData: false);
      _selfTrackingActive = false;
    }
  }

  @override
  void dispose() {
    _userVm.removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const AppLoadingScreen();
    return const AppShell(mode: AppMode.child);
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
