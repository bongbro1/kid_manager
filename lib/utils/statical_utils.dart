import 'package:flutter/material.dart';

enum ChartMode { day, week, month }

class ChartPoint {
  final String label;
  final int minutes;

  ChartPoint({required this.label, required this.minutes});
}

class UsageHistoryResult {
  final Map<DateTime, int> totalUsage;
  final Map<String, Map<DateTime, int>> perAppUsage;

  UsageHistoryResult({required this.totalUsage, required this.perAppUsage});
}

class ChartBarUi {
  final String label;
  final double uiHeight;
  final double valueHeight;
  final bool isToday;
  final bool isFuture;
  final int minutes;

  ChartBarUi({
    required this.label,
    required this.uiHeight,
    required this.valueHeight,
    required this.isToday,
    required this.isFuture,
    required this.minutes,
  });
}

class ChartUiBuilder {
  static List<ChartBarUi> build(List<ChartPoint> points, ChartMode mode) {
    final max = points.map((e) => e.minutes).fold(0, (a, b) => a > b ? a : b);
    final now = DateTime.now();

    return List.generate(points.length, (i) {
      final p = points[i];

      final normalized = max == 0 ? 0.0 : p.minutes / max.toDouble();

      final uiHeight = 160.0;
      final valueHeight = normalized * uiHeight + 2;

      final isToday = _isToday(i, mode, now);
      final isFuture = _isFuture(i, mode, now);

      return ChartBarUi(
        label: p.label,
        uiHeight: uiHeight,
        valueHeight: valueHeight,
        isToday: isToday,
        isFuture: isFuture,
        minutes: p.minutes,
      );
    });
  }

  static bool _isToday(int index, ChartMode mode, DateTime now) {
    switch (mode) {
      case ChartMode.day:
        return index == now.hour;

      case ChartMode.week:
        return index == now.weekday - 1;

      case ChartMode.month:
        return index == now.day - 1;
    }
  }

  static bool _isFuture(int index, ChartMode mode, DateTime now) {
    switch (mode) {
      case ChartMode.day:
        return index > now.hour;

      case ChartMode.week:
        return index > now.weekday - 1;

      case ChartMode.month:
        return index > now.day - 1;
    }
  }
}

class ChartDataHelper {
  static List<ChartPoint> generate({
    required ChartMode mode,
    required Map<DateTime, int> usageMap,
  }) {
    final now = DateTime.now();

    switch (mode) {
      case ChartMode.day:
        return _buildDay(now, usageMap);

      case ChartMode.week:
        return _buildWeek(now, usageMap);

      case ChartMode.month:
        return _buildMonth(now, usageMap);
    }
  }

  static List<ChartPoint> _buildDay(DateTime now, Map<DateTime, int> usageMap) {
    final start = DateTime(now.year, now.month, now.day);

    return List.generate(24, (hour) {
      final time = start.add(Duration(hours: hour));
      final minutes = usageMap[time] ?? 0;

      return ChartPoint(label: "${hour}h", minutes: minutes);
    });
  }

  static List<ChartPoint> _buildWeek(
    DateTime now,
    Map<DateTime, int> usageMap,
  ) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (i) {
      final day = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + i,
      );

      final minutes = usageMap[day] ?? 0;

      return ChartPoint(label: _weekdayLabel(day.weekday), minutes: minutes);
    });
  }

  static List<ChartPoint> _buildMonth(
    DateTime now,
    Map<DateTime, int> usageMap,
  ) {
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    return List.generate(daysInMonth, (i) {
      final day = DateTime(now.year, now.month, i + 1);
      final minutes = usageMap[day] ?? 0;

      return ChartPoint(label: "${i + 1}", minutes: minutes);
    });
  }

  static String _weekdayLabel(int weekday) {
    const labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    return labels[weekday - 1];
  }
}

DateTime normalizeHour(DateTime dt) =>
    DateTime(dt.year, dt.month, dt.day, dt.hour);

DateTime normalizeDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
