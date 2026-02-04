import 'package:flutter/material.dart';
import 'package:kid_manager/features/presentation/shared/map_mode.dart';
import 'package:kid_manager/features/sessionguard/splash_screen.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:provider/provider.dart';


class SessionGuard extends StatelessWidget {
  const SessionGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionVM>(
      builder: (context, session, _) {
        switch (session.status) {
          case SessionStatus.booting:
            return const SplashScreen();

          case SessionStatus.unauthenticated:
            return const LoginScreen();

          case SessionStatus.authenticated:
            return AppShell(
              mode: session.isParent
                  ? MapMode.parent
                  : MapMode.child,
            );
        }
      },
    );
  }
}

