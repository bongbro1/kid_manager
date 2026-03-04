import 'package:kid_manager/utils/usage_rule_utils.dart';

class TimeWindowUtils {
  static List<TimeWindow> sorted(List<TimeWindow> windows) {
    final list = [...windows];
    list.sort((a, b) => a.startMin.compareTo(b.startMin));
    return list;
  }

  static bool isOverlapping(
    List<TimeWindow> windows,
    TimeWindow newWindow, {
    int? ignoreIndex,
  }) {
    for (int i = 0; i < windows.length; i++) {
      if (ignoreIndex != null && i == ignoreIndex) continue;

      final w = windows[i];

      final overlap =
          newWindow.startMin < w.endMin && newWindow.endMin > w.startMin;

      if (overlap) return true;
    }
    return false;
  }

  static TimeWindow? findAvailableSlot(
    List<TimeWindow> windows, {
    int minDuration = 60,
  }) {
    final sorted = TimeWindowUtils.sorted(windows);

    const dayStart = 0;
    const dayEnd = 1440;

    if (sorted.isEmpty) {
      return const TimeWindow(startMin: 8 * 60, endMin: 9 * 60);
    }

    if (sorted.first.startMin - dayStart >= minDuration) {
      return TimeWindow(startMin: dayStart, endMin: dayStart + minDuration);
    }

    for (int i = 0; i < sorted.length - 1; i++) {
      final gap = sorted[i + 1].startMin - sorted[i].endMin;

      if (gap >= minDuration) {
        return TimeWindow(
          startMin: sorted[i].endMin,
          endMin: sorted[i].endMin + minDuration,
        );
      }
    }

    final last = sorted.last;

    if (dayEnd - last.endMin >= minDuration) {
      return TimeWindow(
        startMin: last.endMin,
        endMin: last.endMin + minDuration,
      );
    }

    return null;
  }
}
