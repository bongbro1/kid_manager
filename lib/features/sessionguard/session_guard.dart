import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/auth/flash_screen.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:provider/provider.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  SessionStatus? _lastStatus;

  String? _lastUid;
  bool? _lastIsParent;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppInitVM>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionVM>(
      builder: (context, session, _) {
        final status = session.status;
        final uid = session.user?.uid;
        final isParent = session.isParent;

        // Debug nhẹ (giúp bạn trace “lúc được lúc không”)
        debugPrint('[GUARD] status=$status uid=$uid isParent=$isParent');

        // ===== HANDLE SIDE EFFECT (more robust) =====
        final shouldTriggerChildrenWatch =
            status == SessionStatus.authenticated &&
            isParent == true &&
            uid != null &&
            // Trigger khi: status đổi, hoặc uid đổi, hoặc isParent đổi
            (_lastStatus != status ||
                _lastUid != uid ||
                _lastIsParent != isParent);

        if (shouldTriggerChildrenWatch) {
          _lastStatus = status;
          _lastUid = uid;
          _lastIsParent = isParent;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.read<UserVm>().watchChildren(uid);
          });
        } else {
          // vẫn update lastStatus để UI switch ổn định
          _lastStatus = status;
          _lastUid = uid;
          _lastIsParent = isParent;
        }

        // ===== UI =====
        switch (status) {
          case SessionStatus.booting:
            return const FlashScreen();

          case SessionStatus.unauthenticated:
            return const LoginScreen();

          case SessionStatus.authenticated:
            // Nếu authenticated nhưng uid null (bất thường) -> show Flash để tránh crash
            if (uid == null) return const FlashScreen();

            return AppShell(mode: isParent ? AppMode.parent : AppMode.child);
        }
      },
    );
  }
}
