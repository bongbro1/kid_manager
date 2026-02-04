import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';

import 'app.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔥 Flutter error: ${details.exception}');
  };

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // 🔐 Init Storage
  final storageService = StorageService();
  await storageService.init();

  // await Workmanager().initialize(
  //   callbackDispatcher,
  //   isInDebugMode: true,
  // );
  
  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: const MyApp(),
    ),
  );
}
