import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/notifications/android_sos_alert_bridge.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';

class SosNotificationService {
  SosNotificationService._();

  static final instance = SosNotificationService._();

  bool _initialized = false;
  bool _canResolveSos = false;
  bool _foregroundListenerRegistered = false;
  bool _launchDetailsHandled = false;
  void Function(Map<String, dynamic> data)? _onTapSos;

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = AndroidSosAlertBridge.channelId;
  static const int _notificationId = 1001;
  static final Int64List _androidVibrationPattern = Int64List.fromList(<int>[
    0,
    1200,
    300,
    1200,
    300,
    1600,
  ]);

  bool _isSosData(Map<String, dynamic> data) {
    return (data['type']?.toString() ?? '').toLowerCase() == 'sos';
  }

  Future<AppLocalizations> _loadL10n([String? lang]) {
    final normalized = (lang ?? PlatformDispatcher.instance.locale.languageCode)
        .toLowerCase();
    return AppLocalizations.delegate.load(
      Locale(normalized.startsWith('en') ? 'en' : 'vi'),
    );
  }

  Future<AndroidNotificationChannel> _buildAndroidChannel([
    String? lang,
  ]) async {
    final l10n = await _loadL10n(lang);
    return AndroidNotificationChannel(
      _channelId,
      l10n.sosChannelName,
      description: l10n.sosChannelDescription,
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('sos'),
      enableVibration: true,
      vibrationPattern: _androidVibrationPattern,
    );
  }

  Future<void> _resolveFromAction(Map<String, dynamic> data) async {
    if (!_canResolveSos) return;

    final familyId = data['familyId']?.toString();
    final sosId = data['sosId']?.toString();
    if (familyId == null || sosId == null) return;

    final fn = FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    ).httpsCallable('resolveSos');

    await fn.call({'familyId': familyId, 'sosId': sosId});
    await clearActiveAlert();
  }

  Future<void> clearActiveAlert() async {
    await _fln.cancel(_notificationId);
    if (Platform.isAndroid) {
      await AndroidSosAlertBridge.restoreBestEffortAudioEscalation();
    }
  }

  Future<void> init({
    required void Function(Map<String, dynamic> data) onTapSos,
    required UserRole role,
  }) async {
    _canResolveSos = role.isAdultManager;
    _onTapSos = onTapSos;

    await _ensureInitialized(
      registerForegroundListener: true,
      processLaunchDetails: true,
    );
  }

  Future<void> prepareBackgroundHandling() async {
    await _ensureInitialized(
      registerForegroundListener: false,
      processLaunchDetails: false,
    );
  }

  Future<bool> showRemoteMessage(
    RemoteMessage msg, {
    required bool fromBackgroundIsolate,
  }) async {
    final data = Map<String, dynamic>.from(msg.data);
    if (!_isSosData(data)) return false;

    await _ensureInitialized(
      registerForegroundListener: !fromBackgroundIsolate,
      processLaunchDetails: !fromBackgroundIsolate,
    );
    await _showFromRemoteMessage(msg);
    return true;
  }

  Future<void> _ensureInitialized({
    required bool registerForegroundListener,
    required bool processLaunchDetails,
  }) async {
    if (!_initialized) {
      _initialized = true;
      debugPrint('SosNotificationService.init()');

      final l10n = await _loadL10n();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestSoundPermission: false,
        requestBadgePermission: false,
        notificationCategories: [
          DarwinNotificationCategory(
            'sos_category',
            actions: [
              DarwinNotificationAction.plain(
                'RESOLVE_SOS',
                l10n.incomingSosConfirmButton,
                options: {
                  DarwinNotificationActionOption.authenticationRequired,
                },
              ),
            ],
          ),
        ],
      );

      await _fln.initialize(
        InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );
    }

    if (Platform.isAndroid) {
      final androidChannel = await _buildAndroidChannel();
      await AndroidSosAlertBridge.ensureNotificationChannel(
        channelName: androidChannel.name,
        channelDescription: androidChannel.description ?? '',
      );
    } else {
      final android = _fln
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(await _buildAndroidChannel());
    }

    if (processLaunchDetails && !_launchDetailsHandled) {
      _launchDetailsHandled = true;
      final launchDetails = await _fln.getNotificationAppLaunchDetails();
      final notificationResponse = launchDetails?.notificationResponse;
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          notificationResponse != null) {
        await _handleNotificationResponse(notificationResponse);
      }
    }

    if (registerForegroundListener && !_foregroundListenerRegistered) {
      _foregroundListenerRegistered = true;
      FirebaseMessaging.onMessage.listen((msg) {
        showRemoteMessage(msg, fromBackgroundIsolate: false);
      });
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          sound: true,
          badge: true,
        );
  }

  Future<void> _handleNotificationResponse(NotificationResponse resp) async {
    final payload = resp.payload;
    if (payload == null) return;

    final decoded = jsonDecode(payload);
    if (decoded is! Map) return;
    final data = Map<String, dynamic>.from(decoded);

    if (resp.actionId == 'RESOLVE_SOS') {
      await _resolveFromAction(data);
      return;
    }

    if (!_isSosData(data)) return;
    final onTap = _onTapSos;
    if (onTap != null) {
      onTap(data);
      return;
    }

    await NotificationService.handleTap(data);
  }

  Future<void> _showFromRemoteMessage(RemoteMessage msg) async {
    debugPrint(
      '[SOS PUSH] onMessage data=${msg.data} notif=${msg.notification?.title}',
    );

    final data = Map<String, dynamic>.from(msg.data);
    final type = (msg.data['type']?.toString() ?? '').trim().toLowerCase();
    if (type != 'sos') return;

    final l10n = await _loadL10n(data['lang']?.toString());
    final androidChannel = await _buildAndroidChannel(data['lang']?.toString());
    final title =
        msg.notification?.title ??
        data['title']?.toString() ??
        l10n.sosFallbackTitle;
    final body =
        msg.notification?.body ??
        data['body']?.toString() ??
        l10n.sosFallbackBody;
    if (Platform.isAndroid) {
      // Best-effort only: temporarily raise alert-related streams so the
      // Android SOS alert is more likely to be heard.
      await AndroidSosAlertBridge.prepareBestEffortAudioEscalation();
    }
    final canUseFullScreen = Platform.isAndroid
        ? await AndroidSosAlertBridge.canUseFullScreenIntent()
        : false;

    final androidDetails = AndroidNotificationDetails(
      androidChannel.id,
      androidChannel.name,
      channelDescription: androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('sos'),
      enableVibration: true,
      vibrationPattern: _androidVibrationPattern,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
      fullScreenIntent: canUseFullScreen,
      actions: _canResolveSos
          ? [
              AndroidNotificationAction(
                'RESOLVE_SOS',
                l10n.incomingSosConfirmButton,
                showsUserInterface: true,
              ),
            ]
          : const <AndroidNotificationAction>[],
    );

    // iOS Critical Alerts are intentionally out of scope. Without Apple's
    // entitlement, muted-mode bypass is not supported.
    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      categoryIdentifier: 'sos_category',
      sound: 'sos.caf',
      presentAlert: true,
    );

    await _fln.show(
      _notificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(data),
    );
  }
}
