import 'package:kid_manager/services/location/device_time_zone_service.dart';
import 'package:kid_manager/services/location/location_history_partition.dart';

class LocationDayKeyResolver {
  LocationDayKeyResolver({
    DeviceTimeZoneService? deviceTimeZoneService,
  }) : _deviceTimeZoneService =
           deviceTimeZoneService ?? DeviceTimeZoneService.instance;

  final DeviceTimeZoneService _deviceTimeZoneService;

  String localDayKeyFromDate(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  DateTime parseLocalDayKey(String dayKey) {
    final parts = dayKey.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid dayKey: $dayKey');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Future<String> normalizeTimeZone(String? timeZone) {
    return _deviceTimeZoneService.normalizeTimeZone(
      timeZone,
      fallback: LocationHistoryPartition.legacyTimeZone,
    );
  }

  Future<String> resolvePreferredTimeZone(String? storedTimeZone) async {
    final deviceTimeZone = await _deviceTimeZoneService.getDeviceTimeZone(
      fallback: LocationHistoryPartition.legacyTimeZone,
    );
    if (deviceTimeZone.trim().isNotEmpty) {
      return deviceTimeZone;
    }
    return normalizeTimeZone(storedTimeZone);
  }

  Future<String> dayKeyForTimestamp({
    required int timestampMs,
    required String timeZone,
  }) {
    return _deviceTimeZoneService.resolveDayKeyForTimestamp(
      timestampMs: timestampMs,
      timeZone: timeZone,
    );
  }

  Future<LocalTimeZoneParts> localPartsForTimestamp({
    required int timestampMs,
    required String timeZone,
  }) {
    return _deviceTimeZoneService.resolveLocalPartsForTimestamp(
      timestampMs: timestampMs,
      timeZone: timeZone,
    );
  }

  Future<LocalDayUtcRange> utcRangeForLocalDay({
    required DateTime day,
    required String timeZone,
    required int startMinuteOfDay,
    required int endMinuteOfDay,
  }) {
    return _deviceTimeZoneService.resolveUtcRangeForLocalDay(
      dayKey: localDayKeyFromDate(day),
      timeZone: timeZone,
      startMinuteOfDay: startMinuteOfDay,
      endMinuteOfDay: endMinuteOfDay,
    );
  }
}
