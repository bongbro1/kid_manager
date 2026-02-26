import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class HistorySegment {
  final TransportMode mode;
  final List<LocationData> points;
  HistorySegment(this.mode, this.points);
}

class HistorySegmenter {
  static List<HistorySegment> splitByTransport(
      List<LocationData> history, {
        int gapMs = 2 * 60 * 1000,
        int minPoints = 2,

        // ✅ new: chống nhảy mode
        int stablePointsToSwitch = 3,
      }) {
    if (history.length < 2) return [];

    final sorted = [...history]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final segments = <HistorySegment>[];
    var currentMode = _normalize(sorted.first);
    var buf = <LocationData>[sorted.first];

    // ✅ theo dõi mode "ứng viên" để switch
    TransportMode? pendingMode;
    int pendingCount = 0;

    for (int i = 1; i < sorted.length; i++) {
      final p = sorted[i];
      final prev = sorted[i - 1];

      final mode = _normalize(p);
      final gap = p.timestamp - prev.timestamp;

      final breakByGap = gap > gapMs;

      if (breakByGap) {
        if (buf.length >= minPoints) segments.add(HistorySegment(currentMode, buf));
        buf = <LocationData>[p];
        currentMode = mode;
        pendingMode = null;
        pendingCount = 0;
        continue;
      }

      if (mode == currentMode) {
        // reset pending nếu quay lại mode cũ
        pendingMode = null;
        pendingCount = 0;
        buf.add(p);
        continue;
      }

      // mode khác current -> bắt đầu/tiếp tục pending
      if (pendingMode == mode) {
        pendingCount++;
      } else {
        pendingMode = mode;
        pendingCount = 1;
      }

      buf.add(p);

      // ✅ chỉ switch khi mode mới ổn định đủ N điểm
      if (pendingCount >= stablePointsToSwitch) {
        // cắt segment tại điểm bắt đầu pending (để khỏi trộn mode)
        final cutIndex = buf.length - pendingCount;
        final left = buf.sublist(0, cutIndex);
        final right = buf.sublist(cutIndex);

        if (left.length >= minPoints) segments.add(HistorySegment(currentMode, left));

        buf = right;
        currentMode = mode;

        pendingMode = null;
        pendingCount = 0;
      }
    }

    if (buf.length >= minPoints) segments.add(HistorySegment(currentMode, buf));
    return segments;
  }

  static TransportMode _normalize(LocationData p) {
    if (p.transport != TransportMode.unknown) return p.transport;

    // accuracy xấu -> unknown (đừng flip mode)
    if (p.accuracy > 30) return TransportMode.unknown;

    final s = p.speedKmh;

    // speed rất thấp mới coi still
    if (s < 0.5) return TransportMode.still;

    //  walking threshold thực tế hơn
    if (s < 9) return TransportMode.walking;
    if (s < 22) return TransportMode.bicycle;
    return TransportMode.vehicle;
  }}