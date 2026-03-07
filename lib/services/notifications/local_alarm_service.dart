import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalAlarmService {
  LocalAlarmService._();
  static final LocalAlarmService I = LocalAlarmService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String dangerChannelId = "danger_zone_channel";
  static const String dangerChannelName = "Cảnh báo vùng nguy hiểm";
  static const String dangerChannelDesc =
      "Thông báo khi bé vào/ra vùng nguy hiểm";

  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings,
      // onDidReceiveNotificationResponse: (resp) { ... } // nếu muốn handle tap
    );

    // Android: create channel
    const androidChannel = AndroidNotificationChannel(
      dangerChannelId,
      dangerChannelName,
      description: dangerChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImpl =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(androidChannel);

    _inited = true;
    debugPrint("🔔 LocalAlarmService inited");
  }

  Future<void> showDangerEnter({
    required String zoneName,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      dangerChannelId,
      dangerChannelName,
      channelDescription: dangerChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      // ✅ nếu bạn có custom sound: thêm raw resource và set sound ở đây
      // sound: RawResourceAndroidNotificationSound('siren'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      // sound: 'siren.aiff', // nếu có custom sound iOS
    );

    await _plugin.show(
      2001, // id cố định cho "enter danger"
      "⚠️ Cảnh báo vùng nguy hiểm",
      "Bạn đã vào: $zoneName",
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> showDangerExit({
    required String zoneName,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      dangerChannelId,
      dangerChannelName,
      channelDescription: dangerChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(presentSound: true);

    await _plugin.show(
      2002, // id cố định cho "exit danger"
      "✅ Đã rời vùng nguy hiểm",
      "Bạn đã rời: $zoneName",
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }
}