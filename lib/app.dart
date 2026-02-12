import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_shell.dart';
import 'package:provider/provider.dart';

import 'core/alert_service.dart';
import 'core/constants.dart';
import 'core/theme.dart';

import 'services/firebase_auth_service.dart';
import 'repositories/auth_repository.dart';
import 'viewmodels/auth_vm.dart';

import 'repositories/schedule_repository.dart';
import 'viewmodels/schedule_vm.dart';


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
        // Services
        Provider.value(value: authService),

        // Repositories
        Provider.value(value: userRepo),
        Provider.value(value: authRepo),
        Provider(
        create: (_) => ScheduleRepository(FirebaseFirestore.instance),
      ),

        // ViewModels
        ChangeNotifierProvider(
          create: (_) => AuthVM(authRepo),
        ),

        ChangeNotifierProxyProvider<AuthVM, ScheduleViewModel>(
          create: (context) => ScheduleViewModel(
            context.read<ScheduleRepository>(),
            context.read<AuthVM>(),
          ),
          update: (context, authVM, scheduleVM) => ScheduleViewModel(
            context.read<ScheduleRepository>(),
            authVM,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        navigatorKey: AlertService.navigatorKey,
        theme: AppTheme.light(),
        themeMode: ThemeMode.system,
        home: Consumer<AuthVM>(
          builder: (context, authVM, _) {
            if (authVM.user == null) return const LoginScreen();
            return const ParentShell();
          },
        ),
      ),
    );
  }
}
