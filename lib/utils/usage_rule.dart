import 'package:flutter/material.dart';

@immutable
class UsageRule {
  final bool enabled;
  final int startMin; // phút từ 00:00
  final int endMin; // phút từ 00:00
  final Set<int> weekdays; // 1=Mon ... 7=Sun
  final Map<String, DayOverride> overrides;

  const UsageRule({
    required this.enabled,
    required this.startMin,
    required this.endMin,
    required this.weekdays,
    required this.overrides,
  });

  factory UsageRule.defaults() => const UsageRule(
    enabled: true,
    startMin: 8 * 60,
    endMin: 20 * 60,
    weekdays: {1, 2, 3, 4, 5, 6, 7},
    overrides: {},
  );

  UsageRule copyWith({
    bool? enabled,
    int? startMin,
    int? endMin,
    Set<int>? weekdays,
    Map<String, DayOverride>? overrides,
  }) {
    return UsageRule(
      enabled: enabled ?? this.enabled,
      startMin: startMin ?? this.startMin,
      endMin: endMin ?? this.endMin,
      weekdays: weekdays ?? this.weekdays,
      overrides: overrides ?? this.overrides,
    );
  }

  // helpers cho UI
  TimeOfDay get startTime =>
      TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
  TimeOfDay get endTime => TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);

  static int toMin(TimeOfDay t) => t.hour * 60 + t.minute;

  String pretty() {
    String fmt(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    final days = weekdays.toList()..sort();
    return 'enabled=$enabled start=${fmt(startMin)} end=${fmt(endMin)} days=$days';
  }

  bool isValid() {
    if (!enabled) return true;
    if (weekdays.isEmpty) return false;
    if (startMin < 0 || startMin > 1439) return false;
    if (endMin < 0 || endMin > 1439) return false;
    // tuỳ bạn: bắt buộc end > start (không qua ngày)
    return endMin > startMin;
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'startMin': startMin,
    'endMin': endMin,
    'weekdays': weekdays.toList(),
    'overrides': overrides.map((k, v) => MapEntry(k, v.name)),
  };

  factory UsageRule.fromMap(Map<String, dynamic>? m) {
    if (m == null) return UsageRule.defaults();
    final rawOverrides = (m['overrides'] as Map?) ?? {};
    final list = (m['weekdays'] as List?)?.cast<num>() ?? const [];
    return UsageRule(
      enabled: (m['enabled'] as bool?) ?? true,
      startMin: (m['startMin'] as num?)?.toInt() ?? 8 * 60,
      endMin: (m['endMin'] as num?)?.toInt() ?? 20 * 60,
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
