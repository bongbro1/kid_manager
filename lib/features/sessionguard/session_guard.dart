import 'package:flutter/material.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/services/notifications/sos_notification_service.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/auth/flash_screen.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';
import 'package:kid_manager/features/sessions/sessionstatus.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:kid_manager/widgets/sos/sos_view.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/services/notifications/sos_sound_prompt.dart';

class SessionGuard extends StatefulWidget {
  const SessionGuard({super.key});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  SessionStatus? _lastStatus;
  String? _lastUid;
  bool? _lastIsParent;

  String? _pushInitedForUid;

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

        debugPrint('[GUARD] status=$status uid=$uid isParent=$isParent');

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
            // reset để lần login sau init lại notification + register token
            _pushInitedForUid = null;
            return const LoginScreen();

          case SessionStatus.authenticated:
            if (uid == null) return const FlashScreen();

            // comment lại để không lỗi init trên máy ảo

            // if (_pushInitedForUid != uid) {
            //   _pushInitedForUid = uid;

            //   WidgetsBinding.instance.addPostFrameCallback((_) async {
            //     if (!mounted) return;

            //     await SosNotificationService.instance.init(
            //       onTapSos: (data) {
            //         if (data['type']?.toString() != 'SOS') return;

            //         final familyId = data['familyId']?.toString();
            //         final sosId = data['sosId']?.toString();
            //         final lat = double.tryParse(data['lat']?.toString() ?? '');
            //         final lng = double.tryParse(data['lng']?.toString() ?? '');

            //         if (familyId == null ||
            //             sosId == null ||
            //             lat == null ||
            //             lng == null)
            //           return;

            //         AlertService.navigatorKey.currentState?.push(
            //           MaterialPageRoute(
            //             builder: (_) => SosView(
            //               lat: lat,
            //               lng: lng,
            //               familyId: familyId,
            //               sosId: sosId,
            //             ),
            //           ),
            //         );
            //       },
            //     );

            //     await SosSoundPrompt.showIfNeeded(context);
            //   });
            // }

            return AppShell(mode: isParent ? AppMode.parent : AppMode.child);
        }
      },
    );
  }
}
