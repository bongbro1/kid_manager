import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/background/auth_runtime_manager.dart';
import 'package:kid_manager/background/background_worker.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/user/user_types.dart';
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
  await LocalNotificationService.init();

  // gọi hàm xử lý bg (mình sẽ đưa bên dưới)
  await NotificationService.handleMessageForLocalNotification(message);
}

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔥 Flutter error: ${details.exception}');
  };

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await LocalNotificationService.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  await dotenv.load(fileName: ".env");
  final accessToken = dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(accessToken);

  await LocalAlarmService.I.init();
  await initializeDateFormatting('vi_VN', null);
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );
  debugPrint('🔔 FCM permission=${settings.authorizationStatus}');

  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('🔔 FCM token=$token');

  final storageService = await StorageService.create();
  final role = storageService.getString(StorageKeys.role);

  if (role != null && roleFromString(role) == UserRole.child) {
    final parentId = storageService.getString(StorageKeys.parentId);
    if (parentId != null && parentId.isNotEmpty) {
      AuthRuntimeManager.start(parentId: parentId);
    }
  }

  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: const MyApp(),
    ),
  );
}