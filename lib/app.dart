import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/repositories/location/location_repository_impl.dart';

import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';


import 'package:provider/provider.dart';

import 'core/alert_service.dart';
import 'core/constants.dart';
import 'core/theme.dart';


import 'features/sessionguard/session_guard.dart';
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
        Provider.value(value: authRepo),
        /// LOCATION SERVICE
        Provider<LocationServiceInterface>(
          create: (_) => LocationServiceImpl(),
        ),
        /// LOCATION REPOSITORY
        Provider<LocationRepository>(
          create: (_) => LocationRepositoryImpl(),
        ),
        ChangeNotifierProvider(create: (_) => AuthVM(authRepo)),
        ChangeNotifierProvider(create: (_) => SessionVM(authRepo)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        navigatorKey: AlertService.navigatorKey,
        theme: AppTheme.light(),
        themeMode: ThemeMode.system,
        home: const SessionGuard(),

      ),
    );
  }
}