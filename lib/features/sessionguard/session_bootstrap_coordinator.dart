import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/background/auth_runtime_manager.dart';
import 'package:kid_manager/background/tracking_background_service.dart';
import 'package:kid_manager/background/tracking_runtime_store.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/features/sessionguard/session_guard_state.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/location/device_time_zone_service.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';
import 'package:kid_manager/services/notifications/sos_notification_service.dart';
import 'package:kid_manager/services/notifications/sos_tap_router.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/viewmodels/zones/zone_status_vm.dart';
import 'package:provider/provider.dart';

class SessionBootstrapCoordinator extends StatefulWidget {
  const SessionBootstrapCoordinator({
    super.key,
    required this.resolvedSession,
    required this.isLoggingOut,
    this.allowAuthenticatedSideEffects = true,
    required this.child,
  });

  final SessionGuardResolvedState resolvedSession;
  final bool isLoggingOut;
  final bool allowAuthenticatedSideEffects;
  final Widget child;

  @override
  State<SessionBootstrapCoordinator> createState() =>
      _SessionBootstrapCoordinatorState();
}

class _SessionBootstrapCoordinatorState
    extends State<SessionBootstrapCoordinator>
    with WidgetsBindingObserver {
  SessionStatus? _lastStatus;
  String? _lastUid;

  String? _pushInitedForUid;
  String? _identityResolvedUid;
  String? _bootstrappedUid;
  String? _bootstrapQueuedForUid;
  String? _bootstrapRetryScheduledForUid;
  bool _sessionBootstrapInFlight = false;
  bool _sessionCleanupInFlight = false;
  bool _sessionPreLogoutCleanupInFlight = false;
  String? _logoutPreparedForUid;
  String? _timeZoneSyncInFlightForUid;

  Timer? _bootstrapRetryTimer;
  int _bootstrapRetryAttempt = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleSnapshotChange();
    });
  }

  @override
  void didUpdateWidget(covariant SessionBootstrapCoordinator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resolvedSession != widget.resolvedSession ||
        oldWidget.isLoggingOut != widget.isLoggingOut ||
        oldWidget.allowAuthenticatedSideEffects !=
            widget.allowAuthenticatedSideEffects) {
      _handleSnapshotChange();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncAuthenticatedUserTimeZone());
    });
  }

  void _handleSnapshotChange() {
    final status = widget.resolvedSession.status;
    final uid = widget.resolvedSession.uid;
    final prevStatus = _lastStatus;
    final prevUid = _lastUid;

    final shouldClearSessionState =
        status == SessionStatus.unauthenticated &&
        (prevStatus != SessionStatus.unauthenticated || prevUid != null);

    final shouldEnsureSessionBootstrap =
        status == SessionStatus.authenticated &&
        !widget.isLoggingOut &&
        uid != null &&
        uid.isNotEmpty &&
        (_identityResolvedUid != uid ||
            !widget.resolvedSession.hasResolvedIdentity ||
            (widget.allowAuthenticatedSideEffects &&
                widget.resolvedSession.hasResolvedIdentity &&
                _bootstrappedUid != uid)) &&
        !_sessionBootstrapInFlight &&
        _bootstrapQueuedForUid != uid &&
        (_bootstrapRetryScheduledForUid != uid ||
            widget.resolvedSession.hasResolvedIdentity);

    final shouldPrepareSessionForLogout =
        status == SessionStatus.authenticated &&
        widget.isLoggingOut &&
        uid != null &&
        uid.isNotEmpty &&
        _logoutPreparedForUid != uid;

    _lastStatus = status;
    _lastUid = uid;

    if (status != SessionStatus.authenticated || widget.isLoggingOut) {
      _bootstrapRetryTimer?.cancel();
      _bootstrapRetryTimer = null;
      _bootstrapRetryScheduledForUid = null;
      _bootstrapRetryAttempt = 0;
    }

    if (shouldPrepareSessionForLogout && !_sessionPreLogoutCleanupInFlight) {
      _sessionPreLogoutCleanupInFlight = true;
      unawaited(_runPreLogoutCleanup(uid));
    }

    if (shouldClearSessionState && !_sessionCleanupInFlight) {
      _sessionCleanupInFlight = true;
      unawaited(_runSessionCleanup());
    }

    if (shouldEnsureSessionBootstrap) {
      _queueSessionBootstrap(uid: uid);
    }
  }

  void _queueSessionBootstrap({required String uid}) {
    if (_bootstrapQueuedForUid == uid || _sessionBootstrapInFlight) {
      return;
    }

    _bootstrapQueuedForUid = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _bootstrapQueuedForUid = null;

      final currentSession = context.read<SessionVM>();
      if (currentSession.status != SessionStatus.authenticated ||
          currentSession.user?.uid != uid ||
          widget.isLoggingOut) {
        return;
      }

      _sessionBootstrapInFlight = true;
      try {
        await _runSessionBootstrap(uid: uid);
      } finally {
        _sessionBootstrapInFlight = false;
        if (mounted) {
          _handleSnapshotChange();
        }
      }
    });
  }

  Future<void> _runSessionBootstrap({required String uid}) async {
    try {
      if (widget.isLoggingOut) {
        return;
      }
      final userVm = context.read<UserVm>();
      final storage = context.read<StorageService>();
      final appManagementVm = context.read<AppManagementVM>();
      final notificationVm = context.read<NotificationVM>();

      final loadedProfile = await userVm.loadProfile(
        uid: uid,
        caller: 'SessionBootstrapCoordinator',
      );

      if (!mounted) return;

      final currentSession = context.read<SessionVM>();
      if (currentSession.status != SessionStatus.authenticated ||
          currentSession.user?.uid != uid ||
          widget.isLoggingOut) {
        return;
      }

      final liveUser = userVm.me?.uid == uid ? userVm.me : null;
      final profile = userVm.profile?.id == uid ? userVm.profile : loadedProfile;
      final resolvedSession = SessionGuardResolvedState.fromSources(
        status: currentSession.status,
        sessionUser: currentSession.user,
        liveUser: liveUser,
        profile: profile,
      );

      if (!resolvedSession.hasResolvedIdentity) {
        _scheduleBootstrapRetry(uid);
        return;
      }

      _identityResolvedUid = uid;

      if (!widget.allowAuthenticatedSideEffects) {
        return;
      }

      if (_bootstrappedUid == uid) {
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
          verifiedSession.user?.uid != uid ||
          widget.isLoggingOut) {
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
        }
      } else {
        await AuthRuntimeManager.stop();
      }

      userVm.watchMe(uid);

      if (resolvedRole == UserRole.parent && managedOwnerUid.isNotEmpty) {
        unawaited(appManagementVm.watchChildren(managedOwnerUid));
      }

      _bootstrappedUid = uid;
      _bootstrapRetryScheduledForUid = null;
      _bootstrapRetryAttempt = 0;
      _logoutPreparedForUid = null;
    } catch (e, st) {
      debugPrint('[SessionBootstrapCoordinator] bootstrap failed uid=$uid error=$e');
      debugPrintStack(stackTrace: st);
      _scheduleBootstrapRetry(uid);
    }
  }

  void _scheduleBootstrapRetry(String uid) {
    if (_bootstrapRetryScheduledForUid == uid || widget.isLoggingOut) {
      return;
    }

    _bootstrapRetryAttempt += 1;
    final delaySeconds = _bootstrapRetryAttempt <= 1
        ? 1
        : _bootstrapRetryAttempt == 2
        ? 2
        : _bootstrapRetryAttempt == 3
        ? 4
        : 8;

    _bootstrapRetryScheduledForUid = uid;
    _bootstrapRetryTimer?.cancel();
    _bootstrapRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!mounted) return;
      _bootstrapRetryScheduledForUid = null;

      final session = context.read<SessionVM>();
      if (session.status != SessionStatus.authenticated ||
          session.user?.uid != uid ||
          widget.isLoggingOut) {
        return;
      }

      _queueSessionBootstrap(uid: uid);
    });
  }

  Future<void> _runPreLogoutCleanup(String uid) async {
    try {
      if (!mounted) return;
      final currentSession = context.read<SessionVM>();
      if (widget.isLoggingOut &&
          currentSession.status == SessionStatus.authenticated &&
          currentSession.user?.uid == uid) {
        _resetBootstrapState();
        await _prepareSessionForLogout();
        _logoutPreparedForUid = uid;
      }
    } finally {
      _sessionPreLogoutCleanupInFlight = false;
    }
  }

  Future<void> _runSessionCleanup() async {
    try {
      _resetBootstrapState();
      await _clearSessionScopedState();
      _logoutPreparedForUid = null;
    } finally {
      _sessionCleanupInFlight = false;
    }
  }

  void _resetBootstrapState() {
    _identityResolvedUid = null;
    _bootstrappedUid = null;
    _bootstrapQueuedForUid = null;
    _bootstrapRetryScheduledForUid = null;
    _bootstrapRetryAttempt = 0;
    _bootstrapRetryTimer?.cancel();
    _bootstrapRetryTimer = null;
    _sessionBootstrapInFlight = false;
  }

  T? _readOptional<T>() {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _prepareSessionForLogout() async {
    if (!mounted) return;

    final userVm = context.read<UserVm>();
    final appManagementVm = context.read<AppManagementVM>();
    final notificationVm = context.read<NotificationVM>();
    final parentLocationVm = context.read<ParentLocationVm>();
    final childLocationVm = _readOptional<ChildLocationViewModel>();
    final zoneStatusVm = _readOptional<ZoneStatusVm>();

    await userVm.suspendSessionStreams();
    await appManagementVm.suspendChildrenWatch();
    await childLocationVm?.stopSharingOnLogout();
    zoneStatusVm?.clearFocus();
    await notificationVm.clear();
    await parentLocationVm.stopWatchingAllChildren();
    await parentLocationVm.stopMyLocation();
    await TrackingBackgroundService.stop();
    await AuthRuntimeManager.stop();
    _pushInitedForUid = null;
  }

  Future<void> _clearSessionScopedState() async {
    if (!mounted) return;

    final userVm = context.read<UserVm>();
    final appManagementVm = context.read<AppManagementVM>();
    final scheduleVm = context.read<ScheduleViewModel>();
    final memoryVm = context.read<MemoryDayViewModel>();
    final birthdayVm = context.read<BirthdayViewModel>();

    await _prepareSessionForLogout();
    await userVm.clear();
    await appManagementVm.clear();
    scheduleVm.resetForNewSession();
    memoryVm.resetForNewSession();
    birthdayVm.resetForNewSession();
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

    final authUid = FirebaseAuth.instance.currentUser?.uid.trim();
    if (authUid == null || authUid.isEmpty || authUid != resolvedUid) {
      return;
    }
    if (_timeZoneSyncInFlightForUid == resolvedUid) {
      return;
    }

    _timeZoneSyncInFlightForUid = resolvedUid;
    try {
      final normalizedTimeZone = await DeviceTimeZoneService.instance
          .getDeviceTimeZone();
      if (!mounted) return;

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
      debugPrint('[SessionBootstrapCoordinator] sync timezone error: $e');
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
    _bootstrapRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
