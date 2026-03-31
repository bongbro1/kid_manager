import 'dart:math' as math;

class PollingBackoff {
  PollingBackoff({
    required this.initialDelay,
    required this.maxDelay,
    this.multiplier = 2,
  }) : assert(!initialDelay.isNegative),
       assert(!maxDelay.isNegative),
       assert(multiplier >= 1);

  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;

  int _attemptCount = 0;

  int get attemptCount => _attemptCount;

  Duration nextDelay() {
    final initialMs = initialDelay.inMilliseconds;
    final maxMs = maxDelay.inMilliseconds;
    if (initialMs <= 0) {
      return Duration.zero;
    }

    final scaled = (initialMs * math.pow(multiplier, _attemptCount)).round();
    _attemptCount++;
    final capped = math.min(scaled, maxMs > 0 ? maxMs : scaled);
    return Duration(milliseconds: capped);
  }

  void reset() {
    _attemptCount = 0;
  }
}
