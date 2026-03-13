import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app.dart';

String _maskToken(String? token) {
  if (token == null || token.isEmpty) return 'null';
  if (token.length <= 8) return '***';
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint(
      '🔔 BG message id=${message.messageId} keys=${message.data.keys.toList()}',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.handleMessageForLocalNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await LocalNotificationService.init();
  await NotificationService.init();

  await dotenv.load(fileName: ".env");

  final accessToken = dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(accessToken);

  await LocalAlarmService.I.init();
  await initializeDateFormatting('vi_VN', null);

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (kDebugMode) {
    debugPrint('🔔 FCM permission=${settings.authorizationStatus}');
  }

  final token = await FirebaseMessaging.instance.getToken();
  if (kDebugMode) {
    debugPrint('🔔 FCM token=${_maskToken(token)}');
  }

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
