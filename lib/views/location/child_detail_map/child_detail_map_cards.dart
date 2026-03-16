import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/location/effective_speed_estimator.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';

class ChildDetailSelectedPointCard extends StatelessWidget {
  final LocationData point;
  final List<LocationData> history;
  final bool isToday;
  final VoidCallback onClose;

  const ChildDetailSelectedPointCard({
    super.key,
    required this.point,
    required this.history,
    required this.isToday,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (point.isNetworkGap) {
      return _NetworkGapCard(point: point, onClose: onClose);
    }

    final orderedHistory = history.length < 2
        ? history
        : ([...history]..sort((a, b) => a.timestamp.compareTo(b.timestamp)));
    final baseColor = _transportColor(point.transport);
    final icon = _transportIcon(point.transport);
    final stopDuration = _computeStopDuration(orderedHistory, point);
    final summary = _buildPointSummary(
      history: orderedHistory,
      point: point,
      stopDuration: stopDuration,
      isToday: isToday,
    );

    final isStart =
        orderedHistory.isNotEmpty &&
        point.timestamp == orderedHistory.first.timestamp;
    final isEnd =
        orderedHistory.isNotEmpty &&
        point.timestamp == orderedHistory.last.timestamp;
    final gpsLost = point.accuracy > 30;
    final gpsVeryBad = point.accuracy > 80;
    final displayColor = gpsLost ? const Color(0xFFC5221F) : baseColor;
    final statusBg = gpsLost
        ? const Color(0xFFFDE2E1)
        : displayColor.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: gpsLost
              ? Border.all(color: const Color(0xFFF28B82), width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    gpsLost ? Icons.gps_off_rounded : icon,
                    color: displayColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.$1,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: gpsLost
                              ? const Color(0xFFC5221F)
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.$2,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CloseButton(onTap: onClose),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isStart)
                  _TagChip(
                    text: 'Bắt đầu',
                    backgroundColor: const Color(0xFFDDF5E3),
                    foregroundColor: const Color(0xFF188038),
                  ),
                if (isEnd)
                  _TagChip(
                    text: 'Kết thúc',
                    backgroundColor: const Color(0xFFFDE2E1),
                    foregroundColor: const Color(0xFFC5221F),
                  ),
                _TagChip(
                  text: point.timeLabel,
                  backgroundColor: const Color(0xFFF1F3F4),
                  foregroundColor: const Color(0xFF5F6368),
                ),
                if (gpsVeryBad)
                  const _TagChip(
                    text: 'GPS rất yếu',
                    backgroundColor: Color(0xFFFCE8E6),
                    foregroundColor: Color(0xFFC5221F),
                  )
                else if (gpsLost)
                  const _TagChip(
                    text: 'Mất GPS',
                    backgroundColor: Color(0xFFFCE8E6),
                    foregroundColor: Color(0xFFC5221F),
                  )
                else
                  _TagChip(
                    text: _transportLabel(point.transport),
                    backgroundColor: displayColor.withOpacity(0.12),
                    foregroundColor: displayColor,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Ở đây được',
                    value: gpsLost
                        ? 'Không xác định ổn định'
                        : _formatDuration(stopDuration),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    label: 'Tốc độ',
                    value: gpsLost ? 'Không ổn định' : _speedLabel(orderedHistory, point),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Sai số GPS',
                    value: _accuracyLabel(point),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    label: 'GPS giả lập',
                    value: point.isMock ? 'Có dấu hiệu' : 'Không',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(
                'Xem chi tiết kỹ thuật',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              children: [
                _DetailRow(label: 'Thời gian', value: point.fullLabel),
                _DetailRow(
                  label: 'Hướng di chuyển',
                  value: '${point.heading.toStringAsFixed(0)}°',
                ),
                _DetailRow(
                  label: 'Tọa độ',
                  value:
                      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
                ),
                _DetailRow(
                  label: 'Độ chính xác',
                  value: '${point.accuracy.toStringAsFixed(0)} m',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChildDetailBottomCard extends StatelessWidget {
  final LocationData latest;
  final bool isToday;
  final int pointCount;

  const ChildDetailBottomCard({
    super.key,
    required this.latest,
    required this.isToday,
    required this.pointCount,
  });

  @override
  Widget build(BuildContext context) {
    final color = _transportColor(latest.transport);
    final icon = _transportIcon(latest.transport);
    final label = _transportLabel(latest.transport);
    final time = _formatTime(latest.dateTime);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF34A853)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isToday ? 'Trực tiếp' : 'Lịch sử',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? const Color(0xFF34A853)
                              : Colors.grey,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$pointCount điểm',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChildDetailEmptyStateCard extends StatelessWidget {
  final String dayLabel;
  final String rangeLabel;
  final VoidCallback? onClose;

  const ChildDetailEmptyStateCard({
    super.key,
    required this.dayLabel,
    required this.rangeLabel,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint(
      'Building ChildDetailEmptyStateCard with dayLabel=$dayLabel and rangeLabel=$rangeLabel onClose =$onClose',
    );
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EAED), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 20,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (onClose != null)
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 3, 51, 148),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color.fromARGB(255, 6, 45, 122),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Không có hành trình trong khoảng thời gian đã chọn.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(label: 'Ngày', value: dayLabel),
                _SummaryChip(label: 'Khung giờ', value: rangeLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkGapCard extends StatelessWidget {
  final LocationData point;
  final VoidCallback onClose;

  const _NetworkGapCard({required this.point, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final gapDuration = point.networkGapDuration ?? Duration.zero;
    final start = point.gapStartDateTime;
    final end = point.gapEndDateTime;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFFFB74D), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.portable_wifi_off_rounded,
                    color: Color(0xFFF57C00),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mất mạng',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bản đồ nối tạm 2 đầu vì dữ liệu bị ngắt trong ${_formatDuration(gapDuration)}.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CloseButton(onTap: onClose),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(
                  text: 'Mất kết nối',
                  backgroundColor: Color(0xFFFFF3E0),
                  foregroundColor: Color(0xFFF57C00),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _TagChip(
              text: _formatDuration(gapDuration),
              backgroundColor: const Color(0xFFF1F3F4),
              foregroundColor: const Color(0xFF5F6368),
            ),
            if (start != null && end != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      label: 'Mất từ',
                      value: _formatTime(start),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoTile(
                      label: 'Có lại lúc',
                      value: _formatTime(end),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close_rounded, size: 18),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;

  const _TagChip({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EAED), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Duration _computeStopDuration(List<LocationData> history, LocationData point) {
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

    final effectiveSpeedKmh = EffectiveSpeedEstimator.resolveHistorySpeedKmh(
      history,
      index,
    );
    if (effectiveSpeedKmh > movingSpeedThresholdKmh) {
      return false;
    }

    final transportSuggestsMovement =
        value.transport == TransportMode.walking ||
        value.transport == TransportMode.bicycle ||
        value.transport == TransportMode.vehicle;

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

(String title, String subtitle) _buildPointSummary({
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
  final isStoppedLongEnough = stopDuration.inMinutes >= 3;

  if (gpsVeryBad) {
    return (
      'Mất GPS định vị',
      'Tín hiệu GPS rất yếu, vị trí có thể không chính xác',
    );
  }

  if (gpsLost) {
    return (
      'Mất GPS định vị',
      'Sai số lớn hơn ${point.accuracy.toStringAsFixed(0)} m',
    );
  }

  if (isStoppedLongEnough) {
    if (isEnd && isToday) {
      return ('Đang đứng yên', 'Dừng tại đây ${_formatDuration(stopDuration)}');
    }
    return (
      'Đang đứng yên tại đây',
      'Dừng khoảng ${_formatDuration(stopDuration)}',
    );
  }

  if (isStart) {
    return (_transportHeadline(point.transport), 'Điểm bắt đầu hành trình');
  }

  if (isEnd) {
    return (
      _transportHeadline(point.transport),
      isToday ? 'Cập nhật lúc ${point.timeLabel}' : 'Điểm kết thúc hành trình',
    );
  }

  return (
    _transportHeadline(point.transport),
    "Đi qua điểm này lúc ${point.timeLabel}",
  );
}

String _transportHeadline(TransportMode transport) {
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

String _speedLabel(List<LocationData> history, LocationData point) {
  final index = history.indexWhere((entry) => entry.timestamp == point.timestamp);
  final kmh = index == -1
      ? point.speedKmh
      : EffectiveSpeedEstimator.resolveHistorySpeedKmh(history, index);
  if (kmh <= 1) return 'Gần như không di chuyển';
  return '${kmh.toStringAsFixed(1)} km/h';
}

String _accuracyLabel(LocationData point) {
  final acc = point.accuracy.toStringAsFixed(0);

  if (point.accuracy > 80) return 'Mất GPS nghiêm trọng';
  if (point.accuracy > 30) return 'Mất GPS định vị';
  if (point.accuracy <= 15) return 'Khá chính xác ($acc m)';
  return 'Chính xác vừa ($acc m)';
}

Color _transportColor(TransportMode transport) {
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

String _transportLabel(TransportMode transport) {
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

IconData _transportIcon(TransportMode transport) {
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

String _formatDuration(Duration duration) {
  if (duration.inSeconds <= 0) return '0 phút';

  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    return '$hours giờ $minutes phút';
  }
  if (minutes > 0) {
    return '$minutes phút';
  }
  return '$seconds giây';
}

String _formatTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';



