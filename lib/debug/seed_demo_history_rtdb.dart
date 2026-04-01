import 'package:firebase_database/firebase_database.dart';
import 'package:kid_manager/services/location/location_day_key_resolver.dart';

class SeedDemoHistoryRtdb {
  static final LocationDayKeyResolver _dayKeyResolver = LocationDayKeyResolver();

  // ====== CHỈNH DEVICE ID Ở ĐÂY ======
  static const String deviceId = "uzwA0A9JEGXS3Ce4nZYxghP8q2y1";

  /// Demo points (h1..h20) bạn gửi
  /// NOTE: mình bổ sung default giống payload thật: speed/heading/isMock/motion/transport
  static final Map<String, Map<String, dynamic>> demo = {
    "h1":  {"accuracy": 5, "latitude": 21.584393, "longitude": 105.80675,  "timestamp": 1707700000000},
    "h2":  {"accuracy": 5, "latitude": 21.58392,  "longitude": 105.807162, "timestamp": 1707700005000},
    "h3":  {"accuracy": 5, "latitude": 21.583963, "longitude": 105.807371, "timestamp": 1707700010000},
    "h4":  {"accuracy": 5, "latitude": 21.583863, "longitude": 105.807351, "timestamp": 1707700015000},
    "h5":  {"accuracy": 5, "latitude": 21.583835, "longitude": 105.807344, "timestamp": 1707700020000},
    "h6":  {"accuracy": 5, "latitude": 21.58359,  "longitude": 105.807409, "timestamp": 1707700025000},
    "h7":  {"accuracy": 5, "latitude": 21.583496, "longitude": 105.807539, "timestamp": 1707700030000},
    "h8":  {"accuracy": 5, "latitude": 21.583359, "longitude": 105.807779, "timestamp": 1707700035000},
    "h9":  {"accuracy": 5, "latitude": 21.583141, "longitude": 105.808783, "timestamp": 1707700040000},
    "h10": {"accuracy": 5, "latitude": 21.583086, "longitude": 105.809315, "timestamp": 1707700045000},
    "h11": {"accuracy": 5, "latitude": 21.583094, "longitude": 105.809573, "timestamp": 1707700050000},
    "h12": {"accuracy": 5, "latitude": 21.583151, "longitude": 105.809793, "timestamp": 1707700055000},
    "h13": {"accuracy": 5, "latitude": 21.583265, "longitude": 105.809987, "timestamp": 1707700060000},
    "h14": {"accuracy": 5, "latitude": 21.583338, "longitude": 105.810154, "timestamp": 1707700065000},
    "h15": {"accuracy": 5, "latitude": 21.58333,  "longitude": 105.810387, "timestamp": 1707700070000},
    "h16": {"accuracy": 5, "latitude": 21.583279, "longitude": 105.810538, "timestamp": 1707700075000},
    "h17": {"accuracy": 5, "latitude": 21.583247, "longitude": 105.810593, "timestamp": 1707700080000},
    "h18": {"accuracy": 5, "latitude": 21.581901, "longitude": 105.809356, "timestamp": 1707700085000},
    "h19": {"accuracy": 5, "latitude": 21.578756, "longitude": 105.806352, "timestamp": 1707700090000},
    "h20": {"accuracy": 5, "latitude": 21.57786,  "longitude": 105.805528, "timestamp": 1707700095000},
  };

  /// Seed demo -> RTDB new schema:
  /// - /locations/{deviceId}/historyByDay/{day}/{ts}
  /// - /locations/{deviceId}/current = last point
  static Future<void> seedDemoToRtdb({
    FirebaseDatabase? database,
    String? overrideDeviceId,
    String motion = "moving",
    String transport = "vehicle",
    double speed = 6.0,
    double heading = 0.0,
    String timeZone = 'Asia/Ho_Chi_Minh',
  }) async {
    final db = database ?? FirebaseDatabase.instance;
    final did = overrideDeviceId ?? deviceId;

    // sort theo timestamp
    final points = demo.values.toList()
      ..sort((a, b) => (a["timestamp"] as int).compareTo(b["timestamp"] as int));

    if (points.isEmpty) return;

    final updates = <String, dynamic>{};

    for (final p in points) {
      final ts = (p["timestamp"] as int);
      final day = await _dayKeyResolver.dayKeyForTimestamp(
        timestampMs: ts,
        timeZone: timeZone,
      );

      final point = <String, dynamic>{
        "accuracy": p["accuracy"],
        "latitude": p["latitude"],
        "longitude": p["longitude"],
        "timestamp": ts,
        "deviceId": did,
        "speed": p["speed"] ?? speed,
        "heading": p["heading"] ?? heading,
        "isMock": p["isMock"] ?? false,
        "motion": p["motion"] ?? motion,
        "transport": p["transport"] ?? transport,
        "sentAt": ServerValue.timestamp,
      };

      // key = timestamp => dễ query theo ngày + sort tự nhiên
      updates["locations/$did/historyByDay/$day/$ts"] = point;
    }

    // set current = last point
    final last = points.last;
    updates["locations/$did/current"] = {
      "accuracy": last["accuracy"],
      "latitude": last["latitude"],
      "longitude": last["longitude"],
      "timestamp": last["timestamp"],
      "deviceId": did,
      "speed": last["speed"] ?? speed,
      "heading": last["heading"] ?? heading,
      "isMock": last["isMock"] ?? false,
      "motion": last["motion"] ?? motion,
      "transport": last["transport"] ?? transport,
      "sentAt": ServerValue.timestamp,
      "updatedAt": ServerValue.timestamp,
    };

    await db.ref().update(updates);
  }
}
