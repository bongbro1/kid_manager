import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/user/user_types.dart';
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

            final profile = await userVm.loadProfile(uid: uid, caller: 'SessionGuard');

            await storage.setString(StorageKeys.uid, uid);

            if (profile != null) {
              await storage.setString(StorageKeys.role, profile.role ?? '');
              await storage.setString(StorageKeys.displayName, profile.name);

              final role = roleFromString(profile.role ?? 'child');
              final parentId = role == UserRole.child
                  ? (profile.parentUid ?? '')
                  : uid;

              await storage.setString(StorageKeys.parentId, parentId);
            }

            userVm.watchMe(uid);
            context.read<AppManagementVM>().watchChildren(uid);
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

            return const AppShell(mode: AppMode.child);
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

    final ids = _userVm.childrenIds;
    if (ids.isEmpty) return;

    _locationVm.syncWatching(ids);
  }

  @override
  void dispose() {
    _userVm.removeListener(_onUserChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AppShell(mode: AppMode.parent);
  }
}