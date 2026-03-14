import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_navigator.dart';
import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/repositories/app_management_repository.dart';
import 'package:kid_manager/repositories/birthday_repository.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/repositories/location/location_repository_impl.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/repositories/otp_repository.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kid_manager/repositories/subscription_repository.dart';
import 'package:kid_manager/repositories/terms_repository.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/app_state_local_service.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/services/app_installed_service.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/schedule/schedule_notification_service.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/services/usage_sync_service.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:kid_manager/viewmodels/locale_vm.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/viewmodels/otp_vm.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_history_vm.dart';
import 'package:kid_manager/viewmodels/session/session_vm.dart';
import 'package:kid_manager/viewmodels/subscription_vm.dart';
import 'package:kid_manager/viewmodels/terms_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';

import 'features/sessionguard/session_guard.dart';
import 'l10n/app_localizations.dart';
import 'services/firebase_auth_service.dart';
import 'repositories/auth_repository.dart';
import 'viewmodels/auth_vm.dart';

import 'repositories/schedule_repository.dart';
import 'viewmodels/schedule/schedule_vm.dart';

import 'package:kid_manager/repositories/memory_day_repository.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';

import 'package:kid_manager/services/schedule/schedule_import_service.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_import_vm.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';

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
    final authService = FirebaseAuthService();
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
    final otpRepo = OtpRepository(FirebaseFirestore.instance);
    final termsRepo = TermsRepository(FirebaseFirestore.instance);
    final subscriptionRepo = SubscriptionRepository(FirebaseFirestore.instance);
    final scheduleRepo = ScheduleRepository(FirebaseFirestore.instance);
    final appRepo = AppManagementRepository(
      appInstalledService,
      usageService,
      FirebaseFirestore.instance,
      context.read<StorageService>(),
    );

    final memoryRepo = MemoryDayRepository(FirebaseFirestore.instance);
    final birthdayRepo = BirthdayRepository(FirebaseFirestore.instance);

    return MultiProvider(
      providers: [
        Provider.value(value: authService),
        Provider.value(value: permissionService),
        Provider.value(value: appInstalledService),
        Provider.value(value: usageService),

        Provider.value(value: userRepo),
        Provider.value(value: authRepo),
        Provider.value(value: appRepo),
        Provider.value(value: otpRepo),
        Provider.value(value: termsRepo),
        Provider.value(value: subscriptionRepo),
        Provider.value(value: birthdayRepo),

        ChangeNotifierProvider(
          create: (context) => AuthVM(
            authRepo,
            userRepo,
            otpRepo,
            context.read<StorageService>(),
          ),
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

        ChangeNotifierProvider(create: (context) => OtpVM(otpRepo)),
        ChangeNotifierProvider(create: (context) => TermsVM(termsRepo)),
        ChangeNotifierProvider(
          create: (context) => SubscriptionVM(subscriptionRepo),
        ),

        Provider<ScheduleRepository>.value(value: scheduleRepo),

        Provider<ScheduleNotificationService>(
          create: (context) =>
              ScheduleNotificationService(context.read<UserRepository>()),
        ),
        Provider<LocationServiceInterface>(
          create: (_) => LocationServiceImpl(),
        ),
        Provider<LocationRepository>(create: (_) => LocationRepositoryImpl()),
        Provider<AppStateLocalService>(
          create: (context) =>
              AppStateLocalService(context.read<StorageService>()),
        ),

        ChangeNotifierProvider(
          create: (context) => ScheduleViewModel(
            scheduleRepo,
            context.read<AuthVM>(),
            context.read<ScheduleNotificationService>(),
            context.read<UserRepository>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => ScheduleImportVM(
            ScheduleImportService(
              context.read<ScheduleRepository>(),
              context.read<UserRepository>(),
            ),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => MemoryDayViewModel(
            memoryRepo,
            context.read<AuthVM>(),
            context.read<ScheduleNotificationService>(),
          ),
        ),

        ChangeNotifierProvider(create: (_) => BirthdayViewModel(birthdayRepo)),

        ChangeNotifierProvider(
          create: (context) => ScheduleHistoryViewModel(
            context.read<ScheduleRepository>(),
            context.read<AuthVM>(),
          ),
        ),

        ChangeNotifierProvider<SessionVM>(
          create: (context) => SessionVM(context.read<AuthRepository>()),
        ),

        ChangeNotifierProvider.value(value: _sosVm),

        ChangeNotifierProvider<UserVm>(
          create: (context) => UserVm(
            context.read<UserRepository>(),
            context.read<StorageService>(),
          ),
        ),

        ChangeNotifierProxyProvider<UserVm, LocaleVm>(
          create: (context) => LocaleVm(context.read<StorageService>()),
          update: (context, userVm, localeVm) {
            localeVm ??= LocaleVm(context.read<StorageService>());
            localeVm.syncFromProfile(userVm.profile?.locale);
            return localeVm;
          },
        ),

        ChangeNotifierProxyProvider<UserVm, NotificationVM>(
          create: (_) => NotificationVM(NotificationRepository()),
          update: (_, userVm, vm) {
            vm ??= NotificationVM(NotificationRepository());

            Future.microtask(() {
              vm!.bindUser(
                uid: userVm.me?.uid,
                sources: const [
                  NotificationSource.global,
                  NotificationSource.userInbox,
                ],
              );
            });

            return vm;
          },
        ),

        ChangeNotifierProvider<ParentLocationVm>(
          create: (context) => ParentLocationVm(
            context.read<LocationRepository>(),
            context.read<LocationServiceInterface>(),
          ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final locale = context.watch<LocaleVm>().locale;
          return MaterialApp(
            navigatorKey: AppNavigator.navigatorKey,
            debugShowCheckedModeBanner: false,
            title: AppConstants.appName,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('vi')],
            navigatorObservers: [routeObserver],
            theme: AppTheme.light(),
            themeMode: ThemeMode.system,
            home: const SessionGuard(),
          );
        },
      ),
    );
  }
}
