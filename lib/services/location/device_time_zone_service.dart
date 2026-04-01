import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/services/location/location_history_partition.dart';

class LocalTimeZoneParts {
  const LocalTimeZoneParts({
    required this.dayKey,
    required this.minuteOfDay,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
  });

  final String dayKey;
  final int minuteOfDay;
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
}

class LocalDayUtcRange {
  const LocalDayUtcRange({
    required this.fromTs,
    required this.toTs,
  });

  final int fromTs;
  final int toTs;
}

class DeviceTimeZoneService {
  DeviceTimeZoneService._();

  static final DeviceTimeZoneService instance = DeviceTimeZoneService._();

  static const MethodChannel _channel = MethodChannel('device_timezone');

  Future<String> getDeviceTimeZone({
    String fallback = LocationHistoryPartition.legacyTimeZone,
  }) async {
    try {
      final zone = await _channel.invokeMethod<String>('getDeviceTimeZone');
      return normalizeTimeZone(zone, fallback: fallback);
    } catch (e) {
      debugPrint('DeviceTimeZoneService.getDeviceTimeZone error: $e');
      return fallback;
    }
  }

  Future<String> normalizeTimeZone(
    String? timeZone, {
    String fallback = LocationHistoryPartition.legacyTimeZone,
  }) async {
    final candidate = timeZone?.trim();
    if (candidate == null || candidate.isEmpty) {
      return fallback;
    }

    try {
      final normalized = await _channel.invokeMethod<String>(
        'normalizeTimeZone',
        <String, dynamic>{
          'timeZone': candidate,
          'fallbackTimeZone': fallback,
        },
      );
      final value = normalized?.trim();
      return (value == null || value.isEmpty) ? fallback : value;
    } catch (e) {
      debugPrint('DeviceTimeZoneService.normalizeTimeZone error: $e');
      return fallback;
    }
  }

  Future<String> resolveDayKeyForTimestamp({
    required int timestampMs,
    required String timeZone,
  }) async {
    final normalizedTimeZone = await normalizeTimeZone(timeZone);

    try {
      final dayKey = await _channel.invokeMethod<String>(
        'resolveDayKeyForTimestamp',
        <String, dynamic>{
          'timestampMs': timestampMs,
          'timeZone': normalizedTimeZone,
        },
      );
      final value = dayKey?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (e) {
      debugPrint('DeviceTimeZoneService.resolveDayKeyForTimestamp error: $e');
    }

    final fallback = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    return '${fallback.year.toString().padLeft(4, '0')}-'
        '${fallback.month.toString().padLeft(2, '0')}-'
        '${fallback.day.toString().padLeft(2, '0')}';
  }

  Future<LocalTimeZoneParts> resolveLocalPartsForTimestamp({
    required int timestampMs,
    required String timeZone,
  }) async {
    final normalizedTimeZone = await normalizeTimeZone(timeZone);

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'resolveLocalPartsForTimestamp',
        <String, dynamic>{
          'timestampMs': timestampMs,
          'timeZone': normalizedTimeZone,
        },
      );
      final data = Map<String, dynamic>.from(raw ?? const <String, dynamic>{});
      final dayKey = data['dayKey']?.toString().trim();
      final minuteRaw = data['minuteOfDay'];
      final yearRaw = data['year'];
      final monthRaw = data['month'];
      final dayRaw = data['day'];
      final hourRaw = data['hour'];
      final minuteValueRaw = data['minute'];
      final secondRaw = data['second'];
      final minuteOfDay = minuteRaw is num
          ? minuteRaw.toInt()
          : int.tryParse('$minuteRaw');
      final year = yearRaw is num ? yearRaw.toInt() : int.tryParse('$yearRaw');
      final month = monthRaw is num
          ? monthRaw.toInt()
          : int.tryParse('$monthRaw');
      final day = dayRaw is num ? dayRaw.toInt() : int.tryParse('$dayRaw');
      final hour = hourRaw is num ? hourRaw.toInt() : int.tryParse('$hourRaw');
      final minute = minuteValueRaw is num
          ? minuteValueRaw.toInt()
          : int.tryParse('$minuteValueRaw');
      final second = secondRaw is num
          ? secondRaw.toInt()
          : int.tryParse('$secondRaw');
      if (dayKey != null &&
          dayKey.isNotEmpty &&
          minuteOfDay != null &&
          year != null &&
          month != null &&
          day != null &&
          hour != null &&
          minute != null &&
          second != null) {
        return LocalTimeZoneParts(
          dayKey: dayKey,
          minuteOfDay: minuteOfDay,
          year: year,
          month: month,
          day: day,
          hour: hour,
          minute: minute,
          second: second,
        );
      }
    } catch (e) {
      debugPrint('DeviceTimeZoneService.resolveLocalPartsForTimestamp error: $e');
    }

