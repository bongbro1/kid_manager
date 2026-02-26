import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/repositories/app_management_repository.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/repositories/location/location_repository_impl.dart';

import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/services/app_installed_service.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/services/usage_sync_service.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

import 'core/alert_service.dart';
import 'core/constants.dart';
import 'core/theme.dart';

import 'features/sessionguard/session_guard.dart';
import 'services/firebase_auth_service.dart';
import 'repositories/auth_repository.dart';
import 'viewmodels/auth_vm.dart';

import 'repositories/schedule_repository.dart';
import 'viewmodels/schedule_vm.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SosViewModel _sosVm;

  @override
  void initState() {
    super.initState();
    _sosVm = SosViewModel();
  }

  @override
  void dispose() {
    _sosVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ====== Copy y nguyên đoạn build của bạn từ đây xuống ======
    final authService = FirebaseAuthService();
    final storage = context.read<StorageService>();

    final secondaryAuthService = SecondaryAuthService();
    final permissionService = PermissionService();
    final appInstalledService = AppInstalledService();
    final usageService = UsageSyncService(FirebaseFirestore.instance);

    final userRepo = UserRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
      secondaryAuthService,
    );
    final authRepo = AuthRepository(authService, userRepo);
    final scheduleRepo = ScheduleRepository(FirebaseFirestore.instance);
    final appRepo = AppManagementRepository(
      appInstalledService,
      usageService,
      FirebaseFirestore.instance,
    );

    return MultiProvider(
      providers: [
        // services
        Provider.value(value: authService),
        Provider.value(value: permissionService),
        Provider.value(value: appInstalledService),
        Provider.value(value: usageService),

        // repositories
        Provider.value(value: userRepo),
        Provider.value(value: authRepo),
        Provider.value(value: appRepo),

        // ViewModels
        ChangeNotifierProvider(
          create: (context) => AuthVM(context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => AppInitVM(
            context.read<StorageService>(),
            context.read<PermissionService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AppManagementVM(
            context.read<AppManagementRepository>(),
            context.read<UserRepository>(),
            context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ScheduleViewModel(scheduleRepo, context.read<AuthVM>()),
        ),

        Provider<LocationServiceInterface>(create: (_) => LocationServiceImpl()),
        Provider<LocationRepository>(create: (_) => LocationRepositoryImpl()),

        ChangeNotifierProvider<SessionVM>(
          create: (context) => SessionVM(context.read<AuthRepository>()),
        ),

        // ✅ đây là điểm khác: dùng .value để giữ instance
        ChangeNotifierProvider.value(value: _sosVm),

        ChangeNotifierProvider<UserVm>(
          create: (context) => UserVm(
            context.read<UserRepository>(),
            context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider<ParentLocationVm>(
          create: (context) => ParentLocationVm(context.read<LocationRepository>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        navigatorKey: AlertService.navigatorKey,
        navigatorObservers: [routeObserver],
        theme: AppTheme.light(),
        themeMode: ThemeMode.system,
        home: const SessionGuard(),
      ),
    );
  }
}