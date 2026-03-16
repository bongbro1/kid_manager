import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/background/auth_runtime_manager.dart';
import 'package:kid_manager/services/notifications/fcm_push_receiver_service.dart';
import 'package:kid_manager/services/notifications/sos_notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/auth/flash_screen.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  SessionStatus? _lastStatus;
  String? _lastUid;
  bool? _lastIsParent;
  bool _initCalled = false;

  String? _pushInitedForUid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initCalled) {
        _initCalled = true;
        context.read<AppInitVM>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionVM>(
      builder: (context, session, _) {
        final status = session.status;
        final uid = session.user?.uid;
        final isParent = session.isParent;

        final shouldTriggerMeWatch =
            status == SessionStatus.authenticated &&
                uid != null &&
                (_lastStatus != status || _lastUid != uid);

        final shouldTriggerChildrenWatch =
            status == SessionStatus.authenticated &&
                isParent == true &&
                uid != null &&
                (_lastStatus != status ||
                    _lastUid != uid ||
                    _lastIsParent != isParent);

        _lastStatus = status;
        _lastUid = uid;
        _lastIsParent = isParent;

        if (shouldTriggerMeWatch) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;

            final userVm = context.read<UserVm>();
            final storage = context.read<StorageService>();
            final appManagementVm = context.read<AppManagementVM>();

            final profile = await userVm.loadProfile(uid: uid, caller: 'SessionGuard');

            await storage.setString(StorageKeys.uid, uid);

            final resolvedRole = roleFromString(
              profile?.role ?? session.user?.role.name ?? 'child',
            );
            final resolvedDisplayName =
                (profile?.name ?? session.user?.displayName ?? '').trim();
            final resolvedParentId = resolvedRole == UserRole.child
                ? (profile?.parentUid ?? session.user?.parentUid ?? '').trim()
                : uid;

            if (profile != null) {
              await storage.setString(StorageKeys.role, profile.role ?? '');
              await storage.setString(StorageKeys.displayName, profile.name);
            }

            await storage.setString(
              StorageKeys.parentId,
              resolvedParentId,
            );

            if (resolvedRole == UserRole.child) {
              if (resolvedParentId.isNotEmpty && resolvedDisplayName.isNotEmpty) {
                AuthRuntimeManager.start(
                  parentId: resolvedParentId,
                  displayName: resolvedDisplayName,
                );
              } else {
                debugPrint(
                  '[SessionGuard] skip native watcher config '
                  'uid=$uid parentId="$resolvedParentId" '
                  'displayName="$resolvedDisplayName"',
                );
              }
            } else {
              await AuthRuntimeManager.stop();
            }

            userVm.watchMe(uid);
            appManagementVm.watchChildren(uid);
          });
        }

        if (shouldTriggerChildrenWatch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<UserVm>().watchChildren(uid);
          });
        }

        switch (status) {
          case SessionStatus.booting:
            return const FlashScreen();

          case SessionStatus.unauthenticated:
            _pushInitedForUid = null;
            return const LoginScreen();

          case SessionStatus.authenticated:
            if (uid == null) {
              return const FlashScreen();
            }

            if (_pushInitedForUid != uid) {
              _pushInitedForUid = uid;

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                await FcmPushReceiverService.init(uid);
                if (!mounted) return;
                await SosNotificationService.instance.init(
                  onTapSos: (data) {},
                );
              });
            }

            if (isParent == true) {
              return MultiProvider(
                providers: [
                  ChangeNotifierProvider(
                    create: (context) => ParentLocationVm(
                      context.read<LocationRepository>(),
                      context.read<LocationServiceInterface>(),
                    ),
                  ),
                ],
                child: const _ParentWarmupShell(),
              );
            }

            return _ChildWarmupShell(
              locationService: context.read<LocationServiceInterface>(),
            );
        }
      },
    );
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

      try {
        await _locationVm.startMyLocation();
      } catch (e, st) {
        debugPrint('🔥 startMyLocation failed: $e');
        debugPrint('$st');
      }

      _syncChildrenWatch();
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

      final latestIds = _userVm.childrenIds.toSet();
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

class _ChildWarmupShell extends StatefulWidget {
  const _ChildWarmupShell({required this.locationService});

  final LocationServiceInterface locationService;

  @override
  State<_ChildWarmupShell> createState() => _ChildWarmupShellState();
}

class _ChildWarmupShellState extends State<_ChildWarmupShell> {
  bool _ready = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Pre-check foreground location flow before opening child location tab.
        await widget.locationService.ensureServiceAndPermission(
          requireBackground: false,
        );
      } catch (e, st) {
        debugPrint('child warmup location precheck failed: $e');
        debugPrint('$st');
      }

      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const FlashScreen();
    return const AppShell(mode: AppMode.child);
  }
}
