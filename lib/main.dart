import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/background/background_tracking_entrypoint.dart'
    as tracking_background;
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/firebase_app_check_service.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';

String _maskToken(String? token) {
  if (token == null || token.isEmpty) return 'null';
  if (token.length <= 8) return '***';
  return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
}

String _normalizeConfigValue(String? value) {
  final normalized = (value ?? '').trim();
  if (normalized.length >= 2) {
    final first = normalized[0];
    final last = normalized[normalized.length - 1];
    final isWrappedInQuotes =
        (first == "'" && last == "'") || (first == '"' && last == '"');
    if (isWrappedInQuotes) {
      return normalized.substring(1, normalized.length - 1).trim();
    }
  }
  return normalized;
}

String _readMapboxPublicAccessToken() {
  const defineToken = String.fromEnvironment('MAPBOX_PUBLIC_ACCESS_TOKEN');
  final envToken = dotenv.env['MAPBOX_PUBLIC_ACCESS_TOKEN'];

  return _normalizeConfigValue(
    defineToken.trim().isNotEmpty ? defineToken : envToken,
  );
}

Future<void> _activateFirebaseAppCheck({required bool background}) async {
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
  }
}

Future<void> _runDeferredStartupTasks() async {
  try {
    await LocalNotificationService.init();
    await NotificationService.init();
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

  final mapboxAccessToken = _readMapboxPublicAccessToken();
  if (mapboxAccessToken.isEmpty) {
    throw StateError(
      'Missing MAPBOX_PUBLIC_ACCESS_TOKEN for Mapbox rendering. '
      'Provide it in .env or via --dart-define.',
    );
  }
  MapboxOptions.setAccessToken(mapboxAccessToken);

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
