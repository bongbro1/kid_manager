import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'firebase_options.dart';

String _maskToken(String? token) {
  if (token == null || token.isEmpty) return 'null';
  if (token.length <= 8) return '***';
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}

Future<void> _activateFirebaseAppCheck({
  required bool background,
}) async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint('AppCheck activation failed: $e');
    return;
  }

  try {
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    debugPrint('AppCheck auto-refresh setup failed: $e');
  }

  if (kDebugMode && !background) {
    debugPrint(
      'AppCheck debug provider enabled. '
      'Add debug secret from Android logcat to Firebase Console allowlist.',
    );
    unawaited(
      FirebaseAppCheck.instance.getToken(false).then((token) {
        debugPrint('AppCheck token=${_maskToken(token)}');
      }).catchError((error) {
        debugPrint('AppCheck token not ready yet: $error');
      }),
    );
  }
}

Future<void> _runDeferredStartupTasks() async {
  try {
    await LocalNotificationService.init();
    await NotificationService.init();
    await NotificationService.handleInitialMessage();
  } catch (e) {
    debugPrint('Notification bootstrap failed: $e');
  }

  try {
    await LocalAlarmService.I.init();
  } catch (e) {
    debugPrint('LocalAlarm init failed: $e');
  }

  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (e) {
    debugPrint('Date formatting init failed: $e');
  }

  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (kDebugMode) {
      debugPrint('FCM permission=${settings.authorizationStatus}');
    }
  } catch (e) {
    debugPrint('FCM permission request failed: $e');
  }

  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      debugPrint('FCM token=${_maskToken(token)}');
    }
  } catch (e) {
    debugPrint('FCM token fetch failed: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint(
      'BG message id=${message.messageId} keys=${message.data.keys.toList()}',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _activateFirebaseAppCheck(background: true);
  await NotificationService.handleMessageForLocalNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _activateFirebaseAppCheck(background: false);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: '.env');

  final accessToken = dotenv.env['ACCESS_TOKEN'] ?? '';
  MapboxOptions.setAccessToken(accessToken);

  final storageService = await StorageService.create();

  runApp(
    MultiProvider(
      providers: [Provider<StorageService>.value(value: storageService)],
      child: const MyApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_runDeferredStartupTasks());
  });
}