    final fallback = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    return LocalTimeZoneParts(
      dayKey: '${fallback.year.toString().padLeft(4, '0')}-'
          '${fallback.month.toString().padLeft(2, '0')}-'
          '${fallback.day.toString().padLeft(2, '0')}',
      minuteOfDay: (fallback.hour * 60) + fallback.minute,
      year: fallback.year,
      month: fallback.month,
      day: fallback.day,
      hour: fallback.hour,
      minute: fallback.minute,
      second: fallback.second,
    );
  }

  Future<LocalDayUtcRange> resolveUtcRangeForLocalDay({
    required String dayKey,
    required String timeZone,
    required int startMinuteOfDay,
    required int endMinuteOfDay,
  }) async {
    final normalizedTimeZone = await normalizeTimeZone(timeZone);

    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'resolveUtcRangeForLocalDay',
        <String, dynamic>{
          'dayKey': dayKey,
          'timeZone': normalizedTimeZone,
          'startMinuteOfDay': startMinuteOfDay,
          'endMinuteOfDay': endMinuteOfDay,
        },
      );
      final data = Map<String, dynamic>.from(raw ?? const <String, dynamic>{});
      final fromRaw = data['fromTs'];
      final toRaw = data['toTs'];
      final fromTs = fromRaw is num ? fromRaw.toInt() : int.tryParse('$fromRaw');
      final toTs = toRaw is num ? toRaw.toInt() : int.tryParse('$toRaw');
      if (fromTs != null && toTs != null) {
        return LocalDayUtcRange(fromTs: fromTs, toTs: toTs);
      }
    } catch (e) {
      debugPrint('DeviceTimeZoneService.resolveUtcRangeForLocalDay error: $e');
    }

    final parts = dayKey.split('-');
    final year = parts.length == 3 ? int.tryParse(parts[0]) : null;
    final month = parts.length == 3 ? int.tryParse(parts[1]) : null;
    final day = parts.length == 3 ? int.tryParse(parts[2]) : null;
    if (year == null || month == null || day == null) {
      final now = DateTime.now();
      final from = DateTime(
        now.year,
        now.month,
        now.day,
        startMinuteOfDay ~/ 60,
        startMinuteOfDay % 60,
      );
      final to = DateTime(
        now.year,
        now.month,
        now.day,
        endMinuteOfDay ~/ 60,
        endMinuteOfDay % 60,
        59,
        999,
      );
      return LocalDayUtcRange(
        fromTs: from.millisecondsSinceEpoch,
        toTs: to.millisecondsSinceEpoch,
      );
    }

    final from = DateTime(
      year,
      month,
      day,
      startMinuteOfDay ~/ 60,
      startMinuteOfDay % 60,
    );
    final to = DateTime(
      year,
      month,
      day,
      endMinuteOfDay ~/ 60,
      endMinuteOfDay % 60,
      59,
      999,
    );
    return LocalDayUtcRange(
      fromTs: from.millisecondsSinceEpoch,
      toTs: to.millisecondsSinceEpoch,
    );
  }
}
