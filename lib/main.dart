import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/background/background_worker.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔥 Flutter error: ${details.exception}');
  };

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  String ACCESS_TOKEN =dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(ACCESS_TOKEN);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi_VN', null);

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  // 🔐 Init Storage
  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: const MyApp(),
    ),
  );
}
