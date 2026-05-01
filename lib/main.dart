import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kid_manager/background/background_tracking_entrypoint.dart'
    as tracking_background;
import 'package:kid_manager/background/tracking_background_service.dart';
import 'package:kid_manager/background/tracking_runtime_store.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/firebase_app_check_service.dart';
import 'package:kid_manager/services/firebase_init_service.dart';
import 'package:kid_manager/services/notifications/local_alarm_service.dart';
import 'package:kid_manager/services/notifications/local_notification_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/services/notifications/sos_notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'app.dart';

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

// ignore: unused_element
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
    final traceId = message.data['debugTraceId']?.toString();
    if (traceId != null && traceId.isNotEmpty) {
      debugPrint(
        '[VIOLATION_TRACE] parent_backgroundMessage traceId=$traceId '
        'notificationId=${message.data['notificationId']} type=${message.data['type']}',
      );
    }
  }

  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.init();

  final notificationType = (message.data['type']?.toString() ?? '')
      .trim()
      .toLowerCase();
  final shouldUseLocalSosEscalation =
      notificationType == 'sos' &&
      (message.notification == null ||
          message.data['androidAlertMode']?.toString() == 'local_escalation');

  if (shouldUseLocalSosEscalation) {
    await SosNotificationService.instance.prepareBackgroundHandling();
    await SosNotificationService.instance.showRemoteMessage(
      message,
      fromBackgroundIsolate: true,
    );
    return;
  }

  if (message.notification != null) {
    if (kDebugMode) {
      debugPrint(
        'BG skip local notification because remote notification exists '
        'id=${message.messageId}',
      );
    }
    return;
  }

  await NotificationService.handleMessageForLocalNotificationInBackground(
    message,
  );
}

@pragma('vm:entry-point')
Future<void> backgroundTrackingMain() async {
  await tracking_background.backgroundTrackingMain();
}

@visibleForTesting
Future<bool> shouldStopTrackingServiceOnForegroundStartup() async {
  if (!await TrackingBackgroundService.isRunning()) {
    return false;
  }

  final config = await TrackingRuntimeStore.loadConfig();
  return config == null || !config.enabled;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  try {
    if (await shouldStopTrackingServiceOnForegroundStartup()) {
      await TrackingBackgroundService.stop(clearConfig: false);
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  } catch (e) {
    debugPrint('Foreground startup failed to stop tracking service: $e');
  }

  await FirebaseInitService.ensureInitialized();
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
