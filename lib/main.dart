import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kid_manager/background/background_tracking_entrypoint.dart'
    as tracking_background;
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/firebase_app_check_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint(
      'BG message id=${message.messageId} '
      'keys=${message.data.keys.toList()} '
      'hasNotification=${message.notification != null}',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await activateFirebaseAppCheck(background: true);

  if (message.notification != null) {
    if (kDebugMode) {
      debugPrint(
        'BG skip local notification because remote notification exists '
        'id=${message.messageId}',
      );
    }
    return;
  }

  await NotificationService.handleMessageForLocalNotification(message);
}

@pragma('vm:entry-point')
Future<void> backgroundTrackingMain() async {
  await tracking_background.backgroundTrackingMain();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await activateFirebaseAppCheck(background: false);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: '.env');

  final accessToken = dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(accessToken);

  final storageService = await StorageService.create();
  final isDark = storageService.getBool(StorageKeys.isDarkMode) ?? false;

  final colorValue =
      storageService.getInt(StorageKeys.themeColor) ?? 0xFF2E90FA;

  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: MyApp(isDark: isDark, primaryColor: Color(colorValue)),
    ),
  );
}
