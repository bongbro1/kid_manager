import 'package:flutter/material.dart';

@immutable
class TimeWindow {
  final int startMin;
  final int endMin;

  const TimeWindow({required this.startMin, required this.endMin});

  int get duration => endMin - startMin;

  bool get isValid => startMin >= 0 && endMin <= 1440 && endMin > startMin;

  Map<String, dynamic> toMap() => {'startMin': startMin, 'endMin': endMin};

  factory TimeWindow.fromMap(Map<String, dynamic> m) {
    return TimeWindow(
      startMin: (m['startMin'] as num).toInt(),
      endMin: (m['endMin'] as num).toInt(),
    );
  }
}

@immutable
class UsageRule {
  final bool enabled;
  final List<TimeWindow> windows;
  final Set<int> weekdays; // 1=Mon ... 7=Sun
  final Map<String, DayOverride> overrides;

  const UsageRule({
    required this.enabled,
    required this.windows,
    required this.weekdays,
    required this.overrides,
  });

  factory UsageRule.defaults() => const UsageRule(
    enabled: true,
    windows: [TimeWindow(startMin: 8 * 60, endMin: 20 * 60)],
    weekdays: {1, 2, 3, 4, 5, 6, 7},
    overrides: {},
  );

  UsageRule copyWith({
    bool? enabled,
    List<TimeWindow>? windows,
    Set<int>? weekdays,
    Map<String, DayOverride>? overrides,
  }) {
    return UsageRule(
      enabled: enabled ?? this.enabled,
      windows: windows ?? this.windows,
      weekdays: weekdays ?? this.weekdays,
      overrides: overrides ?? this.overrides,
    );
  }

  // helpers cho UI

  static int toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  bool _hasOverlap(List<TimeWindow> list) {
    final sorted = [...list]..sort((a, b) => a.startMin.compareTo(b.startMin));

    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i].endMin > sorted[i + 1].startMin) {
        return true;
      }
    }
    return false;
  }

  bool isValid() {
    if (!enabled) return true;
    if (weekdays.isEmpty) return false;

    for (final w in windows) {
      if (!w.isValid) return false;
    }

    return !_hasOverlap(windows);
  }

  int dailyLimitForWeekday(int weekday) {
    if (!enabled) return 0;

    final override = overrides[weekday.toString()];

    if (override == DayOverride.blockFullDay) return 0;
    if (override == DayOverride.allowFullDay) return 1440;

    if (!weekdays.contains(weekday)) return 0;

    return windows.fold(0, (sum, w) => sum + w.duration);
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'windows': windows.map((e) => e.toMap()).toList(),
    'weekdays': weekdays.toList(),
    'overrides': overrides.map((k, v) => MapEntry(k, v.name)),
  };

  factory UsageRule.fromMap(Map<String, dynamic>? m) {
    if (m == null) return UsageRule.defaults();

    final rawOverrides = (m['overrides'] as Map?) ?? {};
    final list = (m['weekdays'] as List?)?.cast<num>() ?? const [];

    final windowsRaw = (m['windows'] as List?) ?? [];

    List<TimeWindow> windows;

    if (windowsRaw.isNotEmpty) {
      windows = windowsRaw
          .map((e) => TimeWindow.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } else {
      // backward support start/end
      windows = [
        TimeWindow(
          startMin: (m['startMin'] as num?)?.toInt() ?? 8 * 60,
          endMin: (m['endMin'] as num?)?.toInt() ?? 20 * 60,
        ),
      ];
    }

    return UsageRule(
      enabled: (m['enabled'] as bool?) ?? true,
      windows: windows,
      weekdays: list.map((e) => e.toInt()).toSet(),
      overrides: rawOverrides.map(
        (k, v) => MapEntry(
          k.toString(),
          DayOverride.values.firstWhere(
            (e) => e.name == v,
            orElse: () => DayOverride.allowFullDay,
          ),
        ),
      ),
    );
  }
}

enum DayOverrideOption { followSchedule, allowFullDay, blockFullDay }

enum DayOverride { allowFullDay, blockFullDay }

DayOverrideOption toOption(DayOverride? o) {
  if (o == null) return DayOverrideOption.followSchedule;
  if (o == DayOverride.allowFullDay) return DayOverrideOption.allowFullDay;
  return DayOverrideOption.blockFullDay;
}

DayOverride? fromOption(DayOverrideOption o) {
  switch (o) {
    case DayOverrideOption.followSchedule:
      return null;
    case DayOverrideOption.allowFullDay:
      return DayOverride.allowFullDay;
    case DayOverrideOption.blockFullDay:
      return DayOverride.blockFullDay;
  }
}

String toKey(DateTime d) {
  return "${d.year.toString().padLeft(4, '0')}-"
      "${d.month.toString().padLeft(2, '0')}-"
      "${d.day.toString().padLeft(2, '0')}";
}

String fmt(int min) =>
    '${(min ~/ 60).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

enum DotType { none, allow, block }

final Map<DotType, Color> dotColorMap = {
  DotType.allow: const Color(0xFF1BD8A4), // xanh
  DotType.block: const Color(0xFFFF5A5F), // đỏ
};
