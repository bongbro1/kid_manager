import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/background/background_worker.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🔔 FCM BG messageId=${message.messageId} data=${message.data}');
}

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔥 Flutter error: ${details.exception}');
  };

  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  String ACCESS_TOKEN = dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(ACCESS_TOKEN);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ FCM Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ permission
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('🔔 FCM permission=${settings.authorizationStatus}');

  // ✅ token
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('🔔 FCM token=$token');

  await initializeDateFormatting('vi_VN', null);

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: const MyApp(),
    ),
  );
}
