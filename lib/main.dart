import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/background/background_worker.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 BG message id=${message.messageId} data=${message.data}');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.handleMessageForLocalNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  debugPrint("MAIN START");
  await LocalNotificationService.init();
  debugPrint("MAIN AFTER INIT");
  await NotificationService.init();

  await dotenv.load(fileName: ".env");

  final accessToken = dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(accessToken);

  await LocalAlarmService.I.init();
  await initializeDateFormatting('vi_VN', null);
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('🔔 FCM permission=${settings.authorizationStatus}');

  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('🔔 FCM token=$token');

  final storageService = await StorageService.create();

  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await NotificationService.handleInitialMessage();
  });
}
