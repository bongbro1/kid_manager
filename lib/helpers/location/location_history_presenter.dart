import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/location/effective_speed_estimator.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class LocationHistoryPresenter {
  const LocationHistoryPresenter._();

  static Duration computeStopDuration(
    List<LocationData> history,
    LocationData point,
  ) {
    if (history.isEmpty) return Duration.zero;

    final selectedIndex = history.indexWhere(
      (entry) => entry.timestamp == point.timestamp,
    );
    if (selectedIndex == -1) return Duration.zero;

    const stopRadiusMeters = 30.0;
    const movingSpeedThresholdKmh = 2.5;
    const strictMovingThresholdKmh = 1.2;

    var startIndex = selectedIndex;
    var endIndex = selectedIndex;

    bool isStopPoint(int index, LocationData center) {
      final value = history[index];
      final distMeters = value.distanceTo(center) * 1000.0;
      if (distMeters > stopRadiusMeters) return false;

      final effectiveSpeedKmh = resolveEffectiveSpeedKmh(history, index);
      if (effectiveSpeedKmh > movingSpeedThresholdKmh) return false;

      final effectiveTransport = _resolveEffectiveTransportAt(history, index);
      final transportSuggestsMovement =
          effectiveTransport == TransportMode.walking ||
          effectiveTransport == TransportMode.bicycle ||
          effectiveTransport == TransportMode.vehicle;

      if (transportSuggestsMovement &&
          effectiveSpeedKmh > strictMovingThresholdKmh) {
        return false;
      }

      return true;
    }

    while (startIndex > 0 && isStopPoint(startIndex - 1, point)) {
      startIndex--;
    }
    while (endIndex < history.length - 1 && isStopPoint(endIndex + 1, point)) {
      endIndex++;
    }

    final diffMs = history[endIndex].timestamp - history[startIndex].timestamp;
    if (diffMs <= 0) return Duration.zero;

    return Duration(milliseconds: diffMs);
  }

  static ({String title, String subtitle}) buildPointSummary({
    required List<LocationData> history,
    required LocationData point,
    required Duration stopDuration,
    required bool isToday,
  }) {
    final isStart =
        history.isNotEmpty && point.timestamp == history.first.timestamp;
    final isEnd = history.isNotEmpty && point.timestamp == history.last.timestamp;
    final gpsLost = point.accuracy > 30;
    final gpsVeryBad = point.accuracy > 80;
    final selectedIndex = history.indexWhere(
      (entry) => entry.timestamp == point.timestamp,
    );
    final effectiveTransport = resolveEffectiveTransport(
      history,
      point,
      indexHint: selectedIndex,
    );
    final effectiveSpeedKmh = selectedIndex == -1
        ? point.speedKmh
        : resolveEffectiveSpeedKmh(history, selectedIndex);
    final isStoppedLongEnough =
        stopDuration.inMinutes >= 3 &&
        point.motion != 'moving' &&
        effectiveTransport == TransportMode.still &&
        effectiveSpeedKmh <= 1.8;

    if (gpsVeryBad) {
      return (
        title: 'Mất GPS định vị',
        subtitle: 'Tín hiệu GPS rất yếu, vị trí có thể không chính xác',
      );
    }
    if (gpsLost) {
      return (
        title: 'Mất GPS định vị',
        subtitle: 'Sai số lớn hơn ${point.accuracy.toStringAsFixed(0)} m',
      );
    }
    if (isStoppedLongEnough) {
      if (isEnd && isToday) {
        return (
          title: 'Đang đứng yên',
          subtitle: 'Dừng tại đây ${formatDuration(stopDuration)}',
        );
      }
      return (
        title: 'Đang đứng yên tại đây',
        subtitle: 'Dừng khoảng ${formatDuration(stopDuration)}',
      );
    }
    if (isStart) {
      return (
        title: transportHeadline(effectiveTransport),
        subtitle: 'Điểm bắt đầu hành trình',
      );
    }
    if (isEnd) {
      return (
        title: transportHeadline(effectiveTransport),
        subtitle: isToday
            ? 'Cập nhật lúc ${point.timeLabel}'
            : 'Điểm kết thúc hành trình',
      );
    }
    return (
      title: transportHeadline(effectiveTransport),
      subtitle: 'Đi qua điểm này lúc ${point.timeLabel}',
    );
  }

  static double resolveEffectiveSpeedKmh(List<LocationData> history, int index) {
    return EffectiveSpeedEstimator.resolveHistorySpeedKmh(history, index);
  }

  static TransportMode resolveEffectiveTransport(
    List<LocationData> history,
    LocationData point, {
    int? indexHint,
  }) {
    final resolvedIndex = indexHint ??
        history.indexWhere((entry) => entry.timestamp == point.timestamp);
    if (resolvedIndex == -1) {
      return point.transport;
    }
    return _resolveEffectiveTransportAt(history, resolvedIndex);
  }

  static String transportHeadline(TransportMode transport) {
    switch (transport) {
      case TransportMode.walking:
        return 'Đang đi bộ';
      case TransportMode.bicycle:
        return 'Đang đi xe đạp';
      case TransportMode.vehicle:
        return 'Đang đi xe';
      case TransportMode.still:
        return 'Đang đứng yên';
      default:
        return 'Không rõ trạng thái';
    }
  }

  static String speedLabel(List<LocationData> history, LocationData point) {
    final index = history.indexWhere(
      (entry) => entry.timestamp == point.timestamp,
    );
    final kmh = index == -1
        ? point.speedKmh
        : resolveEffectiveSpeedKmh(history, index);
    if (kmh <= 1) return 'Gần như không di chuyển';
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  static String accuracyLabel(LocationData point) {
    final acc = point.accuracy.toStringAsFixed(0);
    if (point.accuracy > 80) return 'Mất GPS nghiêm trọng';
    if (point.accuracy > 30) return 'Mất GPS định vị';
    if (point.accuracy <= 15) return 'Khá chính xác ($acc m)';
    return 'Chính xác vừa ($acc m)';
  }

  static Color transportColor(TransportMode transport) {
    switch (transport) {
      case TransportMode.walking:
        return const Color(0xFF34A853);
      case TransportMode.bicycle:
        return const Color(0xFF4285F4);
      case TransportMode.vehicle:
        return const Color(0xFFFF6D00);
      case TransportMode.still:
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF757575);
    }
  }

  static String transportLabel(TransportMode transport) {
    switch (transport) {
      case TransportMode.walking:
        return 'Đi bộ';
      case TransportMode.bicycle:
        return 'Xe đạp';
      case TransportMode.vehicle:
        return 'Đang đi xe';
      case TransportMode.still:
        return 'Đang đứng yên';
      default:
        return 'Không rõ';
    }
  }

  static IconData transportIcon(TransportMode transport) {
    switch (transport) {
      case TransportMode.walking:
        return Icons.directions_walk_rounded;
      case TransportMode.bicycle:
        return Icons.directions_bike_rounded;
      case TransportMode.vehicle:
        return Icons.directions_car_rounded;
      case TransportMode.still:
        return Icons.pause_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static String formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return '0 phút';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '$hours giờ $minutes phút';
    if (minutes > 0) return '$minutes phút';
    return '$seconds giây';
  }

  static String formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

TransportMode _resolveEffectiveTransportAt(
  List<LocationData> history,
  int index,
) {
  if (index < 0 || index >= history.length) {
    return TransportMode.unknown;
  }

  final point = history[index];
  final motion = point.motion.toLowerCase();
  if (point.transport != TransportMode.still &&
      point.transport != TransportMode.unknown) {
    return point.transport;
  }

  final effectiveSpeedKmh = LocationHistoryPresenter.resolveEffectiveSpeedKmh(
    history,
    index,
  );
  final neighborSignals = <TransportMode>[
    for (final neighbor in [
      if (index > 0) history[index - 1],
      if (index + 1 < history.length) history[index + 1],
    ])
      if (neighbor.transport == TransportMode.walking ||
          neighbor.transport == TransportMode.bicycle ||
          neighbor.transport == TransportMode.vehicle)
        neighbor.transport,
  ];

  if (motion == 'moving') {
    if (neighborSignals.contains(TransportMode.vehicle) &&
        effectiveSpeedKmh >= 10) {
      return TransportMode.vehicle;
    }
    if (neighborSignals.contains(TransportMode.bicycle) &&
        effectiveSpeedKmh >= 5) {
      return TransportMode.bicycle;
    }
    if (neighborSignals.contains(TransportMode.walking) ||
        effectiveSpeedKmh >= 0.8) {
      return TransportMode.walking;
    }
  }

  if (motion == 'idle' || motion == 'stationary') {
    if (effectiveSpeedKmh <= 1.0) {
      return TransportMode.still;
    }
  }

  if (effectiveSpeedKmh >= 16) return TransportMode.vehicle;
  if (effectiveSpeedKmh >= 7) return TransportMode.bicycle;
  if (effectiveSpeedKmh >= 1.8) return TransportMode.walking;
  if (point.transport == TransportMode.still) return TransportMode.still;
  return TransportMode.unknown;
}
