import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/views/auth/forgot_pass_screen.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/views/auth/otp_screen.dart';
import 'package:kid_manager/views/auth/reset_pass_screen.dart';
import 'package:kid_manager/views/auth/success_screen.dart';
import 'package:kid_manager/views/parent/app_management_screen.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:provider/provider.dart';

import 'core/alert_service.dart';
import 'core/constants.dart';
import 'core/theme.dart';

import 'services/firebase_auth_service.dart';
import 'repositories/auth_repository.dart';
import 'viewmodels/auth_vm.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = FirebaseAuthService();

    // Repositories
    final userRepo = UserRepository(FirebaseFirestore.instance);
    final authRepo = AuthRepository(authService, userRepo);

    return MultiProvider(
      providers: [
        Provider.value(value: authService),
        Provider.value(value: userRepo),
        Provider.value(value: authRepo),
        ChangeNotifierProvider(create: (_) => AuthVM(authRepo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        navigatorKey: AlertService.navigatorKey,
        theme: AppTheme.light(),
        themeMode: ThemeMode.system,
        // home: const ParentShell(),
        home: Consumer<AuthVM>(
          builder: (context, authVM, _) {
            // final user = authVM.user;
            // if (user == null) return const AppManagementScreen(); // hoặc Login

            // TODO: thay bằng field role thật của bạn
            // final role = user.role == 'parent'
            //     ? UserRole.parent
            //     : UserRole.child;

            // if (role == UserRole.parent) return const ParentShell();
            // return const ChildShell();

            if (authVM.user == null) return const LoginScreen();
            return const ParentShell();
          },
        ),
      ),
    );
  }
}
